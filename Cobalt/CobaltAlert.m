//
//  CobaltAlert.m
//  Cobalt
//
//  Created by Sébastien Vitard on 04/08/16.
//  Copyright © 2016 Cobaltians. All rights reserved.
//

#import "CobaltAlert.h"

#import "Cobalt.h"

@implementation CobaltAlert

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark LIFECYCLE

////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithData:(NSDictionary *)data
                    callback:(NSString *)callback
                 andDelegate:(id<CobaltAlertDelegate>)delegate
          fromViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        _viewController = viewController;
        _callback = callback;
        _delegate = delegate;
        
        if (data != nil
            && [data isKindOfClass:[NSDictionary class]]) {
            id title = [data objectForKey:kJSAlertTitle];
            id message = [data objectForKey:kJSAlertMessage];
            id buttons = [data objectForKey:kJSAlertButtons];
            
            if (title == nil
                || ! [title isKindOfClass:[NSString class]]) {
                title = @"";
            }
            if (message == nil
                || ! [message isKindOfClass:[NSString class]]) {
                message = @"";
            }
            if (buttons == nil
                || ! [buttons isKindOfClass:[NSArray class]]) {
                buttons = [NSArray array];
            }
            NSUInteger buttonsCount = ((NSArray *)buttons).count;
            
            NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
            if ([systemVersion compare:@"8.0"
                               options:NSNumericSearch] != NSOrderedAscending) {
                _alertController = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
                
                if (buttonsCount) {
                    for (int i = 0 ; i < buttonsCount ; i++) {
                        UIAlertAction *action = [UIAlertAction actionWithTitle:[buttons objectAtIndex:i]
                                                                         style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction *action) {
                                                                           if (_callback != nil
                                                                               && [_callback isKindOfClass:[NSString class]]) {
                                                                               if (_delegate != nil) {
                                                                                   [_delegate alert:self
                                                                                       withCallback:_callback
                                                                               clickedButtonAtIndex:i];
                                                                               }
#if DEBUG_COBALT
                                                                               else {
                                                                                   NSLog(@"CobaltAlert - a callback was set but delegate is missing.");
                                                                               }
#endif
                                                                           }
                                                                       }];
                        [_alertController addAction:action];
                    }
                }
                else {
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"OK",
                                                                                                                    @"Localizable",
                                                                                                                    [Cobalt bundleResources],
                                                                                                                    @"OK")
                                                                           style:UIAlertActionStyleCancel
                                                                         handler:^(UIAlertAction *action) {
                                                                             if (_callback != nil
                                                                                 && [_callback isKindOfClass:[NSString class]]) {
                                                                                 if (_delegate != nil) {
                                                                                     [_delegate alert:self
                                                                                         withCallback:_callback
                                                                                 clickedButtonAtIndex:0];
                                                                                 }
#if DEBUG_COBALT
                                                                                 else {
                                                                                     NSLog(@"CobaltAlert - a callback was set but delegate is missing.");
                                                                                 }
#endif
                                                                             }
                                                                         }];
                    [_alertController addAction:cancelAction];
                }
            }
            else {
                if (buttonsCount) {
                    _alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:nil];
                    
                    for (int i = 0 ; i < buttonsCount ; i++) {
                        [_alertView addButtonWithTitle:[buttons objectAtIndex:i]];
                    }
                }
                else {
                    _alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK",
                                                                                                       @"Localizable",
                                                                                                       [Cobalt bundleResources],
                                                                                                       @"OK")
                                                  otherButtonTitles:nil];
                }
            }
        }
#if DEBUG_COBALT
        else {
            NSLog(@"CobaltAlert - initWithData:callback:andDelegate:fromViewController: data field missing or not an object.");
        }
#endif
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)show {
    if (_alertController != nil) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            if (_viewController != nil) {
                [_viewController presentViewController:_alertController
                                              animated:YES
                                            completion:nil];
            }
#if DEBUG_COBALT
            else {
               NSLog(@"CobaltAlert - show: unable to show alert, viewController is missing.");
            }
#endif
        }];
    }
    else if (_alertView != nil) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [_alertView show];
        }];
    }
#if DEBUG_COBALT
    else {
        NSLog(@"CobaltAlert - show: unable to show alert, none are set. Check your init call.");
    }
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ALERTVIEW DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_callback != nil
        && [_callback isKindOfClass:[NSString class]]) {
        if (_delegate != nil) {
            [_delegate alert:self
                withCallback:_callback
        clickedButtonAtIndex:buttonIndex];
        }
#if DEBUG_COBALT
        else {
            NSLog(@"CobaltAlert - a callback was set but delegate is missing.");
        }
#endif
    }
}

@end
