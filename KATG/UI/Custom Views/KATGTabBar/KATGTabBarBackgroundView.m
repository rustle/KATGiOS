//
//  KATGBackgroundView.m
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

#import "KATGTabBarBackgroundView.h"

@implementation KATGTabBarBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		self.layer.shouldRasterize = YES;
		_topGradientColor = [UIColor colorWithWhite:0.33f alpha:1.0f];
		_bottomGradientColor = [UIColor colorWithWhite:0.22f alpha:1.0f];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:self.corners cornerRadii:CGSizeMake(self.cornerRadius, self.cornerRadius)];
	[maskPath addClip];
	
	CGFloat locations[2] = { 0.0, 1.0 };
	NSArray *colors = @[(id)[self.topGradientColor CGColor], (id)[self.bottomGradientColor CGColor]];
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef)colors, locations);
	
	CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
	
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorspace);
}

@end
