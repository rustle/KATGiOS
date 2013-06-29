//
//  TDRoundedShadowView.h
//
//  Created by Timothy Donnelly on 12/8/12.
//  Copyright (c) 2012 Timothy Donnelly. All rights reserved.
//
// This source code is licenced under The MIT License:
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

typedef enum {
	TDRoundedShadowSideTop,
	TDRoundedShadowSideRight,
	TDRoundedShadowSideBottom,
	TDRoundedShadowSideLeft
} TDRoundedShadowSide;

@interface TDRoundedShadowView : UIView

// The side the shadow originates from
@property (nonatomic) TDRoundedShadowSide shadowSide;

// Defaults to black, opacity 0.1
@property (strong, nonatomic) UIColor *shadowColor;

// Defaults to 0. Draws a line along the side the shadow is originating from
@property (nonatomic) CGFloat lineWidth;

// Defaults to white
@property (strong, nonatomic) UIColor *lineColor;


@end
