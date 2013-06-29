//
//  UIColor+KATGColors.m
//  KATG
//
//  Created by Doug Russell on 6/18/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "UIColor+KATGColors.h"

@implementation UIColor (KATGColors)

#define ColorStatic(colorDefinition) \
static id color = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
	color = colorDefinition; \
}); \
return color;

+ (UIColor *)katg_whitishColor
{
	ColorStatic([UIColor colorWithWhite:245.0f/255.0f alpha:1.0f])
}

+ (UIColor *)katg_titleTextColor
{
	ColorStatic([UIColor colorWithWhite:0.25f alpha:1.0f])
}

@end
