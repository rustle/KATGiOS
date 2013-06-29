//
//  KATGTabBar.h
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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, KATGTabBarInterfaceLuminosity) {
	KATGTabBarInterfaceLuminosityDark,
	KATGTabBarInterfaceLuminosityLight,
};

@class KATGTabBarItem, KATGTabBarButtonItem, KATGTabBarTabItem;
@class KATGTabBar;

@protocol KATGTabBarDelegate <NSObject>
- (BOOL)tabBar:(KATGTabBar *)tabBar shouldSelectItemAtIndex:(NSInteger)index wasTapped:(BOOL)wasTapped;
- (void)tabBar:(KATGTabBar *)tabBar didSelectItemAtIndex:(NSInteger)index wasTapped:(BOOL)wasTapped;
- (void)tabBarDidOpenDrawer:(KATGTabBar *)tabBar;
@end

@interface KATGTabBar : UIView

@property (weak, nonatomic) IBOutlet id<KATGTabBarDelegate> delegate;

@property (nonatomic) NSArray *tabItems;
@property (nonatomic) KATGTabBarButtonItem *leftButtonItem;
@property (nonatomic) KATGTabBarButtonItem *rightButtonItem;

@property (nonatomic) CGFloat tabItemSpacing;
@property (nonatomic) CGFloat tabItemTopMargin;
@property (nonatomic) CGFloat tabItemBottomMargin;

- (void)selectTabItem:(KATGTabBarTabItem *)item;
- (void)selectTabItem:(KATGTabBarTabItem *)item animated:(BOOL)animated;
- (void)selectTabItemAtIndex:(NSInteger)index;
- (void)selectTabItemAtIndex:(NSInteger)index animated:(BOOL)animated;

@end
