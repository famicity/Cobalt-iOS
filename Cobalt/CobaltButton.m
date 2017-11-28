/**
 *
 * CobaltButton.m
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

#import "CobaltButton.h"

@interface CobaltButton() {
    UILabel *_titleLabel;
    UIImageView *_iconImageView;
    NSLayoutConstraint *_buttonWidthConstraint;
    NSLayoutConstraint *_buttonHeightConstraint;
    NSLayoutConstraint *_contentWidthConstraint;
    NSLayoutConstraint *_contentHeightConstraint;
}

@end

@implementation CobaltButton

/*
- (CGRect)frame {
    CGRect frame = [super frame];

    if ([[UIDevice currentDevice].systemVersion compare:@"11.0" options:NSNumericSearch] != NSOrderedAscending) {
        frame.origin.x += self.alignmentRectInsets.left;
        frame.origin.y += self.alignmentRectInsets.top;

        frame.size.width -= self.alignmentRectInsets.left;
        frame.size.width -= self.alignmentRectInsets.right;

        frame.size.height -= self.alignmentRectInsets.top;
        frame.size.height -= self.alignmentRectInsets.bottom;
    }

    return frame;
}
*/

- (instancetype)initWithBarHeight:(CGFloat)height {
    if (self = [super init]) {
        if (@available(iOS 11, *)) {
            _buttonHeightConstraint = [self.heightAnchor constraintEqualToConstant:height];
            _buttonHeightConstraint.active = YES;
        }
    }
    
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
                 andBarHeight:(CGFloat)height {
    if (self = [self initWithImage:image
                         tintColor:nil
                      andBarHeight:height]) {
        
    }
    
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
                    tintColor:(UIColor *)tintColor
                 andBarHeight:(CGFloat)height {
    if (self = [self initWithBarHeight:height]) {
        if (! @available(iOS 11, *)) {
            self.frame = CGRectMake(0, 0, 22.0, 22.0);
        }
        
        [self setImage:image
         withTintColor:tintColor
          andBarHeight:height];
    }
    
    return self;
}

- (instancetype)initWithAttributedTitle:(NSAttributedString *)title
                           andBarHeight:(CGFloat)height {
    if (self = [self initWithBarHeight:height]) {
        [self setAttributedTitle:title
                   withBarHeight:height];
    }
    
    return self;
}

- (void)setImage:(UIImage *)image
   withBarHeight:(CGFloat)height {
    [self setImage:image
     withTintColor:nil
      andBarHeight:height];
}

- (void)setImage:(UIImage *)image
   withTintColor:(UIColor *)tintColor
    andBarHeight:(CGFloat)height {
    if (@available(iOS 11, *)) {
        if (_titleLabel != nil) {
            [_titleLabel removeFromSuperview];
            _titleLabel = nil;
            _contentWidthConstraint = nil;
            _contentHeightConstraint = nil;
            
            [self removeConstraint:_buttonWidthConstraint];
            _buttonWidthConstraint = nil;
        }
        
        CGFloat imageWidth = image.size.width;
        CGFloat imageHeight = image.size.height;
        CGFloat maxDimension = MAX(imageWidth, imageHeight);
        CGFloat imageViewWidth, imageViewHeight;
        if (maxDimension > height) {
            CGFloat ratio = height / maxDimension;
            imageViewWidth = imageWidth * ratio;
            imageViewHeight = imageHeight * ratio;
        }
        else {
            imageViewWidth = imageWidth;
            imageViewHeight = imageHeight;
        }
        
        if (_iconImageView == nil) {
            _iconImageView = [[UIImageView alloc] init];
            _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
            
            [self addSubview:_iconImageView];
            
            [[_iconImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor] setActive:YES];
            [[_iconImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor
                                                          constant:-0.3333] setActive:YES];
            _buttonWidthConstraint = [self.widthAnchor constraintEqualToAnchor:_iconImageView.widthAnchor
                                                                      constant:22.0];
            [_buttonWidthConstraint setActive:YES];
        }
        
        if (_contentWidthConstraint == nil) {
            _contentWidthConstraint = [_iconImageView.widthAnchor constraintEqualToConstant:imageViewWidth];
            [_contentWidthConstraint setActive:YES];
        }
        else {
            _contentWidthConstraint.constant = imageViewWidth;
        }
        if (_contentHeightConstraint == nil) {
            _contentHeightConstraint = [_iconImageView.heightAnchor constraintEqualToConstant:imageViewHeight];
            [_contentHeightConstraint setActive:YES];
        }
        else {
            _contentHeightConstraint.constant = imageViewHeight;
        }
        
        _iconImageView.frame = CGRectMake(11.0, (height - imageViewHeight) / 2.0 - 0.3333, imageViewWidth, imageViewHeight);
        _iconImageView.image = image;
        _iconImageView.tintColor = tintColor;
    }
    else {
        [self setImage:image
              forState:UIControlStateNormal];
        self.tintColor = tintColor;
    }
}

- (void)setAttributedTitle:(NSAttributedString *)title
             withBarHeight:(CGFloat)height {
    if (@available(iOS 11, *)) {
        if (_iconImageView != nil) {
            [_iconImageView removeFromSuperview];
            _iconImageView = nil;
            _contentWidthConstraint = nil;
            _contentHeightConstraint = nil;
            
            [self removeConstraint:_buttonWidthConstraint];
            _buttonWidthConstraint = nil;
        }
        
        CGSize titleSize = title.size;
        CGFloat labelheight = titleSize.height;
        
        if (_titleLabel == nil) {
            _titleLabel = [[UILabel alloc] init];
            _titleLabel.shadowOffset = CGSizeZero;
            _titleLabel.opaque = NO;
            _titleLabel.contentMode = UIViewContentModeScaleToFill;
            _titleLabel.backgroundColor = nil;
            _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            
            [self addSubview:_titleLabel];
            
            [[_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor] setActive:YES];
            [[_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor
                                                       constant:-0.6666] setActive:YES];
            _buttonWidthConstraint = [self.widthAnchor constraintEqualToAnchor:_titleLabel.widthAnchor
                                                                      constant:3.0];
            [_buttonWidthConstraint setActive:YES];
        }
        
        if (_contentWidthConstraint == nil) {
            _contentWidthConstraint = [_titleLabel.widthAnchor constraintEqualToConstant:titleSize.width];
            [_contentWidthConstraint setActive:YES];
        }
        else {
            _contentWidthConstraint.constant = titleSize.width;
        }
        if (_contentHeightConstraint == nil) {
            _contentHeightConstraint = [_titleLabel.heightAnchor constraintEqualToConstant:labelheight];
            [_contentHeightConstraint setActive:YES];
        }
        else {
            _contentHeightConstraint.constant = labelheight;
        }
        
        _titleLabel.frame = CGRectMake(0.0, (height - labelheight) / 2.0 - 0.6666, titleSize.width, labelheight);
        _titleLabel.attributedText = title;
    }
    else {
        CGSize titleSize = title.size;
        self.frame = CGRectMake(0, 0, titleSize.width, titleSize.height);
        [self setAttributedTitle:title
                        forState:UIControlStateNormal];
        [self setImage:nil
              forState:UIControlStateNormal];
    }
}

- (void)updateEdgeInsetsWithBarPosition:(int)position
                              andHeight:(CGFloat)height {
    if (@available(iOS 11, *)) {
        BOOL imageUpdated = _iconImageView == nil;
        BOOL titleUpdated = _titleLabel == nil;
        for (UIView *subview in self.subviews) {
            if (! imageUpdated
                && [subview isEqual:_iconImageView]) {
                [self setImage:_iconImageView.image
                 withTintColor:_iconImageView.tintColor
                  andBarHeight:height];
                
                imageUpdated = YES;
            }
            else if (! titleUpdated
                     && [subview isEqual:_titleLabel]) {
                [self setAttributedTitle:_titleLabel.attributedText
                           withBarHeight:height];
                
                titleUpdated = YES;
            }
            
            if (imageUpdated
                && titleUpdated) {
                break;
            }
        }
        
        _buttonHeightConstraint.constant = height;
        [self updateConstraintsIfNeeded];
        [self layoutIfNeeded];
    }
    else {
        switch(position) {
            case POSITION_TOP:
                self.imageEdgeInsets = UIEdgeInsetsMake(-1.0, 0, 1.0, 0);
                
                if (height < 44.0) {
                    self.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                }
                else {
                    self.titleEdgeInsets = UIEdgeInsetsMake(1.0, 0, -1.0, 0);
                }
                break;
            case POSITION_BOTTOM:
                self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                
                if (height < 44.0) {
                    self.titleEdgeInsets = UIEdgeInsetsMake(-1.0, 0, 1.0, 0);
                }
                else {
                    self.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                }
                break;
        }
    }
}

/*
- (void)setBadgeLabelWithText:(NSString *)text {
    if (_badgeLabel == nil) {
        _badgeLabel = [[UILabel alloc] init];
        _badgeLabel.backgroundColor = [UIColor redColor];
        _badgeLabel.textColor = [UIColor whiteColor];
        _badgeLabel.font = [UIFont systemFontOfSize:12.0];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        //[self addSubview:_badgeLabel];
    }
    _badgeLabel.text = text;
    
    [self resizeBadge];
    [self addSubview:_badgeLabel];
}

- (void)resizeBadge {
    [_badgeLabel sizeToFit];
    
    CGSize badgeSize = _badgeLabel.frame.size;
    CGFloat width = badgeSize.width + 6.0 < badgeSize.height ? badgeSize.height : badgeSize.width + 6.0;
    width = width > (self.frame.size.width + badgeSize.height / 2.0) ? self.frame.size.width + badgeSize.height / 2.0 : width;
    
    _badgeLabel.frame = CGRectMake(self.frame.size.width - (width - badgeSize.height / 2.0), - badgeSize.height / 2.0,
                                   width, badgeSize.height);
    _badgeLabel.layer.cornerRadius = _badgeLabel.frame.size.height / 2.0;
    _badgeLabel.layer.masksToBounds = YES;
}

- (UIEdgeInsets)alignmentRectInsets {
    return UIEdgeInsetsMake(0, -5.5, 0, -5.5);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    [self bringSubviewToFront:_badgeLabel];
}
*/

@end
