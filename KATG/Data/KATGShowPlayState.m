//
//  KATGShowPlayState.m
//  KATG
//
//  Created by Doug Russell on 5/11/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGShowPlayState.h"
#import "KATGShow.h"

@implementation KATGShowPlayState
@dynamic lastPlaybackTime;
@dynamic show;

+ (NSString *)katg_entityName
{
	return @"ShowPlayState";
}

@end
