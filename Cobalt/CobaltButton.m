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

@implementation CobaltButton

- (void)setBadgeLabelWithText:(NSString *)text {
    if (_badgeLabel == nil) {
        _badgeLabel = [[UILabel alloc] init];
        _badgeLabel.backgroundColor = [UIColor redColor];
        _badgeLabel.textColor = [UIColor whiteColor];
        _badgeLabel.font = [UIFont systemFontOfSize:12.0];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
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

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    [self bringSubviewToFront:_badgeLabel];
}

@end
