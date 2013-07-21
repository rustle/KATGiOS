//
//  KATGContentContainerView.m
//  KATG
//
//  Created by Timothy Donnelly on 12/12/12.
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

#import "KATGContentContainerView.h"
#import "KATGContentContainerView_Internal.h"
#import "TDRoundedShadowView.h"

@implementation KATGContentContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_headerHeight = 44.0f;
		_footerHeight = 44.0f;
		
		_backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
		_backgroundView.backgroundColor = [UIColor colorWithWhite:0.96f alpha:1.0f];
		_backgroundView.layer.cornerRadius = 4.0f;
		[self addSubview:_backgroundView];
		
		_headerView = [[UIView alloc] initWithFrame:CGRectZero];
		[self addSubview:_headerView];
		
		_contentView = [[UIScrollView alloc] initWithFrame:CGRectZero];
		_contentView.backgroundColor = [UIColor colorWithWhite:0.86f alpha:1.0f];
		_contentView.clipsToBounds = YES;
		[self addSubview:_contentView];
		
		_footerView = [[UIView alloc] initWithFrame:CGRectZero];
		[self addSubview:_footerView];
		
		_headerShadowView = [[TDRoundedShadowView alloc] initWithFrame:CGRectZero];
		_headerShadowView.shadowSide = TDRoundedShadowSideTop;
		_headerShadowView.lineWidth = 1.0f / [[UIScreen mainScreen] scale];
		[self addSubview:_headerShadowView];
		
		_footerShadowView = [[TDRoundedShadowView alloc] initWithFrame:CGRectZero];
		_footerShadowView.shadowSide = TDRoundedShadowSideBottom;
		_footerShadowView.lineWidth = 1.0f / [[UIScreen mainScreen] scale];
		[self addSubview:_footerShadowView];
		
		self.accessibilityElements = @[_headerView, _contentView, _footerView];
		
		self.isAccessibilityElement = NO;
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self layoutContent];
}

- (void)layoutContent
{
	self.backgroundView.frame = self.bounds;
	
	CGRect headerRect = CGRectZero;
	headerRect.size.width = self.bounds.size.width;
	headerRect.size.height = self.headerHeight;
	self.headerView.frame = headerRect;
	
	CGRect contentRect = CGRectZero;
	contentRect.size.width = self.bounds.size.width;
	contentRect.size.height = self.bounds.size.height - self.headerHeight - self.footerHeight;
	contentRect.origin.y = self.headerHeight;
	self.contentView.frame = contentRect;
	
	CGRect footerRect = CGRectZero;
	footerRect.size.width = self.bounds.size.width;
	footerRect.size.height = self.footerHeight;
	footerRect.origin.y = CGRectGetMaxY(contentRect);
	self.footerView.frame = footerRect;
	
	CGRect headerShadowRect = CGRectZero;
	headerShadowRect.size.width = self.bounds.size.width;
	headerShadowRect.size.height = 6.0f;
	headerShadowRect.origin.y = self.headerHeight;
	self.headerShadowView.frame = headerShadowRect;
	
	CGRect footerShadowRect = CGRectZero;
	footerShadowRect.size.width = self.bounds.size.width;
	footerShadowRect.size.height = 6.0f;
	footerShadowRect.origin.y = footerRect.origin.y - 6.0f;
	self.footerShadowView.frame = footerShadowRect;
}

- (NSInteger)accessibilityElementCount
{
	return [self.accessibilityElements count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
	return self.accessibilityElements[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
	return [self.accessibilityElements indexOfObject:element];
}

- (void)setFooterHeight:(CGFloat)footerHeight
{
	_footerHeight = footerHeight;
	[self layoutContent];
}

- (void)setHeaderHeight:(CGFloat)headerHeight
{
	_headerHeight = headerHeight;
	[self layoutContent];
}

@end
