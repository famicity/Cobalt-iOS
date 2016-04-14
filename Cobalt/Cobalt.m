/**
 *
 * Cobalt.m
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

#import "Cobalt.h"

#import <WebKit/WebKit.h>

//static NSMutableDictionary *sCobaltConfiguration;
static NSDictionary *sCobaltConfiguration;
static NSString *sResourcePath = @"www";
static NSString *sFullResourcePath;

#define NIB_DEFAULT     @"CobaltViewController"

@implementation Cobalt

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark RESOURCE PATH

////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString *)resourcePath {
    if (sFullResourcePath != nil) {
        return sFullResourcePath;
    }
    
    // TODO: check if sFullResourcePath exists in UserDefaults,
    // if yes, set sFullResourcePath and return it,
    // else run code below and register sFullResourcePath in UserDefaults
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    if (mainBundle == nil) {
        NSLog(@"resourcePath: app bundle could not be created.");
        return nil;
    }
    
    if ([WKWebView class]
        && ! [WKWebView instancesRespondToSelector:@selector(loadFileURL:allowingReadAccessToURL:)]) {
        NSURL *resourceDirectoryURL = [NSURL fileURLWithPath:[mainBundle.bundlePath stringByAppendingPathComponent:sResourcePath]];
        
        NSString *temporaryDirectoryPath = NSTemporaryDirectory();
        if (temporaryDirectoryPath != nil) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
            CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
            temporaryDirectoryPath = [temporaryDirectoryPath stringByAppendingPathComponent:(__bridge NSString *)uuidString];
            CFRelease(uuidString);
            CFRelease(uuidRef);
            
            if ([fileManager createDirectoryAtPath:temporaryDirectoryPath
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:nil]) {
                temporaryDirectoryPath = [temporaryDirectoryPath stringByAppendingPathComponent:sResourcePath];
                
                if ([fileManager copyItemAtPath:resourceDirectoryURL.path
                                         toPath:temporaryDirectoryPath
                                          error:nil]) {
                    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:temporaryDirectoryPath];
                    NSString *filename;
                    while((filename = [dirEnum nextObject])) {
                        NSLog(@"%@", filename);
                    }
                    
                    sFullResourcePath = temporaryDirectoryPath;
                    return sFullResourcePath;
                }
            }
        }
        
        return nil;
    }
    
    sFullResourcePath = [mainBundle.resourcePath stringByAppendingPathComponent:sResourcePath];
    return sFullResourcePath;
}

+ (void)setResourcePath:(NSString *)resourcePath {
    sResourcePath = resourcePath;
}

+ (NSBundle *)bundleResources {
    return [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@%@", [NSBundle mainBundle].bundlePath,
                                                       @"/Cobalt.bundle"]];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark CONTROLLERS

////////////////////////////////////////////////////////////////////////////////////////////////

+ (CobaltViewController *)cobaltViewControllerForController:(NSString *)controller
                                                    andPage:(NSString *)page {
    if (page == nil) {
#if DEBUG_COBALT
        NSLog(@"cobaltViewControllerForController:andPage: no page specified");
#endif
        return nil;
    }
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSBundle *cobaltBundle = [Cobalt bundleResources];
    NSString *nib = NIB_DEFAULT;
    
    NSDictionary *configuration = [Cobalt configurationForController:controller];
    if (configuration == nil) {
        configuration = [Cobalt defaultConfiguration];
    }
    if (configuration == nil) {
        CobaltViewController *viewController = [[CobaltViewController alloc] initWithNibName:nib
                                                                                      bundle:cobaltBundle];
        viewController.pageName = page;
        viewController.isPullToRefreshEnabled = false;
        viewController.isInfiniteScrollEnabled = false;
        viewController.infiniteScrollOffset = 0;
        viewController.barsConfiguration = nil;
        
        return viewController;
    }
    
    NSString *class = [configuration objectForKey:kConfigurationIOS];
    nib = [configuration objectForKey:kConfigurationControllerIOSNibName];
    BOOL pullToRefreshEnabled = [[configuration objectForKey:kConfigurationControllerPullToRefresh] boolValue];
    BOOL infiniteScrollEnabled = [[configuration objectForKey:kConfigurationControllerInfiniteScroll] boolValue];
    int infiniteScrollOffset = [configuration objectForKey:kConfigurationControllerInfiniteScrollOffset] != nil ? [[configuration objectForKey:kConfigurationControllerInfiniteScrollOffset] intValue] : 0;
    NSDictionary *barsDictionary = [configuration objectForKey:kConfigurationBars];
    
    if (class == nil) {
#if DEBUG_COBALT
        NSLog(@"cobaltViewControllerForController:andPage: no class found for %@ controller", controller);
#endif
        return nil;
    }
    
    if ([Cobalt isValidCobaltViewControllerWithClassName:class]) {
        if (nib == nil) {
            CobaltViewController *viewController;
            // If nib not defined in configuration file, use same as class if it exists!
            if ([Cobalt isValidNib:class
                         forBundle:mainBundle]) {
                viewController = [[NSClassFromString(class) alloc] initWithNibName:class
                                                                            bundle:mainBundle];
            }
            // If nib file does no exists, use default one i.e. CobaltViewController.xib
            else {
                nib = NIB_DEFAULT;
                
                viewController = [[NSClassFromString(class) alloc] initWithNibName:nib
                                                                            bundle:cobaltBundle];
            }
            
            viewController.pageName = page;
            viewController.isPullToRefreshEnabled = pullToRefreshEnabled;
            viewController.isInfiniteScrollEnabled = infiniteScrollEnabled;
            viewController.infiniteScrollOffset = infiniteScrollOffset;
            viewController.barsConfiguration = barsDictionary;
            
            return viewController;
        }
        else if ([Cobalt isValidNib:nib
                          forBundle:mainBundle]) {
            CobaltViewController *viewController = [[NSClassFromString(class) alloc] initWithNibName:nib
                                                                                              bundle:mainBundle];
            viewController.pageName = page;
            viewController.isPullToRefreshEnabled = pullToRefreshEnabled;
            viewController.isInfiniteScrollEnabled = infiniteScrollEnabled;
            viewController.infiniteScrollOffset = infiniteScrollOffset;
            viewController.barsConfiguration = barsDictionary;
            
            return viewController;
        }
    }
    
    return nil;
}

+ (UIViewController *)nativeViewControllerForController:(NSString *)controller {
    NSDictionary *configuration = [Cobalt configurationForController:controller];
    if (configuration == nil) {
        configuration = [Cobalt defaultConfiguration];
    }
    if (configuration == nil) {
        return nil;
    }
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *class = [configuration objectForKey:kConfigurationIOS];
    NSString *nib = [configuration objectForKey:kConfigurationControllerIOSNibName];
    
    if (class == nil) {
#if DEBUG_COBALT
        NSLog(@"nativeViewControllerForController: no class found for %@ controller", controller);
#endif
        return nil;
    }
    
    if (! [Cobalt isValidNativeViewControllerWithClassName:class]) {
        return nil;
    }
    
    if (nib == nil) {
        // If nib not defined in configuration file, use same as class if it exists!
        if ([Cobalt isValidNib:class
                     forBundle:bundle]) {
            return [[NSClassFromString(class) alloc] initWithNibName:class
                                                              bundle:bundle];
        }
        else {
            return [[NSClassFromString(class) alloc] init];
        }
    }
    else if ([Cobalt isValidNib:nib
                      forBundle:bundle]) {
        return [[NSClassFromString(class) alloc] initWithNibName:nib
                                                          bundle:bundle];
    }
    else {
        return nil;
    }
}

+ (BOOL)isValidNativeViewControllerWithClassName:(NSString *)className {
    Class class = NSClassFromString(className);
    BOOL isValidViewControllerClass = class
    && [class isSubclassOfClass:UIViewController.class];
    BOOL isValidNativeViewControllerClass = class
    && ! [class isSubclassOfClass:CobaltViewController.class];
    
#if DEBUG_COBALT
    if (! isValidViewControllerClass) {
        NSLog(@"isValidNativeViewControllerWithClassName: class %@ not found", className);
    }
    else if (! isValidNativeViewControllerClass) {
        NSLog(@"isValidNativeViewControllerWithClassName: class %@ inherits from CobaltViewController", className);
    }
#endif
    
    return isValidViewControllerClass && isValidNativeViewControllerClass;
}

+ (BOOL)isValidCobaltViewControllerWithClassName:(NSString *)className {
    Class class = NSClassFromString(className);
    BOOL isValidViewControllerClass = class
    && [class isSubclassOfClass:UIViewController.class];
    BOOL isValidCobaltViewControllerClass = class
    && [class isSubclassOfClass:CobaltViewController.class];
    
#if DEBUG_COBALT
    if (! isValidViewControllerClass) {
        NSLog(@"isValidNativeViewControllerWithClassName: class %@ not found", className);
    }
    else if (! isValidCobaltViewControllerClass) {
        NSLog(@"isValidCobaltViewControllerWithClassName: class %@ does not inherit from CobaltViewController", className);
    }
#endif
    
    return isValidViewControllerClass && isValidCobaltViewControllerClass;
}

+ (BOOL)isValidNib:(NSString *)nib
         forBundle:(NSBundle *)bundle {
    BOOL isValidNib = (nib.length > 0
                       && [bundle pathForResource:nib
                                           ofType:@"nib"]);
    
#if DEBUG_COBALT
    if (! isValidNib) {
        NSLog(@"isValidNib:forBundle: %@ nib does not exist!", nib);
    }
#endif
    
    return isValidNib;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark CONFIGURATION

////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSDictionary *)defaultConfiguration {
    NSDictionary *configuration = [Cobalt controllersConfiguration];
    if (configuration == nil) {
        return nil;
    }
    
    NSDictionary *defaultConfiguration = [configuration objectForKey:kConfigurationControllerDefault];
    if (defaultConfiguration == nil
        || ! [defaultConfiguration isKindOfClass:[NSDictionary class]]) {
#if DEBUG_COBALT
        NSLog(@"defaultConfiguration: no configuration found for default controller.");
#endif
        return nil;
    }
    
    return defaultConfiguration;
}

+ (NSDictionary *)configurationForController:(NSString *)controller {
    if (controller == nil) {
#if DEBUG_COBALT
        NSLog(@"configurationForController: controller is nil.");
#endif
        return nil;
    }
    
    NSDictionary *configuration = [Cobalt controllersConfiguration];
    if (configuration == nil) {
        return nil;
    }
    
    NSDictionary *controllerConfiguration = [configuration objectForKey:controller];
    if (controllerConfiguration == nil
        || ! [controllerConfiguration isKindOfClass:[NSDictionary class]]) {
#if DEBUG_COBALT
        NSLog(@"configurationForController: no configuration found for %@ controller.", controller);
#endif
        return nil;
    }
    
    return controllerConfiguration;
}

+ (NSDictionary *)controllersConfiguration {
    NSDictionary *cobaltConfiguration = [Cobalt cobaltConfiguration];
    if (cobaltConfiguration == nil) {
        return nil;
    }
    
    id controllersConfiguration = [cobaltConfiguration objectForKey:kConfigurationControllers];
    if (controllersConfiguration == nil
        || ! [controllersConfiguration isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return controllersConfiguration;
}

+ (NSDictionary *)cobaltConfiguration {
    if (sCobaltConfiguration != nil) {
        return sCobaltConfiguration;
    }
    
    NSString *cobaltResourcePath = [Cobalt resourcePath];
    if (cobaltResourcePath == nil) {
        return nil;
    }
    
    NSData *data = [Cobalt dataWithContentsOfFile:[cobaltResourcePath stringByAppendingPathComponent:@"cobalt.conf"]];
    if (data == nil) {
        return nil;
    }
    
    sCobaltConfiguration = [Cobalt dictionaryWithData:data];
    return sCobaltConfiguration;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark HELPERS

////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSData *)dataWithContentsOfFile:(NSString *)path {
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path
                                          options:0
                                            error:&error];
//#if DEBUG_COBALT
    if (data == nil) {
        NSLog(@"dataWithContentsOfFile: error while reading file at %@\n%@", path, [error localizedFailureReason]);
    }
//#endif
    
    return data;
}

+ (NSDictionary *)dictionaryWithData:(NSData *)data {
    NSError *error;
    id dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];
    if (dictionary == nil
        || ! [dictionary isKindOfClass:[NSDictionary class]]) {
//#if DEBUG_COBALT
        NSLog(@"dictionaryWithData: error while parsing JSON\n%@", [error localizedFailureReason]);
//#endif
        return nil;
    }
    
    return dictionary;
}

+ (NSDictionary *)dictionaryWithString:(NSString *)string {
    NSError *error;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    id dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];

    if (dictionary == nil
        || ! [dictionary isKindOfClass:[NSDictionary class]]) {
//#if DEBUG_COBALT
        NSLog(@"dictionaryWithString: error while parsing JSON %@\n%@", string, [error localizedFailureReason]);
//#endif
        return nil;
    }

    return dictionary;
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    if (hexString == nil) {
        NSLog(@"colorFromHexString: nil hexString.");
        return nil;
    }
    
    unsigned long hexStringLength = hexString.length;
    if (! ((hexStringLength > 2 && hexStringLength < 5) || (hexStringLength > 5 && hexStringLength < 10))) {
        NSLog(@"colorFromHexString: unsupported %@ color format.\n\
              Valid formats are: (#)RGB and (#)RRGGBB(AA).", hexString);
        return nil;
    }
    
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#"
                                                                 withString:@""];
    if (cleanString.length == 3) {
        NSString *redCharacter = [cleanString substringWithRange:NSMakeRange(0, 1)];
        NSString *greenCharacter = [cleanString substringWithRange:NSMakeRange(1, 1)];
        NSString *blueCharacter = [cleanString substringWithRange:NSMakeRange(2, 1)];
        
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       redCharacter, redCharacter,
                       greenCharacter, greenCharacter,
                       blueCharacter, blueCharacter];
    }
    
    if (cleanString.length == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int hexInt;
    BOOL validHexInt = [[NSScanner scannerWithString:cleanString] scanHexInt:&hexInt];
    if (! validHexInt) {
        NSLog(@"colorFromHexString: unsupported %@ color format.\n\
              Valid formats are: (#)RGB and (#)RRGGBB(AA).", hexString);
        return nil;
    }
    
    float red = ((hexInt >> 24) & 0xFF) / 255.0f;
    float green = ((hexInt >> 16) & 0xFF) / 255.0f;
    float blue = ((hexInt >> 8) & 0xFF) / 255.0f;
    float alpha = ((hexInt >> 0) & 0xFF) / 255.0f;
    return [UIColor colorWithRed:red
                           green:green
                            blue:blue
                           alpha:alpha];
}

@end
