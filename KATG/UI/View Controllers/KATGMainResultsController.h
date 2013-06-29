//
//  KATGMainResultsController.h
//  KATG
//
//  Created by Doug Russell on 3/28/13.
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
#import "KATGMainDataSource.h"

@protocol KATGMainResultsControllerDelegate <NSObject>

- (void)reloadAllData;

- (void)didChangeEvents;

//- (void)didRemoveEventsAtIndexPaths:(NSArray *)indexPaths;
//- (void)didInsertEventsAtIndexPaths:(NSArray *)indexPaths;
//- (void)didUpdateEventsAtIndexPaths:(NSArray *)indexPaths;

- (void)didChangeShows;

//- (void)didRemoveShowsAtIndexPaths:(NSArray *)indexPaths;
//- (void)didInsertShowsAtIndexPaths:(NSArray *)indexPaths;
//- (void)didUpdateShowsAtIndexPaths:(NSArray *)indexPaths;

@end

@interface KATGMainResultsController : NSObject

- (bool)performFetch:(NSError *__autoreleasing*)error;

@property (nonatomic, readonly) NSArray *events;
@property (nonatomic, readonly) NSArray *shows;

@property (weak, nonatomic) id<KATGMainResultsControllerDelegate> delegate;

@end
