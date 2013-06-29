//
//  KATGTabBarTabItem.h
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

@class KATGTabBarTabItem;

@protocol KATGTabBarTabItemDelegate <KATGTabBarItemDelegate>
- (void)tabBarTabItemWasTapped:(KATGTabBarTabItem *)item;
@end

typedef NS_ENUM(NSUInteger, KATGTabBarTabItemState) {
  KATGTabBarTabItemStateNormal,
  KATGTabBarTabItemStateSelected,
  KATGTabBarTabItemStateHighlighted
};

@interface KATGTabBarTabItem : KATGTabBarItem

@property (weak, nonatomic) KATGTabBar<KATGTabBarTabItemDelegate> *tabBar;

@property (nonatomic) UIImage *image;
@property (nonatomic) NSString *title;

@property (nonatomic) KATGTabBarTabItemState state;

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title;

@end
