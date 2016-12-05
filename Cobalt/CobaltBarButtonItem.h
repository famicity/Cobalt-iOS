/**
 *
 * CobaltBarButtonItem.h
 * Cobalt
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Cobaltians
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

#import <UIKit/UIKit.h>

#import "CobaltButton.h"

@protocol CobaltBarButtonItemDelegate <NSObject>

@required

- (void)onBarButtonItemPressed:(NSString *)name;

@end

@interface CobaltBarButtonItem : UIBarButtonItem {
    CGFloat _barHeight;
    UIColor *_color;
    UIColor *_barColor;
    NSString *_icon;
    NSString *_position;
}

@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) BOOL visible;
@property (weak, nonatomic) id<CobaltBarButtonItemDelegate> delegate;
@property (strong, nonatomic) CobaltButton *button;

- (instancetype)initWithAction:(NSDictionary *)action
                     barHeight:(CGFloat)barHeight
                      barColor:(UIColor *)barColor
                   andDelegate:(id<CobaltBarButtonItemDelegate>)delegate;

- (void)resizeWithBarHeight:(CGFloat)barHeight;
- (void)setContent:(NSDictionary *)content;

- (void)setBadge:(NSString *)text;

@end
