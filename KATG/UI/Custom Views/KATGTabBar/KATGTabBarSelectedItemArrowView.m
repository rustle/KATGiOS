//
//  KATGTabBarSelectedItemArrowView.m
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

#import "KATGTabBarSelectedItemArrowView.h"

@implementation KATGTabBarSelectedItemArrowView

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		_arrowColor = [UIColor colorWithWhite:0.33f alpha:1.0f];
		self.layer.shouldRasterize = YES;
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	[self.arrowColor set];
	
	UIBezierPath *triangle = [UIBezierPath bezierPath];
	[triangle moveToPoint:CGPointMake(0.0f, CGRectGetMaxY(rect))];
	[triangle addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
	[triangle addLineToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect))];
	[triangle addLineToPoint:CGPointMake(0.0f, CGRectGetMaxY(rect))];
	[triangle fill];
}

@end
