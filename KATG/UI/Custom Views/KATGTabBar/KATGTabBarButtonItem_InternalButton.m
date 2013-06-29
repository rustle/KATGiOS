//
//  KATGTabBarButtonItem_InternalButton.m
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

#import "KATGTabBarButtonItem_InternalButton.h"
#import "KATGTabBarStyledImageView.h"

@interface KATGTabBarButtonItem_InternalButton ()

@property (nonatomic) KATGTabBarStyledImageView *styledImageView;

- (void)updateButtonState;

@end

@implementation KATGTabBarButtonItem_InternalButton

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_styledImageView = [KATGTabBarStyledImageView new];
		_styledImageView.userInteractionEnabled = NO;
		[self addSubview:_styledImageView];
		[self updateButtonState];
	}
	return self;
}

- (void)layoutSubviews
{
	[self.styledImageView sizeToFit];
	self.styledImageView.center = self.center;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event 
{
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event 
{
	return YES;
}

- (void)setImage:(UIImage *)image
{
	_image = image;
	self.styledImageView.image = image;
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

- (void)updateButtonState
{
	switch (self.state) {
		case UIControlStateNormal:
		{
			if (self.interfaceLuminosity == KATGTabBarInterfaceLuminosityDark)
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			else
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor whiteColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			break;
		}
		case UIControlStateHighlighted:
		{
			if (self.interfaceLuminosity == KATGTabBarInterfaceLuminosityDark)
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.6f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.3f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			else
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.1f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:1.0f] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
				self.styledImageView.layer.shadowOpacity = 1.0f;
				self.styledImageView.layer.shadowRadius = 8.0f;
			}
			break;
		}
		case UIControlStateSelected:
		{
			if (self.interfaceLuminosity == KATGTabBarInterfaceLuminosityDark)
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.6f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.3f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			else
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.1f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor whiteColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			break;
		}
		case UIControlStateDisabled:
		{
			if (self.interfaceLuminosity == KATGTabBarInterfaceLuminosityDark)
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			else
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.6f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.3f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor whiteColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			break;
		}
		default:
		{
			if (self.interfaceLuminosity == KATGTabBarInterfaceLuminosityDark)
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			else
			{
				self.styledImageView.topGradientColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
				self.styledImageView.bottomGradientColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
				self.styledImageView.layer.shadowColor = [[UIColor whiteColor] CGColor];
				self.styledImageView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
				self.styledImageView.layer.shadowOpacity = 0.2f;
				self.styledImageView.layer.shadowRadius = 0.0f;
			}
			break;
		}
	}
	[self.styledImageView setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self updateButtonState];
}

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	[self updateButtonState];
}

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	[self updateButtonState];
}

- (void)setInterfaceLuminosity:(KATGTabBarInterfaceLuminosity)interfaceLuminosity
{
	_interfaceLuminosity = interfaceLuminosity;
	[self updateButtonState];
}

@end
