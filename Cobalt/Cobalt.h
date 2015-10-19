/**
 *
 * Cobalt.h
 * Cobalt
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Cobaltians
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

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark FRAMEWORK STUFF

////////////////////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>

//! Project version number for Cobalt.
FOUNDATION_EXPORT double CobaltVersionNumber;

//! Project version string for Cobalt.
FOUNDATION_EXPORT const unsigned char CobaltVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Cobalt/PublicHeader.h>

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -

////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark ORIGINAL COBALT

////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#import "CobaltViewController.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define viewControllerDeallocatedNotification   @"viewControllerDeallocatedNotification"

#define cobaltSpecialJSKey      @"cob@l7#k&y"

// CONFIGURATION FILE
#define kIos                    @"ios"
#define kIosNibName             @"iosNibName"
#define kInfiniteScrollOffset   @"infiniteScrollOffset"
// TODO: uncomment for Bars
/*
#define kBars                   @"bars"
#define kBarVisible             @"visible"
#define kBarBackgroundColor     @"backgroundColor"
#define kBarTitle               @"title"
#define kBarActions             @"actions"
#define kBarActionIcon          @"iosIcon"
#define kBarActionName          @"name"
#define kBarActionTitle         @"title"
#define kBarActionVisible       @"visible"
#define kBarActionPosition      @"iosPosition"
*/

@interface Cobalt : NSObject

/*!
 @method    + (NSString *)resourcePath
 @abstract  Returns the Cobalt resource path for the whole application (default: /www/),
            or nil if app bundle could not be created.
 */
+ (NSString *)resourcePath;

/*!
 @method    + (void)setResourcePath:(NSString *)resourcePath
 @param     resourcePath
 @abstract  Sets the Cobalt resource path for the whole application
 */
+ (void)setResourcePath:(NSString *)resourcePath;

/*!
 @method		+ (CobaltViewController *)cobaltViewControllerForController:(NSString *)controller andPage:(NSString *)page
 @abstract		Returns an allocated and initialized Cobalt view controller from its id in cobalt configuration file and HTML page.
 @param         controller: view controller id
 @param         page: HTML page
 */
+ (CobaltViewController *)cobaltViewControllerForController:(NSString *)controller
                                                    andPage:(NSString *)page;
/*!
 @method		+ (UIViewController *)nativeViewControllerForController:(NSString *)controller
 @abstract		Returns an allocated and initialized native view controller from its id in cobalt configuration file.
 @param         controller: view controller id
 */
+ (UIViewController *)nativeViewControllerForController:(NSString *)controller;

/*!
 @method    + (NSDictionary *)defaultConfiguration
 @abstract  Returns the default controller configuration contained in the cobalt.conf file if any
            nil otherwise
 */
+ (NSDictionary *)defaultConfiguration;

/*!
 @method    + (NSDictionary *)configurationForController:(NSString *)controller
 @param     controller the controller to find the configuration
 @abstract  Returns the configuration for the specified controller contained in the cobalt.conf file if any
            nil otherwise
 */
+ (NSDictionary *)configurationForController:(NSString *)controller;

/*!
 @method    + (NSDictionary *)cobaltConfiguration
 @abstract  Returns the Cobalt configuration read from cobalt.conf file in resource path.
            May be nil vor various reasons.
 */
+ (NSDictionary *)cobaltConfiguration;

/*!
 @method    + (NSDictionary *)dictionaryWithString:(NSString *)string
 @param     string a JSON as an UTF-8 encoded string
 @abstract  Parses the JSON sent as an UTF-8 encoded string and returns a NSDictionary.
            May be nil if an error occured.
 */
+ (NSDictionary *)dictionaryWithString:(NSString *)string;

/*!
 @method    + (UIColor *)colorFromHexString:(NSString *)hexString
 @param     hexString a color as an hexadecimal RGB string. Valid formats are: (#)RGB and (#)RRGGBB(AA).
 @abstract  Returns an UIColor from a color as an hexadecimal string.
            May be nil if the input format is not valid.
 */
+ (UIColor *)colorFromHexString:(NSString *)hexString;

@end
