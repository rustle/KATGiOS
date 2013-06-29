//
//  KATGShow.h
//  KATG
//
//  Created by Timothy Donnelly on 12/6/12.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+ESObject.h"

typedef NS_ENUM(NSUInteger, KATGShowObjectStatus) {
	
	KATGShowObjectStatusShowReload = 1<<1,
	KATGShowObjectStatusShowDeleted = 1<<2,
	KATGShowObjectStatusShowInserted = 1<<3,
	
	KATGShowObjectStatusImagesReload = 1<<10,
	KATGShowObjectStatusImagesDeleted = 1<<11,
	KATGShowObjectStatusImagesInserted = 1<<12,
	
	KATGShowObjectStatusGuestsReload = 1<<20,
	KATGShowObjectStatusGuestsDeleted = 1<<21,
	KATGShowObjectStatusGuestsInserted = 1<<22,
	
	KATGShowObjectStatusAllInvalidated = NSUIntegerMax,
};

#import "KATGGuest.h"
#import "KATGImage.h"
#import "KATGShowPlayState.h"

extern NSString *const KATGShowEpisodeIDAttributeName;

@interface KATGShow : NSManagedObject

// TODO: rename desc to notes and add show type attribute

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * episode_id;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * media_url;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * access;
@property (nonatomic, retain) NSNumber * downloaded;
@property (nonatomic, retain) NSString * file_url;
@property (nonatomic, retain) NSSet * guests;
@property (nonatomic, retain) NSSet * images;
@property (nonatomic, retain) KATGShowPlayState *playState;

+ (NSString *)katg_entityName;
+ (NSNumber *)episodeIDForShowDictionary:(NSDictionary *)showDictionary;
+ (NSArray *)guestDictionariesForShowDictionary:(NSDictionary *)showDictionary;
- (KATGShowObjectStatus)showStatusBasedOnNotification:(NSNotification *)note checkRelationships:(bool)checkRelationships;

@end

@interface KATGShow (CoreDataGeneratedAccessors)

- (void)addGuestsObject:(KATGGuest *)value;
- (void)removeGuestsObject:(KATGGuest *)value;
- (void)addGuests:(NSSet *)values;
- (void)removeGuests:(NSSet *)values;

- (void)addImagesObject:(KATGImage *)value;
- (void)removeImagesObject:(KATGImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@property (readonly) NSArray *sortedGuests;

- (NSString *)formattedTimestamp;

@end
