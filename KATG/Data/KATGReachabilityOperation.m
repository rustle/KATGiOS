//
//  KATGReachabilityOperation.m
//  KATG
//
//  Created by Doug Russell on 4/20/13.
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

#import "KATGReachabilityOperation.h"
#import "Reachability.h"

NSString * const kKATGReachabilityIsReachableNotification = @"KATGReachabilityIsReachableNotification";

@interface KATGReachabilityOperation ()
@property (nonatomic) Reachability *reachabilityForHost;
@property (copy, nonatomic) NSString *host;
@end

@implementation KATGReachabilityOperation

- (instancetype)initWithHost:(NSString *)host
{
	self = [super init];
	if (self)
	{
		_host = host;
		NSParameterAssert(_host);
	}
	return self;
}

- (void)operationDidStart
{
	NSParameterAssert(self.host);
	self.reachabilityForHost = [Reachability reachabilityWithHostName:self.host];
	NSParameterAssert(self.reachabilityForHost);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:self.reachabilityForHost];
	[self.reachabilityForHost startNotifier];
}

- (void)reachabilityChanged:(NSNotification *)note
{
	NSParameterAssert([self isActualRunLoopThread]);
	NSParameterAssert([[note object] isEqual:self.reachabilityForHost]);
	if ([self.reachabilityForHost isReachable])
	{
		[self finishWithError:nil];
	}
}

- (void)operationWillFinish
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:self.reachabilityForHost];
	self.reachabilityForHost = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:kKATGReachabilityIsReachableNotification object:nil];
}

@end
