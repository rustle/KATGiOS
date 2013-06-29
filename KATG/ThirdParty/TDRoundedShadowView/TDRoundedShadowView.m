//
//  TDRoundedShadowView.m
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

#import "TDRoundedShadowView.h"

@implementation TDRoundedShadowView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = NO;
		self.layer.shouldRasterize = YES;
		_shadowColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGRect shadowRect = rect;
	CGSize shadowOffset = CGSizeZero;
	CGFloat shadowBlurRadius = 0.0f;
	
	switch (self.shadowSide)
	{
		case TDRoundedShadowSideTop:
		{
			shadowRect.origin.y -= shadowRect.size.height;
			shadowOffset = CGSizeMake(0.0f, (shadowRect.size.height/2));
			shadowBlurRadius = (shadowRect.size.height/2);
			break;
		}
		case TDRoundedShadowSideRight:
		{
			shadowRect.origin.x += shadowRect.size.width;
			shadowOffset = CGSizeMake(-(shadowRect.size.width/2), 0.0f);
			shadowBlurRadius = (shadowRect.size.width/2);
			break;
		}
		case TDRoundedShadowSideBottom:
		{
			shadowRect.origin.y += shadowRect.size.height;
			shadowOffset = CGSizeMake(0.0f, -(shadowRect.size.height/2));
			shadowBlurRadius = (shadowRect.size.height/2);
			break;
		}
		case TDRoundedShadowSideLeft:
		{
			shadowRect.origin.x -= shadowRect.size.width;
			shadowOffset = CGSizeMake((shadowRect.size.width/2), 0.0f);
			shadowBlurRadius = (shadowRect.size.width/2);
			break;
		}
	}
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:shadowRect
																						 byRoundingCorners:UIRectCornerAllCorners
																									 cornerRadii:CGSizeMake(rect.size.width/2, rect.size.height/2)];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, [self.shadowColor CGColor]);
	[path fill];
	
	if (!self.lineWidth)
		return;
	
	CGRect lineRect = rect;
	switch (self.shadowSide)
	{
		case TDRoundedShadowSideTop:
		{
			lineRect.size.height = self.lineWidth;
			break;
		}
		case TDRoundedShadowSideRight:
		{
			lineRect.origin.x = lineRect.size.width - self.lineWidth;
			lineRect.size.width = self.lineWidth;
			break;
		}
		case TDRoundedShadowSideBottom:
		{
			lineRect.origin.y = lineRect.size.height - self.lineWidth;
			lineRect.size.height = self.lineWidth;
			break;
		}
		case TDRoundedShadowSideLeft:
		{
			lineRect.size.width = self.lineWidth;
			break;
		}
	}
	CGContextSetShadow(context, CGSizeZero, 0.0f);
	UIBezierPath *linePath = [UIBezierPath bezierPathWithRect:lineRect];
	[self.lineColor set];
	[linePath fill];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
	// Wait to create the line color until lineWidth > 0
	if (lineWidth > 0 && !self.lineColor)
	{
		self.lineColor = [UIColor whiteColor];
	}
	_lineWidth = lineWidth;
	[self setNeedsDisplay];
}

@end
