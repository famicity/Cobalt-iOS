//
//  CobaltAlert.h
//  Cobalt
//
//  Created by Sébastien Vitard on 04/08/16.
//  Copyright © 2016 Cobaltians. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CobaltAlert;

@protocol CobaltAlertDelegate <NSObject>

@required

- (void)alert:(CobaltAlert *)alert
 withCallback:(NSString *)callback
clickedButtonAtIndex:(NSInteger)index;

@end

@interface CobaltAlert : NSObject <UIAlertViewDelegate>

@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSString *callback;
@property (weak, nonatomic) id<CobaltAlertDelegate> delegate;
@property (strong, nonatomic) UIViewController *viewController;

- (instancetype)initWithData:(NSDictionary *)data
                    callback:(NSString *)callback
                 andDelegate:(id<CobaltAlertDelegate>)delegate
          fromViewController:(UIViewController *)viewController;

- (void)show;

@end
