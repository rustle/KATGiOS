//
//  KATGScheduledEvent.m
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

#import "KATGScheduledEvent.h"

NSString *const KATGScheduledEventTimestampAttributeName = @"timestamp";
NSString *const KATGScheduledEventEventIDAttributeName = @"eventid";

@implementation KATGScheduledEvent
@dynamic timestamp;
@dynamic title;
@dynamic subtitle;
@dynamic eventid;
@dynamic location;
@dynamic details;
@dynamic showEvent;

+ (void)initialize
{
	if (self == [KATGScheduledEvent class])
	{
		static NSLock *dateLock;
		dateLock = [NSLock new];
		ESObjectMap *map = [KATGScheduledEvent objectMap];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"startdate" outputKey:KATGScheduledEventTimestampAttributeName transformBlock:^id(id<ESObject> object, id inputValue) {
			NSDate *date;
			[dateLock lock];
			static NSDateFormatter *formatter;
			if (formatter == nil)
			{
				formatter = [[NSDateFormatter alloc] init];
				[formatter setDateStyle:NSDateFormatterLongStyle];
				[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
				[formatter setDateFormat:@"MM/dd/yyyy HH:mm"];
				NSTimeZone  *timeZone = [NSTimeZone timeZoneWithName:@"America/New_York"];
				[formatter setTimeZone:timeZone];
			}
			date = [formatter dateFromString:inputValue];
			[dateLock unlock];
			return date;
		}]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:nil outputKey:@"title" transformBlock:^id(id<ESObject> object, id inputValue) {
			NSParameterAssert([inputValue isKindOfClass:[NSString class]]);
			((KATGScheduledEvent *)object).showEvent = @([inputValue rangeOfString:@"Live Show"].location != NSNotFound);
			NSString *liveShowWith = @"Live Show with";
			NSRange range = [inputValue rangeOfString:liveShowWith options:(NSCaseInsensitiveSearch|NSAnchoredSearch) range:NSMakeRange(0, MIN([liveShowWith length], [inputValue length]))];
			if (range.location != NSNotFound)
			{
				((KATGScheduledEvent *)object).subtitle = [inputValue substringFromIndex:range.length];
				inputValue = @"Live Show";
			}
			return inputValue;
		}]];
	}
}

+ (NSString *)katg_entityName
{
	return @"Event";
}

- (NSString *)formattedDate
{
	NSParameterAssert([NSThread isMainThread]);
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil)
	{
		dateFormatter = [NSDateFormatter new];
		[dateFormatter setDateFormat:@"EEEE, MMMM d"];
	}
	return [dateFormatter stringFromDate:self.timestamp];
}

- (NSString *)formattedTime
{
	NSParameterAssert([NSThread isMainThread]);
	static NSDateFormatter *timeFormatter = nil;
	if (timeFormatter == nil)
	{
		timeFormatter = [NSDateFormatter new];
		[timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[timeFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	return [timeFormatter stringFromDate:self.timestamp];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ : %p> Title: %@", NSStringFromClass([self class]), self, self.title];
}

- (bool)futureTest
{
	NSInteger timeSince = [self.timestamp timeIntervalSinceNow];
	NSInteger threshHold = -(60 /*Seconds*/ * 60 /*Minutes*/);
	bool inFuture = (timeSince > threshHold);
//	NSLog(@"%@ inFuture: %@", self.title, inFuture ? @"true" : @"false");
	return inFuture;
}

@end
