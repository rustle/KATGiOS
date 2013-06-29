//
//  KATGTabBarButtonItem.h
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

#import "KATGTabBarItem.h"

@class KATGTabBarButtonItem;

@protocol KATGTabBarButtonItemDelegate <KATGTabBarItemDelegate>
- (void)tabBarButtonItem:(KATGTabBarButtonItem *)item setDrawerExpanded:(BOOL)expanded animated:(BOOL)animated;
@end

@interface KATGTabBarButtonItem : KATGTabBarItem

@property (weak, nonatomic) KATGTabBar<KATGTabBarButtonItemDelegate> *tabBar;

@property (weak, nonatomic) id target;
@property (nonatomic) SEL action;

@property (nonatomic) UIImage *image;

@property (nonatomic) BOOL actsAsDrawer;
@property (nonatomic) UIView *drawerContentView;
@property (nonatomic) UIView *drawerBackgroundView;
@property (nonatomic) BOOL drawerIsExpanded;

- (instancetype)initWithImage:(UIImage *)image target:(id)target action:(SEL)action;

- (void)setDrawerIsExpanded:(BOOL)drawerIsExpanded animated:(BOOL)animated;
- (UIView *)drawerView;

@end
