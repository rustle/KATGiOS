//
//  KATGTabBarButtonItem.m
//  KATG
//
//  Created by Timothy Donnelly on 11/5/12.
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

#import "KATGTabBarButtonItem.h"
#import "KATGTabBarButtonItem_InternalButton.h"
#import "KATGTabBar.h"
#import "KATGTabBarBackgroundView.h"

@interface KATGTabBarButtonItem ()

@property (nonatomic) UIView *drawerContainerView;
@property (nonatomic) KATGTabBarBackgroundView *drawerButtonBackgroundView;
@property (nonatomic) KATGTabBarButtonItem_InternalButton *button;

- (void)buttonTapped:(id)sender;

@end

@implementation KATGTabBarButtonItem

- (instancetype)initWithImage:(UIImage *)image target:(id)target action:(SEL)action
{
	self = [super init];
	if (self)
	{
		_image = image;
		_target = target;
		_action = action;
		
		self.view.clipsToBounds = NO;
		
		_drawerContainerView = [[UIView alloc] init];
		
		_drawerButtonBackgroundView = [[KATGTabBarBackgroundView alloc] init];
		_drawerButtonBackgroundView.topGradientColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
		_drawerButtonBackgroundView.bottomGradientColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
		_drawerButtonBackgroundView.layer.shadowColor = [[UIColor blackColor] CGColor];
		_drawerButtonBackgroundView.layer.shadowOpacity = 1.0f;
		_drawerButtonBackgroundView.layer.shadowRadius = 4.0f;
		_drawerButtonBackgroundView.hidden = YES;
		[self.view addSubview:_drawerButtonBackgroundView];
		
		_button = [[KATGTabBarButtonItem_InternalButton alloc] init];
		_button.isAccessibilityElement = YES;
		_button.image = image;
		_button.backgroundColor = [UIColor clearColor];
		[_button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_button];
	}
	return self;
}

- (void)performLayout
{
	[super performLayout];
	
	self.button.frame = self.view.bounds;
	
	// Make the button display properly on the light background of the drawer button background
	self.button.interfaceLuminosity = self.actsAsDrawer ? KATGTabBarInterfaceLuminosityLight : KATGTabBarInterfaceLuminosityDark;
	
	self.drawerButtonBackgroundView.frame = self.view.bounds;
	self.drawerButtonBackgroundView.hidden = !self.actsAsDrawer;
	
	if (self.actsAsDrawer)
	{
		self.drawerButtonBackgroundView.cornerRadius = 4.0f;
		if (self.tabBar.leftButtonItem == self)
		{
			self.drawerButtonBackgroundView.corners = UIRectCornerTopRight | UIRectCornerBottomRight;
		}
		else if (self.tabBar.rightButtonItem == self)
		{
			self.drawerButtonBackgroundView.corners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
		}
		[self.drawerButtonBackgroundView setNeedsDisplay];
		
		[self.drawerContainerView bringSubviewToFront:self.drawerBackgroundView];
		[self.drawerContainerView bringSubviewToFront:self.drawerContentView];
		self.drawerContainerView.frame = CGRectZero;
		self.drawerContentView.frame = CGRectZero;
	}
}

- (void)setActsAsDrawer:(BOOL)actsAsDrawer
{
	_actsAsDrawer = actsAsDrawer;
	[self.tabBar tabBarItemDidUpdate:self];
	[self performLayout];
}

- (CGFloat)width
{
	return 48.0f;
}

- (void)setImage:(UIImage *)image
{
	_image = image;
	self.button.image = self.image;
}

- (void)buttonTapped:(id)sender
{  
	if (self.actsAsDrawer)
	{
		[self setDrawerIsExpanded:!self.drawerIsExpanded animated:YES];
		return;
	}
	
	NSMethodSignature *methodSignature = [self.target methodSignatureForSelector:self.action];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	[invocation setTarget:self.target];
	[invocation setSelector:self.action];
	[invocation setArgument:(__bridge void *)self atIndex:2];
	[invocation invoke];
}

- (void)setDrawerIsExpanded:(BOOL)drawerIsExpanded
{
	[self setDrawerIsExpanded:drawerIsExpanded animated:NO];
}

- (void)setDrawerIsExpanded:(BOOL)drawerIsExpanded animated:(BOOL)animated
{
	if (drawerIsExpanded == _drawerIsExpanded)
	{
		return;
	}
	_drawerIsExpanded = drawerIsExpanded;
	
	self.button.image = drawerIsExpanded ? [UIImage imageNamed:@"x.png"] : self.image;
	
	[self.tabBar tabBarButtonItem:self setDrawerExpanded:_drawerIsExpanded animated:animated];
}

- (void)setDrawerBackgroundView:(UIView *)drawerBackgroundView
{
	[_drawerBackgroundView removeFromSuperview];
	_drawerBackgroundView = drawerBackgroundView;
	[self.drawerContainerView addSubview:_drawerBackgroundView];
}

- (void)setDrawerContentView:(UIView *)drawerContentView
{
	[_drawerContentView removeFromSuperview];
	_drawerContentView = drawerContentView;
	[self.drawerContainerView addSubview:_drawerContentView];
}

- (UIView *)drawerView
{
	return _drawerContainerView;
}

- (NSString *)accessibilityLabel
{
	return self.button.accessibilityLabel;
}

- (void)setAccessibilityLabel:(NSString *)accessibilityLabel
{
	[self.button setAccessibilityLabel:accessibilityLabel];
}

@end
