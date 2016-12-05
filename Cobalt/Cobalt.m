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

//static NSMutableDictionary *sCobaltConfiguration;
static NSDictionary *sCobaltConfiguration;
static NSString *sResourcePath;

#define NIB_DEFAULT     @"CobaltViewController"

@implementation Cobalt

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark RESOURCE PATH

////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString *)resourcePath {
    if (sResourcePath != nil) {
        return sResourcePath;
    }
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    if (mainBundle == nil) {
        NSLog(@"resourcePath: app bundle could not be created.");
        return nil;
    }
    
    return [NSString stringWithFormat:@"%@%@", [mainBundle resourcePath], @"/www/"];
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
    NSString *nibName = NIB_DEFAULT;
    
    NSDictionary *configuration = [Cobalt configurationForController:controller];
    if (configuration == nil) {
        configuration = [Cobalt defaultConfiguration];
    }
    if (configuration == nil) {
        CobaltViewController *viewController = [[CobaltViewController alloc] initWithNibName:nibName
                                                                                      bundle:cobaltBundle];
        viewController.pageName = page;
        viewController.background = [UIColor whiteColor];
        viewController.scrollsToTop = YES;
        viewController.isPullToRefreshEnabled = false;
        viewController.isInfiniteScrollEnabled = false;
        viewController.infiniteScrollOffset = 0;
        viewController.barsConfiguration = nil;
        
        return viewController;
    }
    
    NSString *className = [configuration objectForKey:kConfigurationIOS];
    nibName = [configuration objectForKey:kConfigurationControllerIOSNibName];
    
    id backgroundColor = [configuration objectForKey:kConfigurationControllerBackgroundColor];
    UIColor *background = [UIColor whiteColor];
    if (backgroundColor != nil
        && [backgroundColor isKindOfClass:[NSString class]]) {
        UIColor *parsedBackgroundColor = [Cobalt colorFromHexString:backgroundColor];
        if (parsedBackgroundColor != nil) {
            background = parsedBackgroundColor;
        }
    }
    
    BOOL scrollsToTop = [configuration objectForKey:kConfigurationControllerScrollsToTop] != nil ? [[configuration objectForKey:kConfigurationControllerScrollsToTop] boolValue] : YES;
    BOOL pullToRefreshEnabled = [[configuration objectForKey:kConfigurationControllerPullToRefresh] boolValue];
    BOOL infiniteScrollEnabled = [[configuration objectForKey:kConfigurationControllerInfiniteScroll] boolValue];
    int infiniteScrollOffset = [configuration objectForKey:kConfigurationControllerInfiniteScrollOffset] != nil ? [[configuration objectForKey:kConfigurationControllerInfiniteScrollOffset] intValue] : 0;
    NSDictionary *barsDictionary = [configuration objectForKey:kConfigurationBars];
    
    if (className == nil) {
#if DEBUG_COBALT
        NSLog(@"cobaltViewControllerForController:andPage: no class found for %@ controller", controller);
#endif
        return nil;
    }
    
    Class class = [Cobalt cobaltViewControllerClassWithName:className];
    if (class != nil) {
        if (nibName == nil) {
            CobaltViewController *viewController;
            // If nib not defined in configuration file, use same as class if it exists!
            if ([Cobalt isValidNib:className
                         forBundle:mainBundle]) {
                viewController = [[class alloc] initWithNibName:className
                                                         bundle:mainBundle];
            }
            // If nib file does no exists, use default one i.e. CobaltViewController.xib
            else {
                nibName = NIB_DEFAULT;
                
                viewController = [[class alloc] initWithNibName:nibName
                                                         bundle:cobaltBundle];
            }
            
            viewController.pageName = page;
            viewController.background = background;
            viewController.scrollsToTop = scrollsToTop;
            viewController.isPullToRefreshEnabled = pullToRefreshEnabled;
            viewController.isInfiniteScrollEnabled = infiniteScrollEnabled;
            viewController.infiniteScrollOffset = infiniteScrollOffset;
            viewController.barsConfiguration = barsDictionary;
            
            return viewController;
        }
        else if ([Cobalt isValidNib:nibName
                          forBundle:mainBundle]) {
            CobaltViewController *viewController = [[class alloc] initWithNibName:nibName
                                                                           bundle:mainBundle];
            viewController.pageName = page;
            viewController.background = background;
            viewController.scrollsToTop = scrollsToTop;
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
    NSString *className = [configuration objectForKey:kConfigurationIOS];
    NSString *nibName = [configuration objectForKey:kConfigurationControllerIOSNibName];
    
    if (className == nil) {
#if DEBUG_COBALT
        NSLog(@"nativeViewControllerForController: no class found for %@ controller", controller);
#endif
        return nil;
    }
    
    Class class = [Cobalt nativeViewControllerClassWithName:className];
    if (class == nil) {
        return nil;
    }
    
    if (nibName == nil) {
        // If nib not defined in configuration file, use same as class if it exists!
        if ([Cobalt isValidNib:className
                     forBundle:bundle]) {
            return [[class alloc] initWithNibName:className
                                           bundle:bundle];
        }
        else {
            return [[class alloc] init];
        }
    }
    else if ([Cobalt isValidNib:nibName
                      forBundle:bundle]) {
        return [[class alloc] initWithNibName:nibName
                                       bundle:bundle];
    }
    else {
        return nil;
    }
}

+ (Class)nativeViewControllerClassWithName:(NSString *)className {
    Class class = NSClassFromString(className);
    if (class == nil) {
        // Try Swift class
        NSString *moduleName = [[[NSBundle mainBundle].infoDictionary[@"CFBundleName"]
                                 componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]
                                componentsJoinedByString:@"_"];
        class = NSClassFromString([NSString stringWithFormat:@"%@.%@", moduleName, className]);
    }
    BOOL isValidViewControllerClass = class != nil && [class isSubclassOfClass:UIViewController.class];
    BOOL isValidNativeViewControllerClass = class != nil && ! [class isSubclassOfClass:CobaltViewController.class];
    
#if DEBUG_COBALT
    if (! isValidViewControllerClass) {
        NSLog(@"nativeViewControllerClassWithName: class %@ not found", className);
    }
    else if (! isValidNativeViewControllerClass) {
        NSLog(@"nativeViewControllerClassWithName: class %@ inherits from CobaltViewController", className);
    }
#endif
    
    return isValidViewControllerClass && isValidNativeViewControllerClass ? class : nil;
}

+ (Class)cobaltViewControllerClassWithName:(NSString *)className {
    Class class = NSClassFromString(className);
    if (class == nil) {
        // Try Swift class
        NSString *moduleName = [[[NSBundle mainBundle].infoDictionary[@"CFBundleName"]
                                 componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]
                                componentsJoinedByString:@"_"];
        class = NSClassFromString([NSString stringWithFormat:@"%@.%@", moduleName, className]);
    }
    
    BOOL isValidViewControllerClass = class != nil && [class isSubclassOfClass:UIViewController.class];
    BOOL isValidCobaltViewControllerClass = class != nil && [class isSubclassOfClass:CobaltViewController.class];
    
#if DEBUG_COBALT
    if (! isValidViewControllerClass) {
        NSLog(@"cobaltViewControllerClassWithName: class %@ not found", className);
    }
    else if (! isValidCobaltViewControllerClass) {
        NSLog(@"cobaltViewControllerClassWithName: class %@ does not inherit from CobaltViewController", className);
    }
#endif
    
    return isValidViewControllerClass && isValidCobaltViewControllerClass ? class : nil;
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
        return (NSMutableDictionary *) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef) sCobaltConfiguration, kCFPropertyListMutableContainersAndLeaves));
    }
    
    NSString *cobaltResourcePath = [Cobalt resourcePath];
    if (cobaltResourcePath == nil) {
        return nil;
    }
    
    NSData *data = [Cobalt dataWithContentsOfFile:[NSString stringWithFormat:@"%@%@",
                                                   cobaltResourcePath,
                                                   @"cobalt.conf"]];
    if (data == nil) {
        return nil;
    }
    
    sCobaltConfiguration = [Cobalt dictionaryWithData:data];
    return (NSMutableDictionary *) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef) sCobaltConfiguration, kCFPropertyListMutableContainersAndLeaves));
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
