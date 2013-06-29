
//
//  KATGAlertPanel.m
//  KATG
//
//  Created by Doug Russell on 4/28/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGAlertPanel.h"
#import "UIColor+KATGColors.h"

#define Duration 5.0f

@interface KATGAlertPanel ()
@property (nonatomic) bool animatingIn;
@property (nonatomic) bool animatingOut;
@property (copy, nonatomic) void (^completionBlock)(void);
@end

@implementation KATGAlertPanel

+ (instancetype)panelWithText:(NSString *)text
{
	KATGAlertPanel *panel = [KATGAlertPanel new];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.backgroundColor = [UIColor katg_whitishColor];
	if ([text length])
	{
		label.text = text;
		label.textAlignment = NSTextAlignmentCenter;
		label.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
		label.textColor = [UIColor katg_titleTextColor];
	}
	[panel addSubview:label];
	panel.layoutBlock = ^(KATGAlertPanel *panel) {
		label.frame = panel.bounds;
	};
	panel.accessibilityLabel = text;
	return panel;
}

- (void)showFromView:(UIView *)view completionBlock:(void (^)(void))completionBlock
{
	if (self.animatingIn || self.animatingOut)
	{
		return;
	}
	self.isAccessibilityElement = NO;
	self.accessibilityElementsHidden = YES;
	if (self.accessibilityLabel)
	{
		UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.accessibilityLabel);
	}
	self.completionBlock = completionBlock;
	CGRect viewFrame = view.frame;
	CGRect rect = CGRectMake(0.0f, viewFrame.size.height-44.0f, viewFrame.size.width, 44.0f);
	self.frame = rect;
	[view.superview insertSubview:self belowSubview:view];
	rect.origin.y = viewFrame.size.height;
	void (^animation)(void) = ^{
		self.frame = rect;
	};
	void (^completion)(BOOL) = ^(BOOL finished){
		if (finished)
		{
			[self performSelector:@selector(hide) withObject:nil afterDelay:Duration];
		}
	};
	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0f options:0 animations:animation completion:completion];
}

- (void)hideWithCompletionBlock:(void (^)(void))completionBlock
{
	self.completionBlock = completionBlock;
	[self hide];
}

- (void)hide
{
	if (self.animatingOut)
	{
		return;
	}
	CGRect rect = self.frame;
	rect.origin.y = -rect.size.height;
	void (^animation)(void) = ^{
		self.frame = rect;
	};
	void (^completion)(BOOL) = ^(BOOL finished){
		if (self.completionBlock)
		{
			self.completionBlock();
		}
	};
	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0f options:0 animations:animation completion:completion];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (self.layoutBlock)
	{
		self.layoutBlock(self);
	}
}

@end
