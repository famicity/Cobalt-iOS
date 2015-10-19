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

static NSDictionary *sCobaltConfiguration;
static NSString *sResourcePath;

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
    NSBundle *cobaltBundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@%@", mainBundle.bundlePath,
                                                       @"/Frameworks/Cobalt.framework"]];
    NSString *nib = @"CobaltViewController";
    
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
        // TODO: uncomment for Bars
        //viewController.barsConfiguration = [NSMutableDictionary dictionaryWithCapacity:0];
        
        return viewController;
    }
    
    NSString *class = [configuration objectForKey:kIos];
    nib = [configuration objectForKey:kIosNibName];
    BOOL pullToRefreshEnabled = [[configuration objectForKey:@"pullToRefresh"] boolValue];
    BOOL infiniteScrollEnabled = [[configuration objectForKey:@"infiniteScroll"] boolValue];
    int infiniteScrollOffset = [configuration objectForKey:kInfiniteScrollOffset] != nil ? [[configuration objectForKey:kInfiniteScrollOffset] intValue] : 0;
    
    // TODO: uncomment for Bars
    /*
     NSMutableDictionary *barsDictionary = [NSMutableDictionary dictionaryWithDictionary:[configuration objectForKey:kBars]];
     
     NSDictionary *barActionsArray = [barsDictionary objectForKey:kBarActions];
     NSMutableArray *mutableBarActionsArray = [NSMutableArray arrayWithCapacity:barActionsArray.count];
     for(NSDictionary *barActionDictionary in barActionsArray) {
     [mutableBarActionsArray addObject:[NSMutableDictionary dictionaryWithDictionary:barActionDictionary]];
     }
     
     [barsDictionary setObject:mutableBarActionsArray
     forKey:kBarActions];
     */
    
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
                nib = @"CobaltViewController";
                
                viewController = [[NSClassFromString(class) alloc] initWithNibName:nib
                                                                            bundle:cobaltBundle];
            }
            
            viewController.pageName = page;
            viewController.isPullToRefreshEnabled = pullToRefreshEnabled;
            viewController.isInfiniteScrollEnabled = infiniteScrollEnabled;
            viewController.infiniteScrollOffset = infiniteScrollOffset;
            // TODO: uncomment for Bars
            //viewController.barsConfiguration = barsDictionary;
            
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
            // TODO: uncomment for Bars
            //viewController.barsConfiguration = barsDictionary;
            
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
    NSString *class = [configuration objectForKey:kIos];
    NSString *nib = [configuration objectForKey:kIosNibName];
    
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
    
    NSDictionary *defaultConfiguration = [configuration objectForKey:@"default"];
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
    
    id controllersConfiguration = [cobaltConfiguration objectForKey:@"controllers"];
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
    
    NSData *data = [Cobalt dataWithContentsOfFile:[NSString stringWithFormat:@"%@%@",
                                                   cobaltResourcePath,
                                                   @"cobalt.conf"]];
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
                                                    options:0
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
