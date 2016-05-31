/**
 *
 * CobaltViewController.m
 * Cobalt
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Cobaltians
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "CobaltViewController.h"

#import "Cobalt.h"
#import "CobaltPluginManager.h"

#import "iToast.h"

@interface CobaltViewController () {
    /*
    NSMutableArray *topLeftBarButtonItems;
    NSMutableArray *topRightBarButtonItems;
    NSMutableArray *bottomBarButtonItems;
    */
    
    UIColor *oldNavigationBarBarTintColor;
    UIColor *oldToolbarBarTintColor;
    UIColor *oldNavigationBarTintColor;
    NSDictionary *oldNavigationBarTitleTextAttributes;
    UIColor *oldToolbarTintColor;
    BOOL oldNavigationBarHidden;
    BOOL oldToolbarHidden;
}

/*!
 @method		+(void) executeScriptInWebView:(WebViewType)webViewType withDictionary:(NSDictionary *)dict
 @abstract		this method sends a JSON to the webView to execute a script (allows interactions from the native to the webView)
 @param         webViewType: the webview where the script is due to be executed
 @param         dict: a NSDictionary that contains the necessary informations to execute the script
 @discussion    the webView MUST have a function "nativeBridge.execute(%@);" that receives the JSON (representing dict) as parameter
 @discussion    This method should NOT be overridden in subclasses.
 */
- (void)executeScriptInWebView:(WebViewType)webViewType withDictionary:(NSDictionary *)dict;

@end

@implementation CobaltViewController

@synthesize activityIndicator,
            isInfiniteScrollEnabled,
            isPullToRefreshEnabled,
            pageName,
            webLayer,
            webView;

NSMutableDictionary * alertCallbacks;

NSMutableArray * toastsToShow;
BOOL toastIsShown;

NSString * webLayerPage;

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark LIFECYCLE

////////////////////////////////////////////////////////////////////////////////////////////////

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initCobalt];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil
                               bundle:nibBundleOrNil]) {
        [self initCobalt];
    }
    
    return self;
}

- (void)initCobalt {
    toJavaScriptOperationQueue = [[NSOperationQueue alloc] init] ;
    [toJavaScriptOperationQueue setSuspended:YES];
    
    fromJavaScriptOperationQueue = [[NSOperationQueue alloc] init] ;
    [fromJavaScriptOperationQueue setSuspended:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppStarted:)
                                                 name:kOnAppStarted object:nil];
}

- (void)initWithPage:(nonnull NSString *)page
       andController:(nullable NSString *)controller {
    self.pageName = page;
    
    NSDictionary *configuration = [Cobalt configurationForController:controller];
    if (configuration == nil) {
        configuration = [Cobalt defaultConfiguration];
    }
    
    if (configuration == nil) {
        self.isPullToRefreshEnabled = false;
        self.isInfiniteScrollEnabled = false;
        self.infiniteScrollOffset = 0;
        self.barsConfiguration = nil;
    }
    else {
        BOOL pullToRefreshEnabled = [[configuration objectForKey:kConfigurationControllerPullToRefresh] boolValue];
        BOOL infiniteScrollEnabled = [[configuration objectForKey:kConfigurationControllerInfiniteScroll] boolValue];
        int infiniteScrollOffset = [configuration objectForKey:kConfigurationControllerInfiniteScrollOffset] != nil ? [[configuration objectForKey:kConfigurationControllerInfiniteScrollOffset] intValue] : 0;
        NSDictionary *barsDictionary = [configuration objectForKey:kConfigurationBars];

        self.isPullToRefreshEnabled = pullToRefreshEnabled;
        self.isInfiniteScrollEnabled = infiniteScrollEnabled;
        self.infiniteScrollOffset = infiniteScrollOffset;
        self.barsConfiguration = [barsDictionary mutableCopy];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    [self customWebView];
    [webView setDelegate:self];
    
    alertCallbacks = [[NSMutableDictionary alloc] init];
    toastsToShow = [[NSMutableArray alloc] init];
    
    [activityIndicator startAnimating];
    
    if ([webView respondsToSelector:@selector(setKeyboardDisplayRequiresUserAction:)]) {
        [webView setKeyboardDisplayRequiresUserAction:NO];
    }
    
    if (! pageName
        || pageName.length == 0) {
        pageName = defaultHtmlPage;
    }
    
    // Add pull-to-refresh table header view
    if (isPullToRefreshEnabled) {
        NSBundle *cobaltBundle = [Cobalt bundleResources];
        
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self customizeRefreshControlWithAttributedRefreshText:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"pullToRefresh",
                                                                                                                                             @"Localizable",
                                                                                                                                             cobaltBundle,
                                                                                                                                             @"Pull-to-refresh")]
                                      andAttributedRefreshText:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"refreshing",
                                                                                                                                             @"Localizable",
                                                                                                                                             cobaltBundle,
                                                                                                                                             @"Refreshing")]
                                                  andTintColor:[UIColor grayColor]];
        
        [self.refreshControl addTarget:self
                                action:@selector(refresh)
                      forControlEvents:UIControlEventValueChanged];
        [webView.scrollView addSubview:self.refreshControl];
        [webView.scrollView sendSubviewToBack:self.refreshControl];
    }
    
    [webView.scrollView setDelegate:self];
    
    [self loadPage:pageName inWebView:webView];
    
    if([JSContext class]) {
        JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
        //[context setExceptionHandler:^(JSContext *context, JSValue *value) {
        //    NSLog(@"%@", value);
        //}];
    
        // register CobaltViewController class
        context[@"CobaltViewController"] = self;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self saveBars];
    [self configureBars];
    [self setBarButtonItems];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppBackground:)
                                                 name:kOnAppBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppForeground:)
                                                 name:kOnAppForegroundNotification object:nil];
    
    [self sendEvent:JSEventOnPageShown
           withData:_navigationData
        andCallback:nil];
    
    _navigationData = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [fromJavaScriptOperationQueue setSuspended:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [fromJavaScriptOperationQueue setSuspended:YES];
    
    [self resetBars];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOnAppBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOnAppForegroundNotification
                                                  object:nil];
}

- (void)dealloc
{
    toJavaScriptOperationQueue = nil;
    fromJavaScriptOperationQueue = nil;
    _delegate = nil;
    webView = nil;
    activityIndicator = nil;
    pageName = nil;
    webLayer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOnAppStarted
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:viewControllerDeallocatedNotification
                                                        object:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark NOTIFICATIONS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)onAppStarted:(NSNotification *)notification {
    [self sendEvent:JSEventOnAppStarted
           withData:nil
        andCallback:nil];
}

- (void)onAppBackground:(NSNotification *)notification {
    [self sendEvent:JSEventOnAppBackground
           withData:nil
        andCallback:nil];
}

- (void)onAppForeground:(NSNotification *)notification {
    [self sendEvent:JSEventOnAppForeground
           withData:nil
        andCallback:nil];
    [self sendEvent:JSEventOnPageShown
           withData:nil
        andCallback:nil];
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark BARS

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)saveBars {
    oldNavigationBarBarTintColor = self.navigationController.navigationBar.barTintColor;
    oldToolbarBarTintColor = self.navigationController.toolbar.barTintColor;
    oldNavigationBarTintColor = self.navigationController.navigationBar.tintColor;
    oldNavigationBarTitleTextAttributes = self.navigationController.navigationBar.titleTextAttributes;
    oldToolbarTintColor = self.navigationController.toolbar.tintColor;
    oldNavigationBarHidden = self.navigationController.navigationBarHidden;
    oldToolbarHidden = self.navigationController.toolbarHidden;
}

- (void)configureBars {
    if (_barsConfiguration != nil) {
        id title = [_barsConfiguration objectForKey:kConfigurationBarsTitle];
        id backgroundColor = [_barsConfiguration objectForKey:kConfigurationBarsBackgroundColor];
        id color = [_barsConfiguration objectForKey:kConfigurationBarsColor];
        id visible = [_barsConfiguration objectForKey:kConfigurationBarsVisible];
        id actions = [_barsConfiguration objectForKey:kConfigurationBarsActions];
        
        if (title != nil
            && [title isKindOfClass:[NSString class]]) {
            self.navigationItem.title = title;
        }
        
        if (backgroundColor != nil
            && [backgroundColor isKindOfClass:[NSString class]]) {
            UIColor *barTintColor = [Cobalt colorFromHexString:backgroundColor];
            if (barTintColor != nil) {
                self.navigationController.navigationBar.barTintColor = barTintColor;
                self.navigationController.toolbar.barTintColor = barTintColor;
            }
        }
        
        if (color != nil
            && [color isKindOfClass:[NSString class]]) {
            UIColor *tintColor = [Cobalt colorFromHexString:color];
            if (tintColor != nil) {
                self.navigationController.navigationBar.tintColor = tintColor;
                self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: tintColor};
                self.navigationController.toolbar.tintColor = tintColor;
            }
        }
        
        if (visible != nil
            && [visible isKindOfClass:[NSDictionary class]]) {
            id top = [visible objectForKey:kConfigurationBarsVisibleTop];
            id bottom = [visible objectForKey:kConfigurationBarsVisibleBottom];
            
            
            if (top != nil
                && [top isKindOfClass:[NSNumber class]]) {
                [self.navigationController setNavigationBarHidden:! [top boolValue]
                                                         animated:YES];
            }
            else {
                [self.navigationController setNavigationBarHidden:YES
                                                         animated:YES];
            }
            
            if (bottom != nil
                && [bottom isKindOfClass:[NSNumber class]]) {
                [self.navigationController setToolbarHidden:! [bottom boolValue]
                                                   animated:YES];
            }
            else {
                [self.navigationController setToolbarHidden:YES
                                                   animated:YES];
            }
        }
        
        if (actions != nil
            && [actions isKindOfClass:[NSArray class]]) {
            topLeftBarButtonItems = [NSMutableArray array];
            topRightBarButtonItems = [NSMutableArray array];
            bottomBarButtonItems = [NSMutableArray array];
            
            UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                           target:nil
                                                                                           action:nil];
            flexibleSpace.tag = FLEXIBLE_SPACE_TAG;
            
            
            for (id action in actions) {
                if (action != nil
                    && [action isKindOfClass:[NSDictionary class]]) {
                    id iosPosition = [action objectForKey:kConfigurationBarsActionPosition];  //NSString  (mandatory: topLeft|topRight|bottom)
                    
                    if (iosPosition != nil
                        && [iosPosition isKindOfClass:[NSString class]]) {
                        id groupActions = [action objectForKey:kConfigurationBarsActions];
                        
                        if (groupActions != nil
                            && [groupActions isKindOfClass:[NSArray class]]) {
                            NSArray *barButtonItems = [self barButtonItemsForGroup:action];
                            
                            if ([iosPosition isEqualToString:kConfigurationBarsActionPositionTopRight]) {
                                [topRightBarButtonItems addObjectsFromArray:barButtonItems];
                            }
                            else if ([iosPosition isEqualToString:kConfigurationBarsActionPositionTopLeft]) {
                                [topLeftBarButtonItems addObjectsFromArray:barButtonItems];
                            }
                            else if ([iosPosition isEqualToString:kConfigurationBarsActionPositionBottom]) {
                                if (barButtonItems.count > 0) {
                                    [bottomBarButtonItems addObject:flexibleSpace];
                                    [bottomBarButtonItems addObjectsFromArray:barButtonItems];
                                }
                            }
                        }
                        else {
                            CobaltBarButtonItem *barButtonItem = [self barButtonItemForAction:action];
                            if (barButtonItem != nil) {
                                if ([iosPosition isEqualToString:kConfigurationBarsActionPositionTopRight]) {
                                    [topRightBarButtonItems addObject:barButtonItem];
                                }
                                else if ([iosPosition isEqualToString:kConfigurationBarsActionPositionTopLeft]) {
                                    [topLeftBarButtonItems addObject:barButtonItem];
                                }
                                else if ([iosPosition isEqualToString:kConfigurationBarsActionPositionBottom]) {
                                    [bottomBarButtonItems addObject:flexibleSpace];
                                    [bottomBarButtonItems addObject:barButtonItem];
                                }
                            }
                        }
                    }
                }
            }
            
            NSMutableArray *barButtonItems = [NSMutableArray arrayWithCapacity:topRightBarButtonItems.count];
            [topRightBarButtonItems enumerateObjectsWithOptions:NSEnumerationReverse
                                                     usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                         [barButtonItems addObject:obj];
                                                     }];
            topRightBarButtonItems = barButtonItems;
            
            if (bottomBarButtonItems.count > 0) {
                [bottomBarButtonItems addObject:flexibleSpace];
            }
        }
    }
}

- (void)setBarsVisible:(NSDictionary *)visible {
    id top = [visible objectForKey:kConfigurationBarsVisibleTop];
    id bottom = [visible objectForKey:kConfigurationBarsVisibleBottom];
    
    NSMutableDictionary *barsConfiguration = _barsConfiguration;
    if (barsConfiguration == nil) {
        barsConfiguration = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *barsVisible = [barsConfiguration objectForKey:kConfigurationBarsVisible];
    if (barsVisible == nil
        || ! [barsVisible isKindOfClass:[NSDictionary class]]) {
        barsVisible = [NSMutableDictionary dictionary];
    }
    
    if (top != nil
        && [top isKindOfClass:[NSNumber class]]) {
        [self.navigationController setNavigationBarHidden:! [top boolValue]
                                                 animated:YES];
        [barsVisible setObject:top
                        forKey:kConfigurationBarsVisibleTop];
    }
    if (bottom != nil
        && [bottom isKindOfClass:[NSNumber class]]) {
        [self.navigationController setToolbarHidden:! [bottom boolValue]
                                           animated:YES];
        [barsVisible setObject:bottom
                        forKey:kConfigurationBarsVisibleBottom];
    }
    
    if (barsVisible.count > 0) {
        [barsConfiguration setObject:barsVisible
                              forKey:kConfigurationBarsVisible];
    }
}

- (void)setBarContent:(NSDictionary *)content {
    id title = [content objectForKey:kConfigurationBarsTitle];
    id backgroundColor = [content objectForKey:kConfigurationBarsBackgroundColor];
    id color = [content objectForKey:kConfigurationBarsColor];
    
    NSMutableDictionary *barsConfiguration = _barsConfiguration;
    if (barsConfiguration == nil) {
        barsConfiguration = [NSMutableDictionary dictionary];
    }
    
    if (title != nil
        && [title isKindOfClass:[NSString class]]) {
        self.navigationItem.title = title;
        [barsConfiguration setObject:title
                              forKey:kConfigurationBarsTitle];
    }
    
    if (backgroundColor != nil
        && [backgroundColor isKindOfClass:[NSString class]]) {
        UIColor *barTintColor = [Cobalt colorFromHexString:backgroundColor];
        if (barTintColor != nil) {
            self.navigationController.navigationBar.barTintColor = barTintColor;
            self.navigationController.toolbar.barTintColor = barTintColor;
        }
        
        [barsConfiguration setObject:backgroundColor
                              forKey:kConfigurationBarsBackgroundColor];
    }
    
    if (color != nil
        && [color isKindOfClass:[NSString class]]) {
        UIColor *tintColor = [Cobalt colorFromHexString:color];
        if (tintColor != nil) {
            self.navigationController.navigationBar.tintColor = tintColor;
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: tintColor};
            self.navigationController.toolbar.tintColor = tintColor;
            UIBarButtonItem *leftBarButtonItem = self.navigationItem.leftBarButtonItem;
            if (leftBarButtonItem != nil
                && [leftBarButtonItem isKindOfClass:[BackBarButtonItem class]]) {
                [leftBarButtonItem setTintColor:tintColor];
            }
        }
        
        [barsConfiguration setObject:color
                              forKey:kConfigurationBarsColor];
    }
}

- (NSArray *)barButtonItemsForGroup:(NSDictionary *)group {
    NSMutableArray *barButtonItems = [NSMutableArray array];
    
    id actions = [group objectForKey:kConfigurationBarsActions];
    
    if (actions != nil
        && [actions isKindOfClass:[NSArray class]]) {
        for (id action in actions) {
            if (action != nil
                && [action isKindOfClass:[NSDictionary class]]) {
                CobaltBarButtonItem *barButtonItem = [self barButtonItemForAction:action];
                if (barButtonItem != nil) {
                    [barButtonItems addObject:barButtonItem];
                }
            }
        }
    }
    
    return barButtonItems;
}

- (CobaltBarButtonItem *)barButtonItemForAction:(NSDictionary *)action {
    return [[CobaltBarButtonItem alloc] initWithAction:action
                                              barColor:self.navigationController.navigationBar.tintColor
                                           andDelegate:self];
}

- (CobaltBarButtonItem *)barButtonItemNamed:(NSString *)name {
    for (UIBarButtonItem *barButtonItem in topLeftBarButtonItems) {
        if ([barButtonItem isKindOfClass:[CobaltBarButtonItem class]]
            && [name isEqualToString:[(CobaltBarButtonItem *) barButtonItem name]]) {
            return barButtonItem;
        }
    }
    
    for (UIBarButtonItem *barButtonItem in topRightBarButtonItems) {
        if ([barButtonItem isKindOfClass:[CobaltBarButtonItem class]]
            && [name isEqualToString:[(CobaltBarButtonItem *) barButtonItem name]]) {
            return barButtonItem;
        }
    }
    
    for (UIBarButtonItem *barButtonItem in bottomBarButtonItems) {
        if ([barButtonItem isKindOfClass:[CobaltBarButtonItem class]]
            && [name isEqualToString:[(CobaltBarButtonItem *) barButtonItem name]]) {
            return barButtonItem;
        }
    }
    
    return nil;
}

- (void)setContent:(NSDictionary *)content
forBarButtonItemNamed:(NSString *)name {
    CobaltBarButtonItem *barButtonItem = [self barButtonItemNamed:name];
    if (barButtonItem == nil) {
#if DEBUG_COBALT
        NSLog(@"setContent:forBarButtonItemNamed: unable to set content for action named %@ not found", name);
#endif
        return;
    }
    [barButtonItem setContent:content];
    
    id actions = [_barsConfiguration objectForKey:kConfigurationBarsActions];
    for (NSMutableDictionary *action in actions) {
        if ([[action objectForKey:kConfigurationBarsActionName] isEqualToString:name]) {
            id iosIcon = [content objectForKey:kConfigurationBarsActionIconIOS];
            id icon = [content objectForKey:kConfigurationBarsActionIcon];
            id title = [content objectForKey:kConfigurationBarsActionTitle];
            id color = [content objectForKey:kConfigurationBarsActionColor];
            
            if (iosIcon != nil
                && [iosIcon isKindOfClass:[NSString class]]) {
                [action setObject:iosIcon
                           forKey:kConfigurationBarsActionIconIOS];
            }
            else if (icon != nil
                && [icon isKindOfClass:[NSString class]]) {
                [action setObject:icon
                           forKey:kConfigurationBarsActionIcon];
                [action removeObjectForKey:kConfigurationBarsActionIconIOS];
            }
            else if (title != nil
                && [title isKindOfClass:[NSString class]]) {
                
                [action setObject:title
                           forKey:kConfigurationBarsActionTitle];
                [action removeObjectForKey:kConfigurationBarsActionIconIOS];
                [action removeObjectForKey:kConfigurationBarsActionIcon];
            }
            if (color != nil
                && [color isKindOfClass:[NSString class]]) {
                [action setObject:color
                           forKey:kConfigurationBarsActionColor];
            }
            
            return;
        }
    }
}

- (void)setVisible:(BOOL)visible
forBarButtonItemNamed:(NSString *)name {
    CobaltBarButtonItem *barButtonItem = [self barButtonItemNamed:name];
    if (barButtonItem == nil) {
#if DEBUG_COBALT
        NSLog(@"setVisible:forBarButtonItemNamed: unable to set visible for action named %@ not found", name);
#endif
        return;
    }
    [barButtonItem setVisible:visible];
    
    [self resetBarButtonItems];
    [self setBarButtonItems];
    
    id actions = [_barsConfiguration objectForKey:kConfigurationBarsActions];
    for (NSMutableDictionary *action in actions) {
        if ([[action objectForKey:kConfigurationBarsActionName] isEqualToString:name]) {
            [action setObject:[NSNumber numberWithBool:visible]
                       forKey:kConfigurationBarsActionVisible];
            return;
        }
    }
}

- (void)setEnabled:(BOOL)enabled
forBarButtonItemNamed:(NSString *)name {
    CobaltBarButtonItem *barButtonItem = [self barButtonItemNamed:name];
    if (barButtonItem == nil) {
#if DEBUG_COBALT
        NSLog(@"setEnabled:forBarButtonItemNamed: unable to set enabled for action named %@ not found", name);
#endif
        return;
    }
    [barButtonItem setEnabled:enabled];
    
    id actions = [_barsConfiguration objectForKey:kConfigurationBarsActions];
    for (NSMutableDictionary *action in actions) {
        if ([[action objectForKey:kConfigurationBarsActionName] isEqualToString:name]) {
            [action setObject:[NSNumber numberWithBool:enabled]
                       forKey:kConfigurationBarsActionEnabled];
            return;
        }
    }
}

- (void)setBadgeLabelText:(NSString *)text
    forBarButtonItemNamed:(NSString *)name {
    CobaltBarButtonItem *barButtonItem = [self barButtonItemNamed:name];
    if (barButtonItem == nil) {
#if DEBUG_COBALT
        NSLog(@"setBadgeLabelText:forBarButtonItemNamed: unable to set badge for action named %@ not found", name);
#endif
        return;
    }
    [barButtonItem setBadge:text];
    
    id actions = [_barsConfiguration objectForKey:kConfigurationBarsActions];
    for (NSMutableDictionary *action in actions) {
        if ([[action objectForKey:kConfigurationBarsActionName] isEqualToString:name]) {
            [action setObject:text
                       forKey:kConfigurationBarsActionBadge];
            return;
        }
    }
}

- (void)resetBars {
    self.navigationController.navigationBar.barTintColor = oldNavigationBarBarTintColor;
    self.navigationController.toolbar.barTintColor = oldToolbarBarTintColor;
    self.navigationController.navigationBar.tintColor = oldNavigationBarTintColor;
    self.navigationController.navigationBar.titleTextAttributes = oldNavigationBarTitleTextAttributes;
    self.navigationController.toolbar.tintColor = oldToolbarTintColor;
    self.navigationController.navigationBarHidden = oldNavigationBarHidden;
    self.navigationController.toolbarHidden = oldToolbarHidden;
}

- (void)setBarButtonItems {
    NSMutableArray *visibleTopLeftBarButtonItems = [[NSMutableArray alloc] initWithCapacity:topLeftBarButtonItems.count];
    NSMutableArray *visibleTopRightBarButtonItems = [[NSMutableArray alloc] initWithCapacity:topRightBarButtonItems.count];
    NSMutableArray *visibleBottomBarButtonItems = [[NSMutableArray alloc] initWithCapacity:bottomBarButtonItems.count];
    
    for (UIBarButtonItem *barButtonItem in topLeftBarButtonItems) {
        if (! [barButtonItem isKindOfClass:[CobaltBarButtonItem class]]
            || ((CobaltBarButtonItem *) barButtonItem).visible) {
            [visibleTopLeftBarButtonItems addObject:barButtonItem];
        }
    }
    for (UIBarButtonItem *barButtonItem in topRightBarButtonItems) {
        if (! [barButtonItem isKindOfClass:[CobaltBarButtonItem class]]
            || ((CobaltBarButtonItem *) barButtonItem).visible) {
            [visibleTopRightBarButtonItems addObject:barButtonItem];
        }
    }
    for (UIBarButtonItem *barButtonItem in bottomBarButtonItems) {
        if (! [barButtonItem isKindOfClass:[CobaltBarButtonItem class]]
            || ((CobaltBarButtonItem *) barButtonItem).visible) {
            [visibleBottomBarButtonItems addObject:barButtonItem];
        }
    }
    
    if (visibleTopLeftBarButtonItems.count > 0) {
        self.navigationItem.leftBarButtonItems = visibleTopLeftBarButtonItems;
    }
    else {
        // Override back button
        NSArray *navigationViewControllers = self.navigationController.viewControllers;
        if (navigationViewControllers.count > 1
            && [navigationViewControllers indexOfObject:self] != 0) {
            self.navigationItem.leftBarButtonItem = [[BackBarButtonItem alloc] initWithTintColor:self.navigationController.navigationBar.tintColor
                                                                                     andDelegate:self];
            self.navigationItem.hidesBackButton = YES;
        }
    }
    
    if (visibleTopRightBarButtonItems.count > 0) {
        self.navigationItem.rightBarButtonItems = visibleTopRightBarButtonItems;
    }
    
    if (visibleBottomBarButtonItems.count > 0) {
        self.toolbarItems = visibleBottomBarButtonItems;
    }
}

- (void)resetBarButtonItems {
    self.navigationItem.leftBarButtonItems = @[];
    self.navigationItem.rightBarButtonItems = @[];
    self.toolbarItems = @[];
}

- (void)onBarButtonItemPressed:(NSString *)name {
    [self sendMessage:@{
                        kJSType: JSTypeUI,
                        kJSControl: JSControlBars,
                        kJSData: @{
                                kJSAction: JSActionPressed,
                                kJSName: name
                                }
                        }];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setDelegate:(id)delegate
{
    if (delegate) {
        _delegate = delegate;
    }
}

- (void)customWebView
{
    
}

- (void)loadPage:(NSString *)page inWebView:(UIWebView *)mWebView
{
    NSURL * fileURL = [NSURL fileURLWithPath:[[Cobalt resourcePath] stringByAppendingPathComponent:page]];
    NSURLRequest * requestURL = [NSURLRequest requestWithURL:fileURL];
    [mWebView loadRequest:requestURL];
}

- (void)executeScriptInWebView:(WebViewType)webViewType withDictionary:(NSDictionary *)dict
{
    [toJavaScriptOperationQueue addOperationWithBlock:^{
        if ([NSJSONSerialization isValidJSONObject:dict]) {
            NSError * error;
            NSString * message =[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error] encoding:NSUTF8StringEncoding];
            
            if (message) {
                // Ensures there is no raw newLine in message.
                message = [[message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
                
                NSString * script = [NSString stringWithFormat:@"cobalt.execute(%@);", message];
                
                UIWebView * webViewToExecute;
                switch(webViewType) {
                    default:
                    case WEB_VIEW:
                        webViewToExecute = webView;
                        break;
                    case WEB_LAYER:
                        webViewToExecute = webLayer;
                        break;
                }
                [webViewToExecute performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:script waitUntilDone:NO];
            }
#if DEBUG_COBALT
            else {
                NSLog(@"executeScriptInWebView: Error while generating JSON %@\n%@", [dict description], [error localizedFailureReason]);
            }
#endif
        }
    }];
}

- (void)sendCallback:(NSString *)callback withData:(NSObject *)data
{
    if (callback
        && callback.length > 0) {
        NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:   JSTypeCallBack, kJSType,
                                                                            callback, kJSCallback,
                                                                            data, kJSData,
                                                                            nil];
        [self executeScriptInWebView:WEB_VIEW withDictionary:dict];
    }
#if DEBUG_COBALT
    else {
        NSLog(@"sendCallback: invalid callback (null or empty)");
    }
#endif
}

- (void)sendEvent:(NSString *)event withData:(NSObject *)data andCallback:(NSString *)callback
{
    if (event
        && event.length > 0) {
        NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: JSTypeEvent, kJSType,
                                                                                        event, kJSEvent,
                                                                                        nil];
        if (data) {
            [dict setObject:data forKey:kJSData];
        }
        if (callback) {
            [dict setObject:callback forKey:kJSCallback];
        }
        
        [self executeScriptInWebView:WEB_VIEW withDictionary:dict];
    }
#if DEBUG_COBALT
    else {
        NSLog(@"sendEvent: invalid event (null or empty)");
    }
#endif
}

- (void)sendCallbackToWebLayer:(NSString *)callback withData:(NSObject *)data
{
    if (callback
        && callback.length > 0) {
        NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:   JSTypeCallBack, kJSType,
                               callback, kJSCallback,
                               data, kJSData,
                               nil];
        [self executeScriptInWebView:WEB_LAYER withDictionary:dict];
    }
#if DEBUG_COBALT
    else {
        NSLog(@"sendCallbackToWebLayer: invalid callback (null or empty)");
    }
#endif
}

- (void)sendEventToWebLayer:(NSString *)event withData:(NSObject *)data andCallback:(NSString *)callback
{
    if (event
        && event.length > 0) {
        NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: JSTypeEvent, kJSType,
                                      event, kJSEvent,
                                      nil];
        if (data) {
            [dict setObject:data forKey:kJSData];
        }
        if (callback) {
            [dict setObject:callback forKey:kJSCallback];
        }
        
        [self executeScriptInWebView:WEB_LAYER withDictionary:dict];
    }
#if DEBUG_COBALT
    else {
        NSLog(@"sendEventToWebLayer: invalid event (null or empty)");
    }
#endif
}

- (BOOL)onCobaltMessage:(NSString *)message {
    NSDictionary * jsonObj = [Cobalt dictionaryWithString:message];
    return [self handleDictionarySentByJavaScript: jsonObj];
}

- (BOOL)handleDictionarySentByJavaScript:(NSDictionary *)dict
{
    NSString * type = [dict objectForKey:kJSType];
    
    if (type
        && [type isKindOfClass:[NSString class]]) {
        
        // CALLBACK
        if ([type isEqualToString:JSTypeCallBack]) {
            NSString * callback = [dict objectForKey:kJSCallback];
            NSDictionary * data = [dict objectForKey:kJSData];
            
            if (callback
                && [callback isKindOfClass:[NSString class]]) {
                if ([callback isEqualToString:JSEventCallbackOnBackButtonPressed]) {
                    [self popViewController];
                }
                else if ([callback isEqualToString:JSCallbackPullToRefreshDidRefresh]) {
                    [self.refreshControl endRefreshing];
                    self.refreshControl.attributedTitle = _ptrRefreshText;
                    _isRefreshing = NO;
                }
                else if ([callback isEqualToString:JSCallbackInfiniteScrollDidRefresh]) {
                    [self onInfiniteScrollDidRefresh];
                }
                else {
#if DEBUG_COBALT
                    NSLog(@"handleDictionarySentByJavaScript: unhandled callback %@", [dict description]);
#endif
                    if (_delegate != nil
                        && [_delegate respondsToSelector:@selector(onUnhandledCallback:withData:)]) {
                        return [_delegate onUnhandledCallback:callback withData:data];
                    }
                    else {
                        return NO;
                    }
                }
            }
#if DEBUG_COBALT
            else {
                NSLog(@"handleDictionarySentByJavaScript: callback field missing or not a string (message: %@)", [dict description]);
            }
#endif
        }
        
        // COBALT IS READY
        else if ([type isEqualToString:JSTypeCobaltIsReady]) {
            [toJavaScriptOperationQueue setSuspended:NO];
            if (_delegate != nil
                && [_delegate respondsToSelector:@selector(onCobaltIsReady)]) {
                [_delegate onCobaltIsReady];
            }
#if DEBUG_COBALT
            NSString * versionWeb = [dict objectForKey:KJSVersion];
            if (![IOSCurrentVersion isEqualToString:versionWeb]) {
                NSLog(@"Warning : Cobalt version mismatch : iOS Cobalt version is %@ but Web Cobalt version is %@. You should fix this.",IOSCurrentVersion, versionWeb);
            }else{
                NSLog(@"handleDictionarySentByJavaScript: CobaltIsReady, version %@",versionWeb);
            }
            
            
#endif
        }
        // EVENT
        else if ([type isEqualToString:JSTypeEvent]) {
            NSString * event = [dict objectForKey:kJSEvent];
            NSDictionary * data = [dict objectForKey:kJSData];
            NSString * callback = [dict objectForKey:kJSCallback];
            
            if (event &&
                [event isKindOfClass:[NSString class]]) {
                if (_delegate != nil
                    && [_delegate respondsToSelector:@selector(onUnhandledEvent:withData:andCallback:)]) {
                    BOOL toReturn = [_delegate onUnhandledEvent:event withData:data andCallback:callback];
                    if(!toReturn) {
#if DEBUG_COBALT
                        NSLog(@"handleDictionarySentByJavaScript: unhandled event %@", [dict description]);
#endif
                    }
                    
                    return toReturn;
                }
                else {
#if DEBUG_COBALT
                    NSLog(@"handleDictionarySentByJavaScript: unhandled event %@", [dict description]);
#endif
                    return NO;
                }
            }
#if DEBUG_COBALT
            else {
                NSLog(@"handleDictionarySentByJavaScript: event field missing or not a string (message: %@)", [dict description]);
            }
#endif
        }
        
        // LOG
        else if ([type isEqualToString:JSTypeLog]) {
            NSString * text = [dict objectForKey:kJSValue];
            if (text
                && [text isKindOfClass:[NSString class]]) {
                NSLog(@"JS LOG: %@", text);
            }
        }
        
        // NAVIGATION
        else if([type isEqualToString:JSTypeNavigation]) {
            NSString * action = [dict objectForKey:kJSAction];
            
            if (action
                && [action isKindOfClass:[NSString class]]) {
                // PUSH
                if ([action isEqualToString:JSActionNavigationPush]) {
                    NSDictionary * data = [dict objectForKey:kJSData];
                    if (data
                        && [data isKindOfClass:[NSDictionary class]]) {
                        [self pushViewControllerWithData:data];
                    }
#if DEBUG_COBALT
                    else {
                        NSLog(@"handleDictionarySentByJavaScript: data field missing or not an object (message: %@)", [dict description]);
                    }
#endif
                }
                //POP
                else if ([action isEqualToString:JSActionNavigationPop]) {
                    id data = [dict objectForKey:kJSData];
                    if (data != nil
                        && [data isKindOfClass:[NSDictionary class]]) {
                        [self popViewControllerWithData:data];
                    }
                    else {
                        [self popViewController];
                    }
                }
                //MODAL
                else if ([action isEqualToString:JSActionNavigationModal]) {
                    NSDictionary * data = [dict objectForKey:kJSData];
                    if (data
                        && [data isKindOfClass:[NSDictionary class]]) {
                            [self presentViewControllerWithData:data];
                    }
#if DEBUG_COBALT
                    else {
                        NSLog(@"handleDictionarySentByJavaScript: data field missing or not an object (message: %@)", [dict description]);
                    }
#endif
                }
                //DISMISS
                else if ([action isEqualToString:JSActionNavigationDismiss]) {
                    NSDictionary *data = [dict objectForKey:kJSData];
                    if (data
                        && [data isKindOfClass:[NSDictionary class]]) {
                        [self dismissViewControllerWithData:data];
                    }
                    else {
                        [self dismissViewController];
                    }
                }
                //REPLACE
                else if ([action isEqualToString:kJSActionNavigationReplace]) {
                    NSDictionary * data = [dict objectForKey:kJSData];
                    if (data
                        && [data isKindOfClass:[NSDictionary class]]) {
                        [self replaceViewControllerWithData:data];
                    }
#if DEBUG_COBALT
                    else {
                        NSLog(@"handleDictionarySentByJavaScript: data field missing or not an object (message: %@)", [dict description]);
                    }
#endif
                }
                else {
#if DEBUG_COBALT
                    NSLog(@"handleDictionarySentByJavaScript: unhandled navigation %@", [dict description]);
#endif
                    if (_delegate != nil
                        && [_delegate respondsToSelector:@selector(onUnhandledMessage:)]) {
                        return [_delegate onUnhandledMessage:dict];
                    }
                    else {
                        return NO;
                    }
                }
                
            }
#if DEBUG_COBALT
            else {
                NSLog(@"handleDictionarySentByJavaScript: action field missing or not a string (message: %@)", [dict description]);
            }
#endif
        }
        
        // UI
        else if ([type isEqualToString:JSTypeUI]) {
            NSString * control = [dict objectForKey:kJSControl];
            NSDictionary * data = [dict objectForKey:kJSData];
            
            if (control
                && [control isKindOfClass:[NSString class]]) {
                
                // TOAST
                if ([control isEqualToString:JSControlToast]) {
                    if (data
                        && [data isKindOfClass:[NSDictionary class]]) {
                        NSString * message = [data objectForKey:kJSAlertMessage];
                        if (message
                            && [message isKindOfClass: [NSString class]]) {
                            CobaltToast * toast = (CobaltToast *)[[CobaltToast makeText:message] setGravity:iToastGravityBottom];
                            [toast setDelegate:self];
                            if (toastIsShown) {
                                [toastsToShow addObject:toast];
                            }
                            else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [toast show];
                                });
                            }
                        }
#if DEBUG_COBALT
                        else {
                            NSLog(@"handleDictionarySentByJavaScript: message field missing or not a string (message: %@)", [dict description]);
                        }
#endif
                    }
#if DEBUG_COBALT
                    else {
                        NSLog(@"handleDictionarySentByJavaScript: data field missing or not an object (message: %@)", [dict description]);
                    }
#endif
                }
                
                // ALERT
                else if([control isEqualToString:JSControlAlert]) {
                    [self showAlert:dict];
                }
                
                // PULL TO REFRESH
                else if([control isEqualToString:JSControlPullToRefresh]) {
                    if (data
                        && [data isKindOfClass:[NSDictionary class]]) {
                        
                        NSString * action = [data objectForKey: kJSAction];
                        
                        if (action
                            && [action isKindOfClass: [NSString class]]) {
                            
                            
                            if([action isEqualToString:JSActionSetTexts]) {
                                NSDictionary * texts = [data objectForKey: kJSTexts];
                                NSString * pullToRefreshText = [texts objectForKey:kJSTextsPullToRefresh];
                                NSString * refreshingText = [texts objectForKey:kJSTextsRefreshing];
                                
                                [self customizeRefreshControlWithAttributedRefreshText: [[NSAttributedString alloc] initWithString: pullToRefreshText] andAttributedRefreshText: [[NSAttributedString alloc] initWithString: refreshingText] andTintColor: self.refreshControl.tintColor];
                                
                            }
                        }
                    }
                }
                
                // BARS
                else if ([control isEqualToString:JSControlBars]) {
                    if (data != nil
                        && [data isKindOfClass:[NSDictionary class]]) {
                        id action = [data objectForKey:kJSAction];
                        if (action != nil
                            && [action isKindOfClass:[NSString class]]) {
                            // SET BARS
                            if ([action isEqualToString:JSActionSetBars]) {
                                id bars = [data objectForKey:kJSBars];
                                if (bars != nil
                                    && [bars isKindOfClass:[NSDictionary class]]) {
                                    _barsConfiguration = bars;
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                        [self configureBars];
                                        [self resetBarButtonItems];
                                        [self setBarButtonItems];
                                    });
                                }
                            }
                            // SET BARS VISIBLE
                            else if ([action isEqualToString:JSActionSetBarsVisible]) {
                                id visible = [data objectForKey:kConfigurationBarsVisible];
                                if (visible != nil
                                    && [visible isKindOfClass:[NSDictionary class]]) {
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                        [self setBarsVisible:visible];
                                    });
                                }
                            }
                            // SET BAR CONTENT
                            else if ([action isEqualToString:JSActionSetBarContent]) {
                                id content = [data objectForKey:kJSContent];
                                if (content != nil
                                    && [content isKindOfClass:[NSDictionary class]]) {
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                        [self setBarContent:content];
                                    });
                                }
                            }
                            // SET ACTION BADGE
                            else if ([action isEqualToString:JSActionSetActionBadge]) {
                                id barButtonItemName = [data objectForKey:kJSName];
                                id badge = [data objectForKey:kJSBadge];
                                
                                if (barButtonItemName != nil && [barButtonItemName isKindOfClass:[NSString class]]
                                    && badge != nil && [badge isKindOfClass:[NSString class]]) {
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                        [self setBadgeLabelText:badge
                                          forBarButtonItemNamed:barButtonItemName];
                                    });
                                }
                            }
                            // SET ACTION VISIBLE
                            else if ([action isEqualToString:JSActionSetActionVisible]) {
                                id barButtonItemName = [data objectForKey:kJSName];
                                id visible = [data objectForKey:kJSVisible];
                                
                                if (barButtonItemName != nil && [barButtonItemName isKindOfClass:[NSString class]]
                                    && visible != nil && [visible isKindOfClass:[NSNumber class]]) {
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                        [self setVisible:[visible boolValue]
                                          forBarButtonItemNamed:barButtonItemName];
                                    });
                                }
                            }
                            // SET ACTION ENABLED
                            else if ([action isEqualToString:JSActionSetActionEnabled]) {
                                id barButtonItemName = [data objectForKey:kJSName];
                                id enabled = [data objectForKey:kJSEnabled];
                                
                                if (barButtonItemName != nil && [barButtonItemName isKindOfClass:[NSString class]]
                                    && enabled != nil && [enabled isKindOfClass:[NSNumber class]]) {
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                        [self setEnabled:[enabled boolValue]
                                   forBarButtonItemNamed:barButtonItemName];
                                    });
                                }
                            }
                            // SET ACTION CONTENT
                            else if ([action isEqualToString:JSActionSetActionContent]) {
                                id barButtonItemName = [data objectForKey:kJSName];
                                id content = [data objectForKey:kJSContent];
                                
                                if (barButtonItemName != nil && [barButtonItemName isKindOfClass:[NSString class]]
                                    && content != nil && [content isKindOfClass:[NSDictionary class]]) {
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                        [self setContent:content
                                   forBarButtonItemNamed:barButtonItemName];
                                    });
                                }
                            }
                        }
                    }
                }
                else {
#if DEBUG_COBALT
                    NSLog(@"handleDictionarySentByJavaScript: unhandled message %@", [dict description]);
#endif
                    if (_delegate != nil
                        && [_delegate respondsToSelector:@selector(onUnhandledMessage:)]) {
                        return [_delegate onUnhandledMessage:dict];
                    }
                    else {
                        return NO;
                    }
                }
            }
#if DEBUG_COBALT
            else {
                NSLog(@"handleDictionarySentByJavaScript: control field missing or not a string (message: %@)", [dict description]);
            }
#endif
        }
        
        // WEB LAYER
        else if ([type isEqualToString:JSTypeWebLayer]) {
            NSString * action = [dict objectForKey:kJSAction];
            NSDictionary * data = [dict objectForKey:kJSData];
            
            if (action
                && [action isKindOfClass:[NSString class]]) {
                
                // SHOW
                if ([action isEqualToString:JSActionWebLayerShow]) {
                    if (data
                        && [data isKindOfClass:[NSDictionary class]]) {
                        [self showWebLayer:data];
                    }
#if DEBUG_COBALT
                    else {
                        NSLog(@"handleDictionarySentByJavaScript: data field missing or not an object (message: %@)", [dict description]);
                        
                    }
#endif
                }
                
                // DISMISS
                else if([action isEqualToString:JSActionWebLayerDismiss]) {
                    [self dismissWebLayer:data];
                }
            }
#if DEBUG_COBALT
            else {
                NSLog(@"handleDictionarySentByJavaScript: action field missing or not a string (message: %@)", [dict description]);

            }
#endif
        }
        // INTENT
        else if ([type isEqualToString:kJSTypeIntent]) {
            NSString * action = [dict objectForKey:kJSAction];
            NSDictionary * data = [dict objectForKey:kJSData];
            
            if (action
                && [action isKindOfClass:[NSString class]]) {
                
                // OPEN EXTERNAL URL
                if ([action isEqualToString:kJSActionOpenExternalUrl]) {
                    NSString *urlString = [data objectForKey:kJSUrl];
                    if([urlString isKindOfClass:[NSString class]]) {
                        NSString *encodedUrlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        NSURL *url = [NSURL URLWithString:encodedUrlString];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
            }
        }
        // PLUGIN
        else if ([type isEqualToString: kJSTypePlugin]) {
            [[CobaltPluginManager sharedInstance] onMessageFromCobaltViewController: self andData: dict];
        }
        else {
#if DEBUG_COBALT
            NSLog(@"handleDictionarySentByJavaScript: unhandled message %@", [dict description]);
#endif
            if (_delegate != nil
                && [_delegate respondsToSelector:@selector(onUnhandledMessage:)]) {
                return [_delegate onUnhandledMessage:dict];
            }
            else {
                return NO;
            }
        }
    }
    else {
#if DEBUG_COBALT
        NSLog(@"handleDictionarySentByJavaScript: unhandled message %@", [dict description]);
#endif
        if (_delegate != nil
            && [_delegate respondsToSelector:@selector(onUnhandledMessage:)]) {
            return [_delegate onUnhandledMessage:dict];
        }
        else {
            return NO;
        }
    }
    
    return YES;
}

- (void) sendMessage:(NSDictionary *) message {
    if (message != nil) [self executeScriptInWebView:WEB_VIEW withDictionary:message];
#if DEBUG_COBALT
    else NSLog(@"sendMessage: message is nil!");
#endif
}


- (void) sendMessageToWebLayer:(NSDictionary *) message {
    if (message != nil && webLayer != nil) [self executeScriptInWebView:WEB_LAYER withDictionary:message];
#if DEBUG_COBALT
    else NSLog(@"sendMessage: message is nil!");
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark NAVIGATION METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)pushViewControllerWithData:(NSDictionary *)data {
    id page = [data objectForKey:kJSPage];
    id controller = [data objectForKey:kJSNavigationController];
    id barsConfiguration = [data objectForKey:kJSBars];
    id innerData = [data objectForKey:kJSData];
    
    if (page != nil
        && [page isKindOfClass:[NSString class]]) {
        CobaltViewController *viewController = [Cobalt cobaltViewControllerForController:controller
                                                                                 andPage:page];
        if (viewController != nil) {
            if (barsConfiguration != nil
                && [barsConfiguration isKindOfClass:[NSDictionary class]]) {
                viewController.barsConfiguration = barsConfiguration;
            }
            
            if (innerData != nil
                && [innerData isKindOfClass:[NSDictionary class]]) {
                viewController.navigationData = innerData;
            }
            
            // Push corresponding viewController
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:viewController
                                                     animated:YES];
            });
        }
    }
    else if (controller != nil
             && [controller isKindOfClass:[NSString class]]){
        UIViewController *viewController = [Cobalt nativeViewControllerForController:controller];
        if (viewController != nil) {
            // Push corresponding viewController
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:viewController
                                                     animated:YES];
            });
        }
    }
#if DEBUG_COBALT
    else {
        NSLog(@"pushViewControllerWithData: one of page or controller fields must be specified at least.");
    }
#endif
}


- (void)popViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)popViewControllerWithData:(NSDictionary *)data {
    id page = [data objectForKey:kJSPage];
    id controller = [data objectForKey:kJSNavigationController];
    id innerData = [data objectForKey:kJSData];
    
    if (page == nil
        && controller == nil) {
        if (innerData != nil
            && [innerData isKindOfClass:[NSDictionary class]]) {
            NSArray *viewControllers = self.navigationController.viewControllers;
            if (viewControllers.count > 1) {
                UIViewController *popToViewController = [viewControllers objectAtIndex:viewControllers.count - 2];
                if ([popToViewController isKindOfClass:[CobaltViewController class]]) {
                    ((CobaltViewController *)popToViewController).navigationData = innerData;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    else {
        NSString *controllerClassName;
        if (controller
            && [controller isKindOfClass:[NSString class]]) {
            NSDictionary *controllerConfiguration = [Cobalt configurationForController:controller];
            if (controllerConfiguration != nil) {
                controllerClassName = [controllerConfiguration objectForKey:kConfigurationIOS];
            }
        }
        
        for (UIViewController *viewController in self.navigationController.viewControllers) {
            if (((controllerClassName == nil && controller == nil) || [viewController isKindOfClass:NSClassFromString(controllerClassName)])
                && (page == nil || ([viewController isKindOfClass:[CobaltViewController class]] && [((CobaltViewController *)viewController).pageName isEqualToString:page]))) {
                if ([viewController isKindOfClass:[CobaltViewController class]]
                    && innerData != nil && [innerData isKindOfClass:[NSDictionary class]]) {
                    ((CobaltViewController *)viewController).navigationData = innerData;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController popToViewController:viewController
                                                          animated:YES];
                });
                break;
            }
        }
    }
}

- (void)presentViewControllerWithData:(NSDictionary *)data {
    id page = [data objectForKey:kJSPage];
    id controller = [data objectForKey:kJSNavigationController];
    id barsConfiguration = [data objectForKey:kJSBars];
    id innerData = [data objectForKey:kJSData];
    
    if (page != nil
        && [page isKindOfClass:[NSString class]]) {
        CobaltViewController *viewController = [Cobalt cobaltViewControllerForController:controller
                                                                                 andPage:page];
        if (viewController != nil) {
            if (barsConfiguration != nil
                && [barsConfiguration isKindOfClass:[NSDictionary class]]) {
                viewController.barsConfiguration = barsConfiguration;
            }
            
            if (innerData != nil
                && [innerData isKindOfClass:[NSDictionary class]]) {
                viewController.navigationData = innerData;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:viewController]
                                   animated:YES
                                 completion:nil];
            });
        }
    }
    else if (controller != nil
             && [controller isKindOfClass:[NSString class]]){
        UIViewController *viewController = [Cobalt nativeViewControllerForController:controller];
        if (viewController != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:viewController]
                                   animated:YES
                                 completion:nil];
            });
        }
    }
#if DEBUG_COBALT
    else {
        NSLog(@"presentViewControllerWithData: one of page or controller fields must be specified at least.");
    }
#endif
}

- (void)dismissViewController {
    if (self.presentingViewController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.presentingViewController dismissViewControllerAnimated:YES
                                                              completion:nil];
        });
    }
#if DEBUG_COBALT
    else {
        NSLog(@"dismissViewController: current controller was not presented");
    }
#endif
}

- (void)dismissViewControllerWithData:(NSDictionary *)data {
    if (self.presentingViewController) {
        id innerData = [data objectForKey:kJSData];
        
        if (innerData
            && [innerData isKindOfClass:[NSDictionary class]]) {
            UIViewController *popToViewController;
            if ([self.presentingViewController isKindOfClass:[UINavigationController class]]) {
                popToViewController = ((UINavigationController *)self.presentingViewController).viewControllers.lastObject;
            }
            else if ([self.presentingViewController isKindOfClass:[UIViewController class]]) {
                popToViewController = self.presentingViewController;
            }
            
            if (popToViewController
                && [popToViewController isKindOfClass:[CobaltViewController class]]) {
                ((CobaltViewController *)popToViewController).navigationData = innerData;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.presentingViewController dismissViewControllerAnimated:YES
                                                              completion:nil];
        });
    }
#if DEBUG_COBALT
    else {
        NSLog(@"dismissViewControllerWithData: current controller was not presented");
    }
#endif
}

- (void)replaceViewControllerWithData:(NSDictionary *)data {
    id page = [data objectForKey:kJSPage];
    id controller = [data objectForKey:kJSNavigationController];
    id barsConfiguration = [data objectForKey:kJSBars];
    BOOL animated = [[data objectForKey: kJSAnimated] boolValue];
    BOOL clearHistory = [[data objectForKey: kJSClearHistory] boolValue];
    id innerData = [data objectForKey:kJSData];
    
    if (page != nil
        && [page isKindOfClass:[NSString class]]) {
        CobaltViewController *viewController = [Cobalt cobaltViewControllerForController:controller
                                                                                 andPage:page];
        if (viewController != nil) {
            if (barsConfiguration != nil
                && [barsConfiguration isKindOfClass:[NSDictionary class]]) {
                viewController.barsConfiguration = barsConfiguration;
            }
            
            if (innerData != nil
                && [innerData isKindOfClass:[NSDictionary class]]) {
                viewController.navigationData = innerData;
            }
            
            // replace current view with corresponding viewController
            dispatch_async(dispatch_get_main_queue(), ^{
                if (clearHistory) {
                    [self.navigationController setViewControllers:@[viewController]
                                                         animated:animated];
                }
                else {
                    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
                    [viewControllers replaceObjectAtIndex:(viewControllers.count - 1)
                                               withObject:viewController];
                    [self.navigationController setViewControllers:viewControllers
                                                         animated:animated];
                }
            });
        }
    }
    else if (controller != nil
             && [controller isKindOfClass:[NSString class]]) {
        UIViewController *viewController = [Cobalt nativeViewControllerForController:controller];
        if (viewController != nil) {
            // Push corresponding viewController
            dispatch_async(dispatch_get_main_queue(), ^{
                if (clearHistory) {
                    [self.navigationController setViewControllers:@[viewController]
                                                         animated:animated];
                }
                else {
                    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
                    [viewControllers replaceObjectAtIndex:(viewControllers.count - 1)
                                               withObject:viewController];
                    [self.navigationController setViewControllers:viewControllers
                                                         animated:animated];
                }
            });
                
        }
    }
#if DEBUG_COBALT
    else {
        NSLog(@"replaceViewControllerWithData: one of page or controller fields must be specified at least.");
    }
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark BACK BARBUTTONITEM DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)onBackButtonPressed {
    [self sendEvent:JSEventCallbackOnBackButtonPressed
           withData:nil
        andCallback:JSEventCallbackOnBackButtonPressed];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ALERTS METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)showAlert:(NSDictionary *)dict
{
    NSDictionary * data = [dict objectForKey:kJSData];
    NSString * callback = [dict objectForKey:kJSCallback];
    
    if (data && [data isKindOfClass:[NSDictionary class]]) {
        NSString * title = ([data objectForKey:kJSAlertTitle] && [[data objectForKey:kJSAlertTitle] isKindOfClass:[NSString class]]) ? [data objectForKey:kJSAlertTitle] : @"";
        NSString * message = ([data objectForKey:kJSAlertMessage] && [[data objectForKey:kJSAlertMessage] isKindOfClass:[NSString class]]) ? [data objectForKey:kJSAlertMessage] : @"";
        NSArray * buttons = ([data objectForKey:kJSAlertButtons] && [[data objectForKey:kJSAlertButtons] isKindOfClass:[NSArray class]]) ? [data objectForKey:kJSAlertButtons] : [NSArray array];
        
        NSString * systemVersion = [[UIDevice currentDevice] systemVersion];
        if ([systemVersion compare: @"8.0" options:NSNumericSearch] != NSOrderedAscending) {
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:title
                                                                                      message:message
                                                                               preferredStyle:UIAlertControllerStyleAlert];
            if (! buttons.count) {
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK",
                                                                                                                 @"Localizable",
                                                                                                                 [Cobalt bundleResources],
                                                                                                                 @"OK")
                                                                        style:UIAlertActionStyleCancel
                                                                      handler:^(UIAlertAction * action) {
                        if (callback && [callback isKindOfClass:[NSString class]]) {
                            NSDictionary * data = [NSDictionary dictionaryWithObjectsAndKeys:@0, kJSAlertButtonIndex, nil];
                            [self sendCallback:callback withData:data];
                        }
                    }
                ];
                
                [alertController addAction:cancelAction];
            }
            else {
                for (int i = 0 ; i < buttons.count ; i++) {
                    UIAlertAction * action = [UIAlertAction actionWithTitle:[buttons objectAtIndex:i]
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                           if (callback && [callback isKindOfClass:[NSString class]]) {
                               NSDictionary * data = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:i], kJSAlertButtonIndex, nil];
                               [self sendCallback:callback withData:data];
                           }
                       }
                    ];
                    
                    [alertController addAction:action];
                }
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [self presentViewController:alertController animated:YES completion:nil];
            }];
        }
        else {
            UIAlertView * alertView;
            id delegate = (callback != nil && [callback isKindOfClass:[NSString class]]) ? self : nil;
            
            if (! buttons.count) {
                alertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:delegate
                                             cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK",
                                                                                                  @"Localizable",
                                                                                                  [Cobalt bundleResources],
                                                                                                  @"OK")
                                             otherButtonTitles:nil];
            }
            else {
                alertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:delegate
                                             cancelButtonTitle:nil
                                             otherButtonTitles:nil];
                
                // Add buttons
                for (int i = 0 ; i < buttons.count ; i++) {
                    [alertView addButtonWithTitle:[buttons objectAtIndex:i]];
                }
            }
            
            if (delegate != nil) {
                alertView.tag = [self alertViewTag];
                [alertCallbacks setObject:callback
                                   forKey:[NSNumber numberWithInteger:alertView.tag]];
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [alertView show];
            }];
        }
    }
#if DEBUG_COBALT
    else {
        NSLog(@"showAlert: data field missing or not an object (message: %@)", [dict description]);
    }
#endif
}

- (NSInteger)alertViewTag {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidRef);
    return ((__bridge_transfer NSString *) uuidStringRef).integerValue;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSNumber *key = [NSNumber numberWithInteger:alertView.tag];
    
    NSString *callback = [alertCallbacks objectForKey:key];
    if (callback != nil
        && [callback isKindOfClass:[NSString class]]) {
        [self sendCallback:callback
                  withData:@{kJSAlertButtonIndex: [NSNumber numberWithInteger:buttonIndex]}];
        
        [alertCallbacks removeObjectForKey:key];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark WEB LAYER

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)showWebLayer:(NSDictionary *)data
{
    if (webLayer
        && webLayer.superview) {
        [webLayer removeFromSuperview];
        [webLayer setDelegate:nil];
        webLayer = nil;
    }
    
    webLayerPage = [data objectForKey:kJSPage];
    NSNumber * fadeDuration = ([data objectForKey:kJSWebLayerFadeDuration] && [[data objectForKey:kJSWebLayerFadeDuration] isKindOfClass:[NSNumber class]]) ? [data objectForKey:kJSWebLayerFadeDuration] : [NSNumber numberWithFloat:0.3];
    
    if (webLayerPage) {
        webLayer = [[UIWebView alloc] initWithFrame:self.view.bounds];
        [webLayer setDelegate:self];
        [webLayer setAlpha:0.0];
        [webLayer setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [webLayer setBackgroundColor:[UIColor clearColor]];
        [webLayer setOpaque:NO];
        [webLayer.scrollView setBounces:NO];
        
        if ([webLayer respondsToSelector:@selector(setKeyboardDisplayRequiresUserAction:)]) {
            [webLayer setKeyboardDisplayRequiresUserAction:NO];
        }
        
        [self loadPage:webLayerPage inWebView:webLayer];
        
        [self.view addSubview:webLayer];
        [UIView animateWithDuration:fadeDuration.floatValue animations:^{
            [webLayer setAlpha:1.0];
        } completion:nil];
    }
#if DEBUG_COBALT
    else {
        NSLog(@"showWebLayer: page field missing or not a string (data: %@)", data);
    }
#endif
}

// TODO: like Android code, implement getDataForDismiss
- (void)dismissWebLayer:(NSDictionary *)data
{
    // Guillaume told me that having a customizable fadeDuration is a bad idea. So, it's a fixed fadeDuration...
    // REMEMBER, So if Guillaume tells me the opposite, he owes me a chocolate croissant :)
    NSNumber * fadeDuration = [NSNumber numberWithFloat:0.3];
    //NSNumber * fadeDuration = (dict && [dict objectForKey:kJSWebLayerFadeDuration] && [[dict objectForKey:kJSWebLayerFadeDuration] isKindOfClass:[NSNumber class]]) ? [dict objectForKey:kJSWebLayerFadeDuration] : [NSNumber numberWithFloat:0.3];
    
    [UIView animateWithDuration:fadeDuration.floatValue animations:^{
        [webLayer setAlpha:0.0];
    } completion:^(BOOL finished) {
        [webLayer removeFromSuperview];
        [webLayer setDelegate:nil];
        webLayer = nil;

        [self onWebLayerDismissed:webLayerPage withData:data];
        webLayerPage = nil;
    }];
}

- (void)onWebLayerDismissed:(NSString *)page withData:(NSDictionary *)dict
{
    NSDictionary * data = [NSDictionary dictionaryWithObjectsAndKeys:   page, kJSPage,
                                                                        dict, kJSData,
                                                                        nil];
    [self sendEvent:JSEventWebLayerOnDismiss withData:data andCallback:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark WEBVIEW DELEGATE METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSString *requestURL = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // if requestURL contains cobaltSpecialJSKey, extracts the JSON received.
    NSString *cobaltSpecialJSKey = @"cob@l7#k&y";
    NSRange range = [requestURL rangeOfString:cobaltSpecialJSKey];
    if (range.location != NSNotFound) {
        NSString *json = [requestURL substringFromIndex:range.location + cobaltSpecialJSKey.length];
        NSDictionary *jsonObj = [Cobalt dictionaryWithString:json];
        
        [fromJavaScriptOperationQueue addOperationWithBlock:^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self handleDictionarySentByJavaScript:jsonObj];
            });
        }];
        
        [self sendACK];
        
        return NO;
    }
    
    // Returns YES to ensure regular navigation working as expected.
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [activityIndicator startAnimating];
    
    // Stops queues until Web view is loaded
    [toJavaScriptOperationQueue setSuspended:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // start queue
    [toJavaScriptOperationQueue setSuspended:NO];
    [activityIndicator stopAnimating];
}

- (void)sendACK
{
    [self sendCallback:JSCallbackSimpleAcquitment withData:nil];
    
    if (webLayer) {
        NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:   JSTypeCallBack, kJSType,
                                                                            JSCallbackSimpleAcquitment, kJSCallback,
                                                                            nil];
        [self executeScriptInWebView:WEB_LAYER withDictionary:dict];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark COBALT TOAST DELEGATE METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)toastWillShow:(CobaltToast *)toast
{
    toastIsShown = YES;
#if DEBUG_COBALT
    NSLog(@"toastWillShow");
#endif
}

- (void)toastWillHide:(CobaltToast *)toast
{
    toastIsShown = NO;
    if (toastsToShow.count > 0) {
        CobaltToast * toast = [toastsToShow objectAtIndex:0];
        [toast performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [toastsToShow removeObjectAtIndex:0];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SCROLL VIEW DELEGATE METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

//*************
// DID SCROLL *
//*************
/*!
 @method        - (void)scrollViewDidScroll:(UIScrollView *)scrollView
 @abstract      Tells the delegate when the user scrolls the content view within the receiver.
 @param         scrollView  The scroll-view object in which the scrolling occurred.
 */
- (void)scrollViewDidScroll:(UIScrollView *)_scrollView {
    if ([_scrollView isEqual:webView.scrollView]) {
        float height = _scrollView.frame.size.height;
        float contentHeight = _scrollView.contentSize.height;
        float contentOffset = _scrollView.contentOffset.y;
        
        if (isInfiniteScrollEnabled
            && ! _isLoadingMore
            && _scrollView.isDragging && contentOffset > _lastWebviewContentOffset
			&& (contentOffset + height) > (contentHeight - height * _infiniteScrollOffset / 100)) {
            [self loadMoreItems];
        }
        
        _lastWebviewContentOffset = contentOffset;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark PULL-TO-REFRESH METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

//**********
// REFRESH *
//**********
/*!
 @method		- (void)refresh
 @abstract		Tells the web view to refresh its content.
 */
- (void)refresh {
    if (isPullToRefreshEnabled) {
        _isRefreshing = YES;
        
        self.refreshControl.attributedTitle = _ptrRefreshingText;
        
        [self refreshWebView];
    }
}

//*******************
// REFRESH WEB VIEW *
//*******************
/*!
 @method		- (void)refreshWebView
 @abstract		Sends event to refresh Web view content.
 */
- (void)refreshWebView
{
    [self sendEvent:JSEventPullToRefresh withData:nil andCallback:JSCallbackPullToRefreshDidRefresh];
}


/*!
 @method		- (void)customizeRefreshControlWithAttributedRefreshText:(NSAttributedString *)attributedRefreshText andAttributedRefreshText:(NSAttributedString *)attributedRefreshingText andTintColor: (UIColor *)tintColor;
 @abstract		customize native pull to refresh control
 */
- (void)customizeRefreshControlWithAttributedRefreshText:(NSAttributedString *)attributedRefreshText andAttributedRefreshText:(NSAttributedString *)attributedRefreshingText andTintColor: (UIColor *)tintColor {
    _ptrRefreshText = attributedRefreshText;
    _ptrRefreshingText = attributedRefreshingText;
    
    self.refreshControl.attributedTitle = attributedRefreshText;
    self.refreshControl.tintColor = tintColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark INFINITE SCROLL METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: How can IS works with these methods? O_o
- (void)loadMoreItems
{
    _isLoadingMore = YES;
    
    [self loadMoreContentInWebview];
}

- (void)loadMoreContentInWebview
{
    [self sendEvent:JSEventInfiniteScroll withData:nil andCallback:JSCallbackInfiniteScrollDidRefresh];
}

- (void)onInfiniteScrollDidRefresh
{
    _isLoadingMore = NO;
}

@end
