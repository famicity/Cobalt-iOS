/**
 *
 * CobaltFontManager.h
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

#import "CobaltFontManager.h"

#import "Cobalt.h"
#import "CobaltFont.h"

static NSDictionary *sFontsConfiguration;

@implementation CobaltFontManager

+ (UIImage *)imageWithIcon:(NSString *)identifier
                     color:(UIColor *)color
                   andSize:(CGFloat)size {
    UIImage *image = nil;
    
    if (identifier != nil) {
        NSArray *identifierComponents = [identifier componentsSeparatedByString:@" "];
        if (identifierComponents.count > 1) {
            NSString *font = identifierComponents.firstObject;
            NSString *icon = [identifierComponents objectAtIndex:1];
            
            NSDictionary *fontsConfiguration = [CobaltFontManager fontsConfiguration];
            if (fontsConfiguration != nil) {
                id fontConfiguration = [fontsConfiguration objectForKey:font];
                if (fontConfiguration != nil
                    && [fontConfiguration isKindOfClass:[NSDictionary class]]) {
                    id fontClassName = [fontConfiguration objectForKey:kConfigurationIOS];
                    if (fontClassName != nil
                        && [fontClassName isKindOfClass:[NSString class]]) {
                        Class fontClass = NSClassFromString(fontClassName);
                        if (fontClass != nil
                            && [fontClass conformsToProtocol:@protocol(CobaltFont)]) {
                            if (color == nil) {
                                color = [UIColor blueColor];
                            }
                            
                            image = [fontClass imageWithIcon:icon
                                                       color:color
                                                     andSize:size];
                        }
                    }
                }
            }
        }
    }
    
    return image;
}

+ (NSDictionary *)fontsConfiguration {
    if (sFontsConfiguration != nil) {
        return sFontsConfiguration;
    }
    
    NSDictionary *cobaltConfiguration = [Cobalt cobaltConfiguration];
    if (cobaltConfiguration == nil) {
        return nil;
    }
    
    id fontsConfiguration = [cobaltConfiguration objectForKey:kConfigurationFonts];
    if (fontsConfiguration == nil
        || ! [fontsConfiguration isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    sFontsConfiguration = fontsConfiguration;
    return sFontsConfiguration;
}

@end
