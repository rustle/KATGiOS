//
//  KATGTabBarStyledImageView.m
//  KATG
//
//  Created by Timothy Donnelly on 11/6/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

#import "KATGTabBarStyledImageView.h"

@implementation KATGTabBarStyledImageView

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		self.layer.shouldRasterize = YES;
		_topGradientColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
		_bottomGradientColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
		
		_shadowColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
		_shadowOffset = CGSizeMake(0.0f, -1.0f);
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	float hfactor = self.image.size.width / rect.size.width;
	float vfactor = self.image.size.height / rect.size.height;
	float factor = fmax(hfactor, vfactor);
	float newWidth = self.image.size.width / factor;
	float newHeight = self.image.size.height / factor;
	float leftOffset = (rect.size.width - newWidth) / 2;
	float topOffset = (rect.size.height - newHeight) / 2;
	CGRect newRect = CGRectMake(leftOffset, topOffset, newWidth, newHeight);
	
	// shadow
	CGContextSaveGState(context);
	CGRect shadowRect = newRect;
	shadowRect.origin.x -= self.shadowOffset.width;
	shadowRect.origin.y -= self.shadowOffset.height;
	CGContextClipToMask(context, shadowRect, self.image.CGImage); // respect alpha mask
	[self.shadowColor setFill];
	[[UIBezierPath bezierPathWithRect:shadowRect] fill];
	CGContextRestoreGState(context);
	
	// gradient
	CGContextClipToMask(context, newRect, self.image.CGImage); // respect alpha mask
	CGFloat locations[2] = { 0.0, 1.0 };
	NSArray *colors = @[(id)[self.bottomGradientColor CGColor], (id)[self.topGradientColor CGColor]];
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef)colors, locations);
	
	CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
	
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorspace);
	
}

- (CGSize)sizeThatFits:(CGSize)size
{
	return self.image ? self.image.size : CGSizeZero;
}

- (void)setTopGradientColor:(UIColor *)topGradientColor
{
	_topGradientColor = topGradientColor;
	[self setNeedsDisplay];
}

- (void)setBottomGradientColor:(UIColor *)bottomGradientColor
{
	_bottomGradientColor = bottomGradientColor;
	[self setNeedsDisplay];
}

@end
