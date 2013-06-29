//
//  KATGButton.m
//  KATG
//
//  Created by Tim Donnelly on 4/10/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
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

#import "KATGButton.h"

#define CORNER_RADIUS 4.0f
#define BOTTOM_PATH_WEIGHT 1.0f

@interface KATGButton ()
@property (strong, nonatomic) UIColor *backgroundColor;
@property (strong, nonatomic) UIColor *selectedBackgroundColor;
@end

@implementation KATGButton

- (id)init
{
	return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[self setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.1f] forState:UIControlStateNormal];
		self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
		self.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
		
		[self setButtonStyle:KATGButtonStylePrimary];
	}
	return self;
}

- (void)setDecorationView:(UIView *)decorationView
{
	_decorationView = decorationView;
	[self addSubview:_decorationView];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect decorationViewFrame = self.decorationView.bounds;
	decorationViewFrame.origin.y = (self.bounds.size.height - decorationViewFrame.size.height) / 2;
	decorationViewFrame.origin.x = decorationViewFrame.origin.y;
	self.decorationView.frame = decorationViewFrame;
}

CG_INLINE CGFloat DegreesToRadians(CGFloat degrees)
{
	return degrees * M_PI / 180.0f;
}

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context=UIGraphicsGetCurrentContext();
	
	rect.origin.x += self.contentEdgeInsets.left;
	rect.origin.y += self.contentEdgeInsets.top;
	rect.size.width -= (self.contentEdgeInsets.left + self.contentEdgeInsets.right);
	rect.size.height -= (self.contentEdgeInsets.top + self.contentEdgeInsets.bottom);
	
	UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:CORNER_RADIUS];
	[roundedRect addClip];
	
	if (self.isSelected)
	{
		NSLog(@"drawing selected!");
	}
	
	[(self.isHighlighted ? self.selectedBackgroundColor : self.backgroundColor) setFill];
	[[UIBezierPath bezierPathWithRect:rect] fill];
	
	[self drawRoundedBorderForRect:rect edge:CGRectMaxYEdge radius:CORNER_RADIUS weight:BOTTOM_PATH_WEIGHT color:[UIColor colorWithWhite:0.0f alpha:0.2f] context:context];
}

- (void)drawRoundedBorderForRect:(CGRect)rect edge:(CGRectEdge)edge radius:(CGFloat)radius weight:(CGFloat)weight color:(UIColor *)color context:(CGContextRef)context
{
	CGContextSaveGState(context);
	

	
	UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:CORNER_RADIUS];
	[roundedRect addClip];
	
	// Setup the context. Our drawing code always acts as if it is drawing a bottom edge, so we rotate to match.
	

	CGRect realRect = rect;

	if (edge == CGRectMinXEdge || edge == CGRectMaxXEdge)
	{
		realRect.size.width = rect.size.height;
		realRect.size.height = rect.size.width;
	}
	
	[color setStroke];
	
	switch (edge)
	{
		case CGRectMinXEdge:
		{
			CGContextTranslateCTM(context, rect.size.width, 0.0f);
			CGContextRotateCTM(context, DegreesToRadians(90.0f));
			break;
		}
		case CGRectMaxXEdge:
		{
			CGContextTranslateCTM(context, 0.0f, rect.size.height);
			CGContextRotateCTM(context, DegreesToRadians(270.0f));
			break;
		}
		case CGRectMinYEdge:
		{
			CGContextTranslateCTM(context, rect.size.width, rect.size.height);
			CGContextRotateCTM(context, DegreesToRadians(180.0f));
			break;
		}
		case CGRectMaxYEdge:
		{
			break;
		}
	}
	
	CGMutablePathRef path = CGPathCreateMutable();	
	CGPathMoveToPoint(path, NULL, CGRectGetMinX(realRect) - weight/2, CGRectGetMaxY(realRect) - weight/2 - radius);
	CGPathAddArc(path,
				 NULL,
				 CGRectGetMinX(realRect) - weight/2 + radius,
				 CGRectGetMaxY(realRect) - weight/2 - radius,
				 CORNER_RADIUS,
				 DegreesToRadians(180.0f),
				 DegreesToRadians(90.0f),
				 YES);
	CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(realRect) + radius/2 - radius, CGRectGetMaxY(realRect) - weight/2);
	CGPathAddArc(path,
				 NULL,
				 CGRectGetMaxX(realRect) + weight/2 - radius,
				 CGRectGetMaxY(realRect) - weight/2 - radius,
				 CORNER_RADIUS,
				 DegreesToRadians(90.0f),
				 DegreesToRadians(0.0f),
				 YES);
	
	CGContextAddPath(context, path);
	CGContextSetLineWidth(context, weight);
	CGContextStrokePath(context);
	CGPathRelease(path);
	
	CGContextRestoreGState(context);
}

- (void)setButtonStyle:(KATGButtonStyle)buttonStyle
{
	switch (buttonStyle)
	{
		case KATGButtonStylePrimary:
		{
			_backgroundColor = [UIColor colorWithRed:0.404 green:0.678 blue:0.333 alpha:1];
			_selectedBackgroundColor = [UIColor colorWithRed:0.384 green:0.639 blue:0.314 alpha:1];
			break;
		}
		case KATGButtonStyleSecondary:
		{
			_backgroundColor = [UIColor colorWithWhite:0.70 alpha:1];
			_selectedBackgroundColor = [UIColor colorWithWhite:0.65 alpha:1];
			break;
		}
	}
}


@end
