//
//  KATGShowPlayState.h
//  KATG
//
//  Created by Doug Russell on 5/11/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KATGShow;

@interface KATGShowPlayState : NSManagedObject

+ (NSString *)katg_entityName;

@property (nonatomic, retain) NSNumber *lastPlaybackTime;
@property (nonatomic, retain) KATGShow *show;

@end
