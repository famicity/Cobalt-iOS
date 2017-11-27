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
@property (strong, nonatomic) UILabel *badgeLabel;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithImage:(UIImage *)image
                 andTintColor:(UIColor *)tintColor ;
- (instancetype)initWithAttributedTitle:(NSAttributedString *)title;

- (void)setImage:(UIImage *)image;
- (void)setImage:(UIImage *)image
   withTintColor:(UIColor *)tintColor;
- (void)setAttributedTitle:(NSAttributedString *)title;

- (void)updateEdgeInsetsWithBarPosition:(int)position
                              andHeight:(CGFloat)height;

/*
- (void)setBadgeLabelWithText:(NSString *)text;
- (void)resizeBadge;
*/

@end
