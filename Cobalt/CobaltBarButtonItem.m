/**
 *
 * CobaltBarButtonItem.m
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

#import "CobaltBarButtonItem.h"

#import "Cobalt.h"
#import "CobaltFontManager.h"

@implementation CobaltBarButtonItem

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark INIT

////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithAction:(NSDictionary *)action
                     barHeight:(CGFloat)barHeight
                      barColor:(UIColor *)barColor
                   andDelegate:(id<CobaltBarButtonItemDelegate>)delegate {
    id name = [action objectForKey:kConfigurationBarsActionName];                 //NSString  (mandatory)
    id iosIcon = [action objectForKey:kConfigurationBarsActionIconIOS];           //NSString  (default: nil, img.png)
    id icon = [action objectForKey:kConfigurationBarsActionIcon];                 //NSString  (default: nil, "fc fc-*" ou "fa fa-*")
    id title = [action objectForKey:kConfigurationBarsActionTitle];               //NSString  (mandatory)
    id color = [action objectForKey:kConfigurationBarsActionColor];               //NSString  (default: nil)
    id badge = [action objectForKey:kConfigurationBarsActionBadge];               //NSString  (default: nil)
    id enabled = [action objectForKey:kConfigurationBarsActionEnabled];           //BOOL      (default: true)
    id visible = [action objectForKey:kConfigurationBarsActionVisible];           //BOOL      (default: true)
    _position = [action objectForKey:kConfigurationBarsActionPosition];
    
    _barHeight = barHeight;
    
    if (color != nil
        && [color isKindOfClass:[NSString class]]) {
        _color = [Cobalt colorFromHexString:color];
    }
    _barColor = barColor;
    self.tintColor = _color != nil ? _color : _barColor;
    
    if (name != nil && [name isKindOfClass:[NSString class]]
        && title != nil && [title isKindOfClass:[NSString class]]) {
        if (iosIcon != nil
            && [iosIcon isKindOfClass:[NSString class]]) {
            UIImage *image = [[UIImage imageNamed:iosIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            if (image != nil) {
                _button = [[CobaltButton alloc] initWithImage:image
                                                    tintColor:self.tintColor
                                                 andBarHeight:_barHeight];
            }
        }
        
        if (_button == nil
            && icon != nil
            && [icon isKindOfClass:[NSString class]]) {
            UIImage *image = [CobaltFontManager imageWithIcon:icon
                                                        color:self.tintColor
                                                      andSize:22.0];
            if (image != nil) {
                _button = [[CobaltButton alloc] initWithImage:image
                                                 andBarHeight:_barHeight];
            }
        }
        
        if (_button == nil) {
            NSRange titleRange = NSMakeRange(0, ((NSString *)title).length);
            
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
            [attributedTitle addAttribute:NSFontAttributeName
                                    value:[UIFont systemFontOfSize:17.0]
                                    range:titleRange];
            [attributedTitle addAttribute:NSForegroundColorAttributeName
                                    value:self.tintColor
                                    range:titleRange];
            
            _button = [[CobaltButton alloc] initWithAttributedTitle:attributedTitle
                                                       andBarHeight:_barHeight];
        }
        
        [_button addTarget:self
                    action:@selector(onBarButtonItemPressed:)
          forControlEvents:UIControlEventTouchUpInside];
        
        if (badge != nil
            && [badge isKindOfClass:[NSString class]]) {
            [_button setBadgeLabelWithText:badge];
            
            if (((NSString *) badge).length > 0) {
                _button.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", badge, title];
            }
            else {
                _button.accessibilityLabel = title;
            }
        }
        else {
            _button.accessibilityLabel = title;
        }
        
        int barPosition = [kConfigurationBarsActionPositionBottom isEqualToString:_position] ? POSITION_BOTTOM : POSITION_TOP;
        [_button updateEdgeInsetsWithBarPosition:barPosition
                                       andHeight:_barHeight];
        
        self = [super initWithCustomView:_button];
        
        _name = name;
        _delegate = delegate;
        
        if (enabled != nil
            && [enabled isKindOfClass:[NSNumber class]]) {
            self.enabled = [enabled boolValue];
        }
        
        if (visible != nil
            && [visible isKindOfClass:[NSNumber class]]) {
            _visible = [visible boolValue];
        }
        else {
            _visible = YES;
        }
        
        return self;
    }
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)resizeWithBarHeight:(CGFloat)barHeight {
    _barHeight = barHeight;
    
    int barPosition = [kConfigurationBarsActionPositionBottom isEqualToString:_position] ? POSITION_BOTTOM : POSITION_TOP;
    [_button updateEdgeInsetsWithBarPosition:barPosition
                                   andHeight:_barHeight];
}

- (void)setContent:(NSDictionary *)content {
    id iosIcon = [content objectForKey:kConfigurationBarsActionIconIOS];
    id icon = [content objectForKey:kConfigurationBarsActionIcon];
    id title = [content objectForKey:kConfigurationBarsActionTitle];
    id color = [content objectForKey:kConfigurationBarsActionColor];
    
    if (color != nil
        && [color isKindOfClass:[NSString class]]) {
        _color = [Cobalt colorFromHexString:color];
        self.tintColor = _color;
    }
    
    if (iosIcon != nil
        && [iosIcon isKindOfClass:[NSString class]]) {
        UIImage *image = [[UIImage imageNamed:iosIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        if (image != nil) {
            [_button setImage:image
                withTintColor:self.tintColor
                 andBarHeight:_barHeight];
        }
    }
    else if (icon != nil
             && [icon isKindOfClass:[NSString class]]) {
        UIImage *image = [CobaltFontManager imageWithIcon:icon
                                                    color:self.tintColor
                                                  andSize:22.0];
        if (image != nil) {
            [_button setImage:image
                withBarHeight:_barHeight];
        }
    }
    else if (title != nil
             && [title isKindOfClass:[NSString class]]) {
        NSRange titleRange = NSMakeRange(0, ((NSString *)title).length);
        
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
        [attributedTitle addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:17.0]
                                range:titleRange];
        [attributedTitle addAttribute:NSForegroundColorAttributeName
                                value:self.tintColor
                                range:titleRange];
        
        [_button setAttributedTitle:attributedTitle
                      withBarHeight:_barHeight];
    }
    
    if (title != nil
        && [title isKindOfClass:[NSString class]]) {
        NSString *badge = _button.badgeLabel.text;
        if (badge != nil
            && badge.length > 0) {
            _button.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", _button.badgeLabel.text, title];
        }
        else {
            _button.accessibilityLabel = title;
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark Badge

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setBadge:(NSString *)text {
    [_button setBadgeLabelWithText:text];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark BUTTON / BARBUTTONITEM DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)onBarButtonItemPressed:(id)sender {
    if (_delegate != nil) {
        [_delegate onBarButtonItemPressed:_name];
    }
}

@end
