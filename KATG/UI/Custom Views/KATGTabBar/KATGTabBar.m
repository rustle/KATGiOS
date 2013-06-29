//
//  KATGTabBar.m
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

#import "KATGTabBar.h"
#import "KATGTabBarItem.h"
#import "KATGTabBarButtonItem.h"
#import "KATGTabBarTabItem.h"
#import "KATGTabBarBackgroundView.h"
#import "KATGTabBarSelectedItemBackgroundView.h"

@interface KATGTabBar () <KATGTabBarItemDelegate, KATGTabBarTabItemDelegate, KATGTabBarButtonItemDelegate>

@property (nonatomic) UIView *itemContainerView;
@property (nonatomic) UIView *drawerContainerView;

@property (nonatomic) BOOL leftButtonItemIsExpanded;
@property (nonatomic) BOOL rightButtonItemIsExpanded;

@property (nonatomic) KATGTabBarTabItem *selectedItem;
@property (nonatomic) KATGTabBarSelectedItemBackgroundView *selectedItemBackgroundView;

@property (nonatomic) KATGTabBarBackgroundView *backgroundView;

- (void)layoutItems;
- (void)layoutDrawer;
- (void)layoutCurrentSelection;

@end

@implementation KATGTabBar

- (void)katgtabbar_commonInit
{
	_tabItemBottomMargin = _tabItemTopMargin = 4.0f;

	_backgroundView = [[KATGTabBarBackgroundView alloc] init];
	[self addSubview:_backgroundView];

	_selectedItemBackgroundView = [[KATGTabBarSelectedItemBackgroundView alloc] init];
	[self addSubview:_selectedItemBackgroundView];

	_itemContainerView = [[UIView alloc] init];
	_itemContainerView.backgroundColor = [UIColor clearColor];
	_itemContainerView.clipsToBounds = YES;
	[self addSubview:_itemContainerView];
	_tabItemSpacing = 0.0f;

	_drawerContainerView = [[UIView alloc] init];
	_drawerContainerView.backgroundColor = [UIColor clearColor];
	_drawerContainerView.hidden = YES;
	[_itemContainerView addSubview:_drawerContainerView];

	self.layer.shadowColor = [[UIColor blackColor] CGColor];
	self.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
	self.layer.shadowOpacity = 0.3f;
	self.layer.shadowRadius = 1.0f;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self katgtabbar_commonInit];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		[self katgtabbar_commonInit];
	}
	return self;
}

- (void)setTabItems:(NSArray *)tabItems
{
	for (KATGTabBarItem *item in _tabItems)
	{
		[item.view removeFromSuperview];
		item.tabBar = nil;
	}
	
	_tabItems = tabItems;
	
	for (KATGTabBarItem *item in tabItems)
	{
		[self.itemContainerView addSubview:item.view];
		item.tabBar = self;
	}
	
	[self selectTabItemAtIndex:0];
	[self setNeedsLayout];
}

- (void)setLeftButtonItem:(KATGTabBarButtonItem *)leftButtonItem
{
	[_leftButtonItem.view removeFromSuperview];
	_leftButtonItem.tabBar = nil;
	
	_leftButtonItem = leftButtonItem;
	
	_leftButtonItem.tabBar = self;
	[self.itemContainerView addSubview:_leftButtonItem.view];
	[self setNeedsLayout];
}

- (void)setRightButtonItem:(KATGTabBarButtonItem *)rightButtonItem
{
	[_rightButtonItem.view removeFromSuperview];
	_rightButtonItem.tabBar = nil;
	
	_rightButtonItem = rightButtonItem;
	
	_rightButtonItem.tabBar = self;
	[self.itemContainerView addSubview:_rightButtonItem.view];
	[self setNeedsLayout];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	self.backgroundView.frame = self.bounds;
	self.itemContainerView.frame = self.bounds;
	self.drawerContainerView.frame = self.bounds;
	
	[self layoutItems];
	[self layoutDrawer];
	[self layoutCurrentSelection];
}

- (void)layoutItems
{
	CGFloat availableWidth = self.bounds.size.width;
	CGFloat totalItemWidth = (self.tabItems.count-1) * self.tabItemSpacing; // acount for the gap between items
	
	if (self.leftButtonItem)
	{
		availableWidth -= self.leftButtonItem.width;
	}
	
	if (self.rightButtonItem)
	{
		availableWidth -= self.rightButtonItem.width;
	}
	
	for (KATGTabBarItem *item in self.tabItems)
	{
		totalItemWidth += item.width;
	}
	
	CGFloat currentOrigin = self.leftButtonItem ? self.leftButtonItem.width : 0.0f; // If there is a left item, start laying out items after it.
	currentOrigin += (availableWidth-totalItemWidth)/2;
	
	for (int i=0; i<self.tabItems.count; i++)
	{
		KATGTabBarItem *item = [self.tabItems objectAtIndex:i];
		item.view.frame = CGRectMake(currentOrigin, self.tabItemTopMargin + 1.0f, item.width, self.bounds.size.height - 2.0f - self.tabItemTopMargin - self.tabItemBottomMargin);
		[item performLayout];
		currentOrigin += item.width;
		currentOrigin += self.tabItemSpacing;
	}
	
	// Drawer states
	self.leftButtonItem.view.frame = CGRectMake(0.0f, 0.0f, self.leftButtonItem.width, self.bounds.size.height);
	self.rightButtonItem.view.frame = CGRectMake(self.bounds.size.width-self.rightButtonItem.width, 0.0f, self.rightButtonItem.width, self.bounds.size.height);
	
	[self.leftButtonItem performLayout];
	[self.rightButtonItem performLayout];
}

- (void)selectTabItem:(KATGTabBarTabItem *)item
{
	[self selectTabItem:item animated:NO];
}

- (void)selectTabItem:(KATGTabBarTabItem *)item animated:(BOOL)animated wasTapped:(BOOL)wasTapped
{
	if (![self.delegate tabBar:self shouldSelectItemAtIndex:[self.tabItems indexOfObject:item] wasTapped:wasTapped])
	{
		return;
	}
	
	if (self.selectedItem)
	{
		self.selectedItem.state = KATGTabBarTabItemStateNormal;
		[self.selectedItem performLayout];
	}
	
	self.selectedItem = item;
	self.selectedItem.state = KATGTabBarTabItemStateSelected;
	[self.selectedItem performLayout];
	
	[self.delegate tabBar:self didSelectItemAtIndex:[self.tabItems indexOfObject:item] wasTapped:wasTapped];
	
	[UIView animateWithDuration:(animated ? 0.15f : 0.0f) animations:^{
		[self layoutCurrentSelection];
	} completion:^(BOOL finished) {
		
	}];
}

- (void)selectTabItem:(KATGTabBarTabItem *)item animated:(BOOL)animated
{
	[self selectTabItem:item animated:animated wasTapped:NO];
}

- (void)selectTabItemAtIndex:(NSInteger)index
{
	[self selectTabItemAtIndex:index animated:NO];
}

- (void)selectTabItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
	if (index >= self.tabItems.count)
	{
		return;
	}
	
	[self selectTabItem:[self.tabItems objectAtIndex:index] animated:animated];
}

#pragma mark - KATGTabBarItemDelegate methods

- (void)tabBarItemDidUpdate:(KATGTabBarItem *)item
{
	[self setNeedsLayout];
}

#pragma mark - KATGTabBarTabItemDelegate methods

- (void)tabBarTabItemWasTapped:(KATGTabBarTabItem *)item
{
	[self selectTabItem:item animated:YES wasTapped:YES];
}

#pragma mark - KATGTabBarButtonItemDelegate methods

- (void)tabBarButtonItem:(KATGTabBarButtonItem *)item setDrawerExpanded:(BOOL)expanded animated:(BOOL)animated
{
	if (self.leftButtonItem == item)
	{
		[self setLeftButtonItemIsExpanded:expanded animated:animated];
	}
	else if (self.rightButtonItem == item)
	{
		[self setRightButtonItemIsExpanded:expanded animated:animated];
	}
}

#pragma mark -

- (void)setLeftButtonItemIsExpanded:(BOOL)leftButtonItemIsExpanded
{
	[self setLeftButtonItemIsExpanded:leftButtonItemIsExpanded animated:NO];
}

- (void)setLeftButtonItemIsExpanded:(BOOL)leftButtonItemIsExpanded animated:(BOOL)animated
{
	CGFloat animationDuration = animated ? 0.3f : 0.0f;
	_leftButtonItemIsExpanded = leftButtonItemIsExpanded;
	
	if (leftButtonItemIsExpanded)
	{
		if (self.rightButtonItemIsExpanded)
		{
			[self setRightButtonItemIsExpanded:NO animated:NO];
		}
		[self.drawerContainerView addSubview:self.leftButtonItem.drawerView];
		
		// Shift the drawer off screen so it can animate in
		CGRect drawerContainerRect = self.drawerContainerView.frame;
		drawerContainerRect.origin.x = - drawerContainerRect.size.width;
		self.drawerContainerView.frame = drawerContainerRect;
		self.userInteractionEnabled = NO;
		
		[self.delegate tabBarDidOpenDrawer:self];
		
		[UIView animateWithDuration:animationDuration animations:^{
			[self layoutDrawer];
		} completion:^(BOOL finished) {
			self.userInteractionEnabled = YES;
		}];
	}
	else
	{
		self.userInteractionEnabled = NO;
		[UIView animateWithDuration:animationDuration animations:^{
			// Shift the drawer container offscreen
			CGRect drawerContainerRect = self.drawerContainerView.frame;
			drawerContainerRect.origin.x = - drawerContainerRect.size.width;
			self.drawerContainerView.frame = drawerContainerRect;
			self.selectedItemBackgroundView.alpha = (self.leftButtonItemIsExpanded || self.rightButtonItemIsExpanded) ? 0.0f : 1.0f;
		} completion:^(BOOL finished) {
			[self.leftButtonItem.drawerView removeFromSuperview];
			[self layoutDrawer];
			self.userInteractionEnabled = YES;
		}];
	}
}

- (void)setRightButtonItemIsExpanded:(BOOL)rightButtonItemIsExpanded
{
	[self setRightButtonItemIsExpanded:rightButtonItemIsExpanded animated:NO];
}

- (void)setRightButtonItemIsExpanded:(BOOL)rightButtonItemIsExpanded animated:(BOOL)animated
{
	CGFloat animationDuration = animated ? 0.3f : 0.0f;
	_rightButtonItemIsExpanded = rightButtonItemIsExpanded;
	
	if (rightButtonItemIsExpanded)
	{
		if (self.leftButtonItemIsExpanded)
		{
			[self setLeftButtonItemIsExpanded:NO animated:NO];
		}
		[self.drawerContainerView addSubview:self.rightButtonItem.drawerView];
		
		// Shift the drawer off screen so it can animate in
		CGRect drawerContainerRect = self.drawerContainerView.frame;
		drawerContainerRect.origin.x = drawerContainerRect.size.width;
		self.drawerContainerView.frame = drawerContainerRect;
		self.userInteractionEnabled = NO;
		
		[self.delegate tabBarDidOpenDrawer:self];
		
		[UIView animateWithDuration:animationDuration animations:^{
			[self layoutDrawer];
		} completion:^(BOOL finished) {
			self.userInteractionEnabled = YES;
		}];
	}
	else
	{
		
		self.userInteractionEnabled = NO;
		[UIView animateWithDuration:animationDuration animations:^{
			// Shift the drawer container offscreen
			CGRect drawerContainerRect = self.drawerContainerView.frame;
			drawerContainerRect.origin.x = drawerContainerRect.size.width;
			self.drawerContainerView.frame = drawerContainerRect;
			self.selectedItemBackgroundView.alpha = (self.leftButtonItemIsExpanded || self.rightButtonItemIsExpanded) ? 0.0f : 1.0f;
		} completion:^(BOOL finished) {
			[self.rightButtonItem.drawerView removeFromSuperview];
			[self layoutDrawer];
			self.userInteractionEnabled = YES;
		}];
	}
}

- (void)layoutDrawer
{
	self.drawerContainerView.hidden = !(self.leftButtonItemIsExpanded || self.rightButtonItemIsExpanded);
	self.selectedItemBackgroundView.alpha = (self.leftButtonItemIsExpanded || self.rightButtonItemIsExpanded) ? 0.0f : 1.0f;
	
	[self.itemContainerView bringSubviewToFront:self.drawerContainerView];  
	self.drawerContainerView.frame = self.itemContainerView.bounds;
	if (self.leftButtonItemIsExpanded)
	{
		[self.itemContainerView bringSubviewToFront:self.leftButtonItem.view];
	}
	if (self.rightButtonItemIsExpanded)
	{
		[self.itemContainerView bringSubviewToFront:self.rightButtonItem.view];
	}
	self.leftButtonItem.drawerView.frame = self.drawerContainerView.bounds;
	self.leftButtonItem.drawerBackgroundView.frame = self.drawerContainerView.bounds;
	self.leftButtonItem.drawerContentView.frame = CGRectMake(self.leftButtonItem.width, 0.0f, self.drawerContainerView.bounds.size.width-self.leftButtonItem.width, self.drawerContainerView.bounds.size.height);
	
	self.rightButtonItem.drawerView.frame = self.drawerContainerView.bounds;
	self.rightButtonItem.drawerBackgroundView.frame = self.drawerContainerView.bounds;
	self.rightButtonItem.drawerContentView.frame = CGRectMake(0.0f, 0.0f, self.drawerContainerView.bounds.size.width-self.rightButtonItem.width, self.drawerContainerView.bounds.size.height);
}

- (void)layoutCurrentSelection
{
	if (self.selectedItem)
	{
		self.selectedItemBackgroundView.frame = CGRectMake(self.selectedItem.view.frame.origin.x, 0.0f, self.selectedItem.view.frame.size.width, self.bounds.size.height);
	}
}

@end
