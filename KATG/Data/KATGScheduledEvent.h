//
//  KATGScheduledEvent.h
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

#import <CoreData/CoreData.h>
#import "NSManagedObject+ESObject.h"

extern NSString *const KATGScheduledEventTimestampAttributeName;
extern NSString *const KATGScheduledEventEventIDAttributeName;

@interface KATGScheduledEvent : NSManagedObject

@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;
@property (nonatomic) NSString *eventid;
@property (nonatomic) NSString *location;
@property (nonatomic) NSString *details;
@property (nonatomic) NSNumber *showEvent;

+ (NSString *)katg_entityName;

- (NSString *)formattedDate;
- (NSString *)formattedTime;
- (bool)futureTest;

@end
