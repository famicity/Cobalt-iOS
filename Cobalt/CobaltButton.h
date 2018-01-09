/**
 *
 * CobaltButton.h
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

#define POSITION_TOP    1
#define POSITION_BOTTOM 2

@interface CobaltButton : UIButton

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *visible;
@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *badgeLabel;

- (instancetype)initWithImage:(UIImage *)image
                 andBarHeight:(CGFloat)height;
- (instancetype)initWithImage:(UIImage *)image
                 tintColor:(UIColor *)tintColor
                 andBarHeight:(CGFloat)height;
- (instancetype)initWithAttributedTitle:(NSAttributedString *)title
                           andBarHeight:(CGFloat)height;

- (void)setImage:(UIImage *)image
   withBarHeight:(CGFloat)height;
- (void)setImage:(UIImage *)image
   withTintColor:(UIColor *)tintColor
    andBarHeight:(CGFloat)height;
- (void)setAttributedTitle:(NSAttributedString *)title
             withBarHeight:(CGFloat)height;

- (void)updateEdgeInsetsWithBarPosition:(int)position
                              andHeight:(CGFloat)height;

- (void)setBadgeLabelWithText:(NSString *)text;
- (void)resizeBadge;

@end
