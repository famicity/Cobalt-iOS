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

- (instancetype)init {
    if (self = [super init]) {
        [[self.heightAnchor constraintEqualToConstant:44.0] setActive:YES];
    }
    
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [self init]) {
        [self setImage:image];
    }
    
    return self;
}

- (instancetype)initWithAttributedTitle:(NSAttributedString *)title {
    if (self = [self init]) {
        [self setAttributedTitle:title];
    }
    
    return self;
}

- (void)setImage:(UIImage *)image {
    if (_titleLabel != nil) {
        [_titleLabel removeFromSuperview];
    }
    
    if (_iconImageView == nil) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat maxDimension = MAX(imageWidth, imageHeight);
    CGFloat imageViewWidth, imageViewHeight;
    if (maxDimension > 44.0) {
        CGFloat ratio = 44.0 / maxDimension;
        imageViewWidth = imageWidth * ratio;
        imageViewHeight = imageHeight * ratio;
    }
    else {
        imageViewWidth = imageWidth;
        imageViewHeight = imageHeight;
    }
    
    _iconImageView.frame = CGRectMake(11.0, (44.0 - imageViewHeight) / 2.0 - 0.3333, imageViewWidth, imageViewHeight);
    _iconImageView.image = image;
    
    [self addSubview:_iconImageView];
    
    [[_iconImageView.widthAnchor constraintEqualToConstant:imageViewWidth] setActive:YES];
    [[_iconImageView.heightAnchor constraintEqualToConstant:imageViewHeight] setActive:YES];
    [[self.widthAnchor constraintEqualToAnchor:_iconImageView.widthAnchor
                                      constant:22.0] setActive:YES];
    [[_iconImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor] setActive:YES];
    [[_iconImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor
                                                  constant:-0.3333] setActive:YES];
}

- (void)setAttributedTitle:(NSAttributedString *)title {
    if (_iconImageView != nil) {
        [_iconImageView removeFromSuperview];
    }
    
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.shadowOffset = CGSizeZero;
        _titleLabel.opaque = NO;
        _titleLabel.contentMode = UIViewContentModeScaleToFill;
        _titleLabel.backgroundColor = nil;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    
    CGSize titleSize = title.size;
    CGFloat buttonWidth = titleSize.width + 3.0;
    CGFloat labelheight = titleSize.height;
    
    _titleLabel.frame = CGRectMake(0.0, (44.0 - labelheight) / 2.0 - 0.5, titleSize.width, labelheight);
    _titleLabel.attributedText = title;
    
    [self addSubview:_titleLabel];
    
    [[_titleLabel.widthAnchor constraintEqualToConstant:titleSize.width] setActive:YES];
    [[_titleLabel.heightAnchor constraintEqualToConstant:labelheight] setActive:YES];
    [[self.widthAnchor constraintEqualToConstant:buttonWidth] setActive:YES];
    [[_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor] setActive:YES];
    [[_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor
                                               constant:-0.5] setActive:YES];
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
