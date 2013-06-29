//
//  KATGInsetView.m
//  KATG
//
//  Created by Timothy Donnelly on 4/30/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGInsetView.h"

@implementation KATGInsetView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
			self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	

	CGFloat lineHeight = 1.0f / [[UIScreen mainScreen] scale];
	
	if (lineHeight == 1.0f)
	{
		CGRect topLineRect = CGRectMake(0.0f, 0.0f, self.bounds.size.width, lineHeight);
		[[UIColor colorWithWhite:0.0f alpha:0.2f] setFill];
		CGContextFillRect(context, topLineRect);
		
		CGRect bottomLineRect = CGRectMake(0.0f, lineHeight, self.bounds.size.width, lineHeight);
		[[UIColor whiteColor] setFill];
		CGContextFillRect(context, bottomLineRect);
	}
	else
	{
		CGRect lineRect = CGRectMake(0.0f, 0.0f, self.bounds.size.width, lineHeight);
		[[UIColor colorWithWhite:0.0f alpha:0.05f] setFill];
		CGContextFillRect(context, lineRect);
		
		lineRect.origin.y += lineHeight;
		[[UIColor colorWithWhite:0.0f alpha:0.2f] setFill];
		CGContextFillRect(context, lineRect);
		
		lineRect.origin.y += lineHeight;
		[[UIColor colorWithWhite:1.0f alpha:1.0f] setFill];
		CGContextFillRect(context, lineRect);
		
		lineRect.origin.y += lineHeight;
		[[UIColor colorWithWhite:1.0f alpha:0.2f] setFill];
		CGContextFillRect(context, lineRect);
	}
		
}

@end
