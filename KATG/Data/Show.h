//
//  Show.h
//  KATG
//
//  Created by Timothy Donnelly on 12/6/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Show : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * episode_id;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * access;
@property (nonatomic, retain) NSSet *guests;
@property (nonatomic, retain) NSSet *images;
@end

@interface Show (CoreDataGeneratedAccessors)

- (void)addGuestsObject:(NSManagedObject *)value;
- (void)removeGuestsObject:(NSManagedObject *)value;
- (void)addGuests:(NSSet *)values;
- (void)removeGuests:(NSSet *)values;

- (void)addImagesObject:(NSManagedObject *)value;
- (void)removeImagesObject:(NSManagedObject *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
