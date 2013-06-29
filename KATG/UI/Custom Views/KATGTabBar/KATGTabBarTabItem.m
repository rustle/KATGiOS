//
//  KATGTabBarTabItem.m
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

#import "KATGTabBarTabItem.h"
#import "KATGTabBar.h"
#import "KATGTabBarStyledImageView.h"

#define IMAGE_SIZE 24.0f
#define IMAGE_TOP_MARGIN 4.0f

@interface KATGTabBarTabItem ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) KATGTabBarStyledImageView *styledImageView;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;

@end

@implementation KATGTabBarTabItem

- (void)katgtabbartabitem_commonInit
{
  self.view.backgroundColor = [UIColor clearColor];
  _titleLabel = [[UILabel alloc] init];
  _titleLabel.font = [UIFont boldSystemFontOfSize:9.0f];
  _titleLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
  _titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
  _titleLabel.textAlignment = NSTextAlignmentCenter;
  _titleLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:_titleLabel];
	
	_styledImageView = [[KATGTabBarStyledImageView alloc] initWithFrame:CGRectZero];
	[self.view addSubview:_styledImageView];
  
  _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
  [self.view addGestureRecognizer:_tapRecognizer];
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		[self katgtabbartabitem_commonInit];
	}
	return self;
}

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title
{
	self = [self init];
	if (self)
	{
		[self katgtabbartabitem_commonInit];
		_image = image;
		_title = title;
		_titleLabel.text = title;
		
		_styledImageView.image = image;
		
		self.view.isAccessibilityElement = YES;
		self.view.accessibilityLabel = _title;
	}
	return self;
}

- (void)performLayout
{
	[super performLayout];
	
	self.titleLabel.frame = CGRectMake(0.0f, self.view.bounds.size.height - 20.0f, self.view.bounds.size.width, 20.0f);
	self.titleLabel.textColor = (self.state == KATGTabBarTabItemStateSelected) ? [UIColor colorWithWhite:0.8f alpha:1.0f] : [UIColor colorWithWhite:0.4f alpha:1.0f];
	
	self.styledImageView.frame = CGRectMake((self.view.bounds.size.width - IMAGE_SIZE)/2, IMAGE_TOP_MARGIN, IMAGE_SIZE, IMAGE_SIZE);
	self.styledImageView.topGradientColor = (self.state == KATGTabBarTabItemStateSelected) ? [UIColor colorWithWhite:0.9f alpha:1.0f] : [UIColor colorWithWhite:0.5f alpha:1.0f];
	self.styledImageView.bottomGradientColor = (self.state == KATGTabBarTabItemStateSelected) ? [UIColor colorWithWhite:0.8f alpha:1.0f] : [UIColor colorWithWhite:0.4f alpha:1.0f];
	
}

- (CGFloat)width
{
	return 64.0f;
}

- (void)tapped:(id)sender
{
	[self.tabBar tabBarTabItemWasTapped:self];
}

@end
