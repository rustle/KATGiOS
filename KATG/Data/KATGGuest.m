//
//  KATGGuest.m
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

#import "KATGGuest.h"
#import "KATGImage.h"
#import "KATGShow.h"

NSString *const KATGGuestGuestIDAttributeName = @"guest_id";

@implementation KATGGuest
@dynamic name;
@dynamic guest_id;
@dynamic link_url;
@dynamic desc;
@dynamic shows;
@dynamic image;

+ (NSNumber *)guestIDForGuestDictionary:(NSDictionary *)guestDictionary
{
	return @([guestDictionary[@"ShowGuestId"] integerValue]);
}

+ (NSString *)katg_entityName
{
	return @"Guest";
}

+ (void)initialize
{
	if (self == [KATGGuest class])
	{
		ESObjectMap *map = [KATGGuest objectMap];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"ShowGuestId" outputKey:@"guest_id" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue integerValue]);
		}]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"RealName" outputKey:@"name"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Description" outputKey:@"desc"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Url1" outputKey:@"link_url"]];
	}
}

@end
