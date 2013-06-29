//
//  KATGImageCache.h
//  KATG
//
//  Created by Doug Russell on 3/9/13.
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

extern NSString *const KATGImageCacheErrorDomain;

typedef NS_ENUM(NSUInteger, KATGImageCacheErrorCode) {
	KATGImageCacheErrorCodeUnknown,
	KATGImageCacheErrorCodeCorruptImageData,
	KATGImageCacheErrorCodeScalingFailed,
};

@interface KATGImageCache : NSObject

+ (instancetype)imageCache;

// Completion and progress callbacks will occur on a private queue, be sure to move any UI interactions onto the main queue
// Pass CGSizeZero to use the image at it's natural size

- (void)imageForURL:(NSURL *)url size:(CGSize)size progressHandler:(void (^)(float))progressHandler completionHandler:(void (^)(UIImage *, NSError *))completionHandler;

- (void)requestImages:(id<NSFastEnumeration>)urlStrings size:(CGSize)size;

@end
