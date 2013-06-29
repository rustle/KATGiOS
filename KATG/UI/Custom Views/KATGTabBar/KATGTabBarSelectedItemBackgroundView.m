//
//  KATGTabBarSelectedItemBackgroundView.m
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

#import "KATGTabBarSelectedItemBackgroundView.h"
#import "KATGTabBarSelectedItemArrowView.h"

@interface KATGTabBarSelectedItemBackgroundView ()
@property (nonatomic, strong) KATGTabBarSelectedItemArrowView *arrowView;
@end

@implementation KATGTabBarSelectedItemBackgroundView

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		self.layer.shouldRasterize = YES;
		_arrowSize = CGSizeMake(20.0f, 5.0f);
		_topMargin = 5.0f;
		_bottomMargin = 5.0f;
		_cornerRadius = 4.0f;
		
		_arrowView = [KATGTabBarSelectedItemArrowView new];
		[self addSubview:_arrowView];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	CGRect arrowRect = CGRectZero;
	arrowRect.size = self.arrowSize;
	arrowRect.origin.y -= self.arrowSize.height;
	arrowRect.origin.x = (self.frame.size.width - self.arrowSize.width) / 2;
	self.arrowView.frame = arrowRect;
}

- (void)drawRect:(CGRect)rect
{  
	CGFloat minY = self.topMargin;
	CGFloat maxY = rect.size.height - self.bottomMargin;
	CGFloat minX = 0.0f;
	CGFloat maxX = self.frame.size.width;
	
	CGFloat arrowMinY = minY - self.arrowSize.height;
	CGFloat arrowMinX = (self.frame.size.width - self.arrowSize.width) / 2;
	CGFloat arrowMidX = arrowMinX + (self.arrowSize.width / 2);
	CGFloat arrowMaxX = arrowMinX + self.arrowSize.width;
	
	[[UIColor redColor] set];
	
	UIBezierPath *bezier = [UIBezierPath bezierPath];
	
	// top left
	[bezier moveToPoint:CGPointMake(minX, minY + self.cornerRadius)];
	
	// bottom left
	[bezier addLineToPoint:CGPointMake(minX, maxY - self.cornerRadius)];
	[bezier addArcWithCenter:CGPointMake(minX + self.cornerRadius, maxY - self.cornerRadius) radius:self.cornerRadius startAngle:(180*M_PI/180) endAngle:(90*M_PI/180) clockwise:NO];
	
	
	// bottom right
	[bezier addLineToPoint:CGPointMake(maxX - self.cornerRadius, maxY)];
	[bezier addArcWithCenter:CGPointMake(maxX - self.cornerRadius, maxY - self.cornerRadius) radius:self.cornerRadius startAngle:(90*M_PI/180) endAngle:(0*M_PI/180) clockwise:NO];
	
	// top right
	[bezier addLineToPoint:CGPointMake(maxX, minY + self.cornerRadius)];
	[bezier addArcWithCenter:CGPointMake(maxX - self.cornerRadius, minY + self.cornerRadius) radius:self.cornerRadius startAngle:(0*M_PI/180) endAngle:(270*M_PI/180) clockwise:NO];
	
	// arrow
	[bezier addLineToPoint:CGPointMake(arrowMaxX, minY)];
	[bezier addLineToPoint:CGPointMake(arrowMidX, arrowMinY)];
	[bezier addLineToPoint:CGPointMake(arrowMinX, minY)];
	
	// top left
	[bezier addLineToPoint:CGPointMake(minX + self.cornerRadius, minY)];
	[bezier addArcWithCenter:CGPointMake(minX + self.cornerRadius, minY + self.cornerRadius) radius:self.cornerRadius startAngle:(270*M_PI/180) endAngle:(180*M_PI/180) clockwise:NO];
	
	// ************************
	// Draw the shadow
	// ************************
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGMutablePathRef visiblePath = CGPathCreateMutableCopy([bezier CGPath]);
	
	// Fill this path
	
	[[UIColor colorWithWhite:0.18f alpha:1.0f] set];
	CGContextAddPath(context, visiblePath);
	CGContextFillPath(context);
	
	// Create a larger rectangle to encompass our path
	CGMutablePathRef largerPath = CGPathCreateMutable();
	// // make it larger than the bounds of our path
	CGPathAddRect(largerPath, NULL, CGRectInset(CGPathGetPathBoundingBox(visiblePath), -60, -60));
	
	// subtract the actual path from the larger one
	CGPathAddPath(largerPath, NULL, visiblePath);
	CGPathCloseSubpath(largerPath);
	
	// And clip to the actual path
	CGContextAddPath(context, visiblePath);
	CGContextClip(context);
	
	// Create the shadow
	UIColor *shadowColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
	CGContextSaveGState(context);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 8.0f, [shadowColor CGColor]);
	
	// Now fill the rectangle, so the shadow gets drawn
	[shadowColor set];
	CGContextSaveGState(context);
	CGContextAddPath(context, largerPath);
	CGContextEOFillPath(context);
	
	// Release the paths
	CGPathRelease(largerPath);    
	CGPathRelease(visiblePath);
}

@end
