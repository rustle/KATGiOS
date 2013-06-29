//
//  KATGDownloadOperation.m
//  KATG
//
//  Created by Doug Russell on 3/7/13.
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

#import "KATGDownloadOperation.h"

@implementation KATGDownloadOperation

+ (instancetype)newDownloadOperationWithRemoteURL:(NSURL *)remoteURL fileURL:(NSURL *)fileURL completion:(ESHTTPOperationCompletionBlock)completion
{
	return [[self alloc] initDownloadOperationWithRemoteURL:remoteURL fileURL:fileURL completion:completion];
}

- (BOOL)exists:(NSURL *)fileURL size:(NSUInteger *)size
{
	NSParameterAssert(size);
	NSParameterAssert([fileURL isFileURL]);
	BOOL fileExists;
	if ([fileURL checkResourceIsReachableAndReturnError:nil])
	{
		fileExists = YES;
		NSNumber *sizeObject;
		NSError *error;
		if ([fileURL getResourceValue:&sizeObject forKey:NSURLFileSizeKey error:&error])
		{
			*size = [sizeObject unsignedIntegerValue];
		}
		else
		{
			NSLog(@"%@", error);
			return NO;
		}
	}
	else
	{
		fileExists = NO;
		*size = 0;
	}
	return fileExists;
}

- (instancetype)initDownloadOperationWithRemoteURL:(NSURL *)remoteURL fileURL:(NSURL *)fileURL completion:(ESHTTPOperationCompletionBlock)completion
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:remoteURL];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	NSOutputStream *outputStream;
	NSUInteger size;
	if ([self exists:fileURL size:&size])
	{
		[request setValue:[NSString stringWithFormat:@"bytes=%d-", size] forHTTPHeaderField:@"Range"];
		outputStream = [NSOutputStream outputStreamWithURL:fileURL append:YES];
	}
	else
	{
		outputStream = [NSOutputStream outputStreamWithURL:fileURL append:NO];
	}
	self = [super initWithRequest:request work:NULL completion:completion];
	if (self)
	{
		self.outputStream = outputStream;
		self.cancelOnStatusCodeError = YES;
		if (size)
		{
			self.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:206];
		}
		else
		{
			self.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:200];
		}
	}
	return self;
}

@end
