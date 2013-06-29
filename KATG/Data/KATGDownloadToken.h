//
//  KATGDownloadToken.h
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

#import <Foundation/Foundation.h>
#import "KATGDataStore.h"

@class KATGDownloadOperation;

@interface KATGDownloadToken : NSObject <KATGDownloadToken>

@property (nonatomic) CGFloat progress;
@property (copy, nonatomic) void (^progressBlock)(CGFloat progress);
@property (copy, nonatomic) void (^completionBlock)(NSError *error);

- (void)callProgressBlockWithProgress:(CGFloat)progress;
- (void)callCompletionBlockWithError:(NSError *)error;

- (instancetype)initWithOperation:(KATGDownloadOperation *)op;

@end
