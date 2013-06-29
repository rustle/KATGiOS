//
//  KATGImage.m
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

#import "KATGImage.h"
#import "KATGGuest.h"
#import "KATGShow.h"
#import "NSManagedObject+ESObject.h"

NSString *const KATGImageMediaURLAttributeName = @"media_url";
NSString *const KATGImageShowAttributeName = @"show";

@implementation KATGImage
@dynamic title;
@dynamic desc;
@dynamic media_url;
@dynamic index;
@dynamic guest;
@dynamic show;

+ (NSString *)katg_entityName
{
	return @"Image";
}

+ (void)initialize
{
	if (self == [KATGImage class])
	{
		ESObjectMap *map = [self objectMap];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"description" outputKey:@"desc"]];
	}
}

@end
