/**
 *
 * BackBarButtonItem.m
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

#import "BackBarButtonItem.h"

#import "Cobalt.h"

@interface BackBarButtonItem () {
    UIImageView *backButtonImageView;
    UILabel *backButtonTitle;
}

@end

@implementation BackBarButtonItem

- (instancetype)initWithTintColor:(UIColor *)color
                      andDelegate:(id)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        
        UIImage *backButtonImage = [UIImage imageNamed:@"backButton"
                                              inBundle:[NSBundle bundleForClass:[Cobalt class]]
                         compatibleWithTraitCollection:nil];
        backButtonImage = [backButtonImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        backButtonImageView = [[UIImageView alloc] initWithImage:backButtonImage];
        
        backButtonTitle = [[UILabel alloc] init];
        backButtonTitle.font = [UIFont systemFontOfSize:17];
        backButtonTitle.textColor = color;
        backButtonTitle.text = NSLocalizedStringFromTableInBundle(@"back",
                                                                  @"Localizable",
                                                                  [NSBundle bundleForClass:[Cobalt class]],
                                                                  @"Back");
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [backButton addSubview:backButtonImageView];
        [backButton addSubview:backButtonTitle];
        [backButton addTarget:self
                       action:@selector(didTouchDown:)
             forControlEvents:UIControlEventTouchDown];
        [backButton addTarget:self
                       action:@selector(didTouchUp:)
             forControlEvents:UIControlEventTouchUpInside];
        
        backButtonImageView.translatesAutoresizingMaskIntoConstraints = NO;
        backButtonTitle.translatesAutoresizingMaskIntoConstraints = NO;
        
        [backButton addConstraint:[NSLayoutConstraint constraintWithItem:backButtonImageView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backButton
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1.0
                                                                constant:0.0]];
        [backButton addConstraint:[NSLayoutConstraint constraintWithItem:backButtonTitle
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backButton
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1.0
                                                                constant:0.0]];
        [backButton addConstraint:[NSLayoutConstraint constraintWithItem:backButtonImageView
                                                               attribute:NSLayoutAttributeLeading
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backButton
                                                               attribute:NSLayoutAttributeLeading
                                                              multiplier:1.0
                                                                constant:0.0]];
        [backButton addConstraint:[NSLayoutConstraint constraintWithItem:backButtonTitle
                                                               attribute:NSLayoutAttributeLeading
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backButtonImageView
                                                               attribute:NSLayoutAttributeTrailing
                                                              multiplier:1.0
                                                                constant:6.0]];
        
        self.customView = backButton;
    }
    
    return self;
}

- (void)didTouchDown:(id)sender {
    backButtonImageView.alpha = 0.2;
    backButtonTitle.alpha = 0.2;
}

- (void)didTouchUp:(id)sender {
    backButtonImageView.alpha = 1.0;
    backButtonTitle.alpha = 1.0;
    
    if (_delegate != nil) {
        [_delegate onBackButtonPressed];
    }
}

@end
