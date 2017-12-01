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

@implementation BackBarButtonItem

- (instancetype)initWithTintColor:(UIColor *)color
                      andDelegate:(id)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        
        NSBundle *cobaltBundle = [Cobalt bundleResources];
        
        UIImage *backButtonImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",
                                                                     cobaltBundle.bundlePath,
                                                                     @"backButton.png"]];
        backButtonImage = [backButtonImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _backButtonImageView = [[UIImageView alloc] initWithImage:backButtonImage];
        
        _backButtonTitle = [[UILabel alloc] init];
        _backButtonTitle.font = [UIFont systemFontOfSize:17];
        _backButtonTitle.textColor = color;
        _backButtonTitle.text = NSLocalizedStringFromTableInBundle(@"back",
                                                                  @"Localizable",
                                                                  cobaltBundle,
                                                                  @"Back");
        [_backButtonTitle sizeToFit];
        
        _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_backButton addSubview:_backButtonImageView];
        [_backButton addSubview:_backButtonTitle];
        [_backButton addTarget:self
                       action:@selector(didTouchDown:)
             forControlEvents:UIControlEventTouchDown];
        [_backButton addTarget:self
                       action:@selector(didTouchUp:)
             forControlEvents:UIControlEventTouchUpInside];
        [_backButton addTarget:self
                       action:@selector(didTouchUp:)
             forControlEvents:UIControlEventTouchUpOutside];
        
        CGSize imageSize = _backButtonImageView.frame.size;
        CGSize titleSize = _backButtonTitle.frame.size;
        CGFloat maxHeight = MAX(imageSize.height, titleSize.height);
        _backButtonImageView.frame = CGRectMake(0.0, (maxHeight - imageSize.height) / 2.0, imageSize.width, imageSize.height);
        _backButtonTitle.frame = CGRectMake(imageSize.width + 6.0, (maxHeight - titleSize.height) / 2.0, titleSize.width, titleSize.height);
        _backButton.frame = CGRectMake(0.0, 0.0, imageSize.width + titleSize.width + 6.0, maxHeight);
        
        if (@available(iOS 11, *)) {
            _backButtonImageView.translatesAutoresizingMaskIntoConstraints = NO;
            _backButtonTitle.translatesAutoresizingMaskIntoConstraints = NO;
            
            // Back button height
            [_backButton addConstraint:[NSLayoutConstraint constraintWithItem:_backButton
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                      toItem:_backButtonImageView
                                                                   attribute:NSLayoutAttributeHeight
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            [_backButton addConstraint:[NSLayoutConstraint constraintWithItem:_backButton
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                      toItem:_backButtonTitle
                                                                   attribute:NSLayoutAttributeHeight
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            // Center vertically
            [_backButton addConstraint:[NSLayoutConstraint constraintWithItem:_backButtonImageView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_backButton
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            [_backButton addConstraint:[NSLayoutConstraint constraintWithItem:_backButtonTitle
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_backButton
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            // Width
            [_backButton addConstraint:[NSLayoutConstraint constraintWithItem:_backButtonImageView
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_backButton
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            [_backButton addConstraint:[NSLayoutConstraint constraintWithItem:_backButtonTitle
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_backButtonImageView
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                    constant:6.0]];
            [_backButton addConstraint:[NSLayoutConstraint constraintWithItem:_backButton
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_backButtonTitle
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                    constant:0.0]];
        }
        
        self.customView = _backButton;
    }
    
    return self;
}

- (void)setTintColor:(UIColor *)color {
    [super setTintColor:color];
    
    _backButtonTitle.textColor = color;
}

- (void)didTouchDown:(id)sender {
    _backButtonImageView.alpha = 0.2;
    _backButtonTitle.alpha = 0.2;
}

- (void)didTouchUp:(id)sender {
    _backButtonImageView.alpha = 1.0;
    _backButtonTitle.alpha = 1.0;
    
    if (_delegate != nil) {
        [_delegate onBackButtonPressed];
    }
}

@end
