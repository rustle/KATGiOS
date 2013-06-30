//
//  KATGEpisodeViewController_iPhone.h
//  KATG
//
//  Created by Timothy Donnelly on 11/12/12.
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

#import "KATGViewController.h"

@class KATGShow, KATGShowViewController, KATGShowView;

@protocol KATGShowViewControllerDelegate <NSObject>
- (void)closeShowViewController:(KATGShowViewController *)showViewController;
@end

// Used to configure the view during transitions
typedef enum {
	KATGShowViewControllerInterfaceStateExpanded,
	KATGShowViewControllerInterfaceStateCollapsed
} KATGShowViewControllerInterfaceState;

@interface KATGShowViewController : KATGViewController

@property (nonatomic, readonly) KATGShow *show;
@property (nonatomic) NSManagedObjectID	*showObjectID;

// the KATGShowView is traded between the details view controller and the cells in the main UI during transitions.
@property (strong, nonatomic) KATGShowView *showView;

@property (weak, nonatomic) id<KATGShowViewControllerDelegate> delegate;

@property (strong, nonatomic, readonly) UITableView *tableView;

// Set this to switch between expanded and collapsed states (for transitioning between this view controller and the cells in the main UI)
@property (nonatomic, readonly) KATGShowViewControllerInterfaceState interfaceState;
- (void)setInterfaceState:(KATGShowViewControllerInterfaceState)interfaceState;

@property (nonatomic) CGFloat collapsedFooterHeight;
@property (nonatomic) CGFloat collapsedHeaderHeight;
@property (nonatomic) CGFloat expandedFooterHeight;
@property (nonatomic) CGFloat expandedHeaderHeight;

@property (nonatomic) CGRect collapsedShowViewRect;

@end
