//
//  KATGDownloadToken.m
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

#import "KATGDownloadToken.h"
#import "KATGDownloadOperation.h"

@interface KATGDownloadToken ()
@property (nonatomic) KATGDownloadOperation *op;
@end

@implementation KATGDownloadToken

- (instancetype)initWithOperation:(KATGDownloadOperation *)op
{
	self = [super init];
	if (self)
	{
		_op = op;
		NSParameterAssert(_op);
	}
	return self;
}

- (void)cancel
{
	NSParameterAssert([NSThread isMainThread]);
	[self.op cancel];
}

- (BOOL)isCancelled
{
	NSParameterAssert([NSThread isMainThread]);
	return [self.op isCancelled];
}

- (void)callCompletionBlockWithError:(NSError *)error
{
	NSParameterAssert([NSThread isMainThread]);
	if (self.completionBlock)
	{
		self.completionBlock(error);
		self.op = nil;
		self.progressBlock = nil;
		self.completionBlock = nil;
	}
}

- (void)callProgressBlockWithProgress:(CGFloat)progress
{
	NSParameterAssert([NSThread isMainThread]);
	if (self.progressBlock)
	{
		self.progressBlock(progress);
	}
}

@end
