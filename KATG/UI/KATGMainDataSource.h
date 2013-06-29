//
//  KATGMainDataSource.h
//  KATG
//
//  Created by Doug Russell on 4/16/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
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
#import "KATGMainViewController.h"

@class TDCollectionView;

typedef NS_ENUM(NSUInteger, KATGSection) {
	KATGSectionSchedule,
	KATGSectionLive,
	KATGSectionArchive
};

@interface KATGMainDataSource : NSObject

@property (weak, nonatomic) KATGMainViewController *mainViewController;
@property (nonatomic) TDCollectionView *mainCollectionView;
@property (nonatomic) UITableView *eventsTableView;
@property (nonatomic, readonly) NSArray *shows;
@property (nonatomic, readonly) NSArray *events;

- (bool)performFetch:(NSError *__autoreleasing*)error;

// Making this public is kind of gross
@property (nonatomic) bool collectionViewScrollingAnimationInProgress;

@end
