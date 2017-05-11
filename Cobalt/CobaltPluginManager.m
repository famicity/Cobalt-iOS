/**
 *
 * CobaltPluginManager.m
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

#import "CobaltPluginManager.h"

#import "Cobalt.h"
#import "CobaltAbstractPlugin.h"

@implementation CobaltPluginManager

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SINGLETON

////////////////////////////////////////////////////////////////////////////////////////////////

static CobaltPluginManager *cobaltPluginManagerInstance = nil;

+ (CobaltPluginManager *)sharedInstance {
	@synchronized(self) {
		if (cobaltPluginManagerInstance == nil) {
			cobaltPluginManagerInstance = [[self alloc] init];
		}
	}
    
	return cobaltPluginManagerInstance;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark INITIALISATION

////////////////////////////////////////////////////////////////////////////////////////////////

- (id)init{
	if (self = [super init]) {
        _pluginsDictionary = [CobaltPluginManager pluginsConfiguration];
        //_pluginsDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"plugins" ofType:@"plist"]];
    }
    
	return self;
}

- (BOOL)onMessageFromWebView:(WebViewType)webView
    fromCobaltViewController:(CobaltViewController *)viewController
                     andData:(NSDictionary *)data {
    NSString *pluginName = [data objectForKey:kJSPluginName];
    
    if ([pluginName isKindOfClass:[NSString class]]) {
        NSString *className = [[_pluginsDictionary objectForKey:pluginName] objectForKey:kConfigurationIOS];
        Class class = NSClassFromString(className);
        if(class) {
            CobaltAbstractPlugin *plugin = [class sharedInstanceWithCobaltViewController:viewController];
            switch (webView) {
                case WEB_VIEW:
                    [plugin onMessageFromCobaltController:viewController
                                                  andData:data];
                    break;
                case WEB_LAYER:
                    [plugin onMessageFromWebLayerWithCobaltController:viewController
                                                              andData:data];
                    break;
            }
            
            return YES;
        }
#if DEBUG_COBALT
        else {
            NSLog(@"\n***********\n%@ class not found\n***********\n", className);
        }
#endif
    }
    
    return NO;
}

+ (NSDictionary *)pluginsConfiguration {
    NSDictionary *cobaltConfiguration = [Cobalt cobaltConfiguration];
    if (cobaltConfiguration == nil) {
        return nil;
    }
    
    id pluginsConfiguration = [cobaltConfiguration objectForKey:kConfigurationPlugins];
    if (pluginsConfiguration == nil
        || ! [pluginsConfiguration isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return pluginsConfiguration;
}

@end
