/**
 *
 * CobaltAbstractPlugin.m
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

#import "CobaltAbstractPlugin.h"

#import <objc/runtime.h>

#import "Cobalt.h"

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SINGLETON

////////////////////////////////////////////////////////////////////////////////////////////////

static CobaltAbstractPlugin *cobaltPluginInstance;

@implementation CobaltAbstractPlugin

+ (CobaltAbstractPlugin *)sharedInstanceWithCobaltViewController: (CobaltViewController *)viewController {
    CobaltAbstractPlugin * instance = (CobaltAbstractPlugin *)objc_getAssociatedObject(self, &cobaltPluginInstance);
    if( !instance ){
        instance = [[self alloc] init];
        
        objc_setAssociatedObject(self, &cobaltPluginInstance, instance, OBJC_ASSOCIATION_RETAIN);
    }
    return instance;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark INITIALISATION

////////////////////////////////////////////////////////////////////////////////////////////////

- (id)init{
	if (self = [super init]) {
        _viewControllersArray = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewControllerDeallocated:) name:viewControllerDeallocatedNotification object:nil];
    }
	return self;
}

- (void)onMessageFromCobaltController:(CobaltViewController *)viewController andData: (NSDictionary *)data {
}

- (void)onMessageFromWebLayerWithCobaltController:(CobaltViewController *)viewController andData: (NSDictionary *)data {

}


- (void)viewControllerDeallocated:(NSNotification *)notification {
    CobaltViewController * viewController = [notification object];
    
    [cobaltPluginInstance.viewControllersArray removeObject: [NSValue valueWithNonretainedObject: viewController]];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:viewControllerDeallocatedNotification object:nil];
}

@end
