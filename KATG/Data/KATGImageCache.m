//
//  KATGImageCache.m
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

#import "KATGImageCache.h"
#import "KATGDataStore_Internal.h"
#import "ESHTTPOperation.h"
#import "KATGImageScalingOperation.h"

// Requesting an image:

////// ON ANY QUEUE //////

// 1. Make a request for an image with a url, size, progress and completion handler
// 2. If the input is invalid bail right away
// 3. If the input is good, bounce onto the work queue before doing any work

////// ON THE WORK QUEUE //////

// 4. Create a request object to represent the incoming request
// 5. Check the in memory cache for the requested image already scaled to the requested size
//    5.1 If image exists, call completion handler with it
//    5.2 Otherwise continue
// 6. Check disk for requested image already scaled to correct size
//    6.1 If the image exists, add it to the memory cache and then call completion handler with it
//    6.2 Otherwise continue
// 7. Check the disk for full size image
//    7.1 If the requested size is CGSizeZero or the full image matches the requested size, 
//    copy the image into place as the scaled image and also place the image in the memory 
//    cache before call completion handler with it
//    7.2 If the image is any other size
//       7.2.1 Stash the request object (detailed explanation of this mapping in the comments for - (void)storeRequest:(KATGImageCacheRequest *)request)
//       7.2.2 Queue a scaling operation

////// ON THE SYNC QUEUE //////

// 8. Stash the request object (detailed explanation of this mapping in the comments for - (void)storeRequest:(KATGImageCacheRequest *)request)
// 9. Check if an network request for this URL is already active
//    9.1 If a network request is active, then there's no more to do here
//    9.2 Otherwise queue up a network operation and stash it in activeImageConnections for tracking

// Network operations:
// TODO

// Scaling operations:
// TODO

#if DEBUG && 0
#define ImageCacheLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define ImageCacheLog(fmt, ...) 
#endif //DEBUG

NSString *const KATGImageCacheErrorDomain = @"KATGImageCacheErrorDomain";

@interface KATGImageCacheRequest : NSObject
// Hashed url string
@property (nonatomic) NSString *primaryKey;
// Hashed url string with size appended
@property (nonatomic) NSString *sizedKey;
// Target image size
@property (nonatomic) CGSize size;
// Progress callback (0.0 to 0.9 for download, 0.9 to 1.0 for scaling)
@property (copy, nonatomic) void (^progressHandler)(float);
// Completion callback
@property (copy, nonatomic) void (^completionHandler)(UIImage *, NSError *);
@end

@interface KATGImageCache ()
// Self purging in memory cache
@property (nonatomic) NSCache *memoryCache;
// ESHTTPOperations for images whose requests haven't been fulfilled
// Operations are left in activeImageConnections until all their 
// completion handlers have been called.
@property (nonatomic) NSMutableDictionary *activeImageConnections;
@property (nonatomic) NSMutableDictionary *activeScalingOperations;
// KATGImageCacheRequest objects
@property (nonatomic) NSMutableDictionary *requests;
// File url for image cache folder
@property (nonatomic) NSURL *imageCacheURL;
// Queue through which interactions with collections funnels
// Used primarily for de-duplication
@property (nonatomic) NSOperationQueue *syncQueue;
// Queue for scheduling network ops, these are all concurrent ops
// scheduled on a single thread, so it's width is about how much
// traffic you want simultaneously, rather than about how much
// CPU you want to take up
@property (nonatomic) NSOperationQueue *networkQueue;
// CPU bound task queue
@property (nonatomic) NSOperationQueue *workQueue;
@end

@implementation KATGImageCache

#pragma mark - Setup/Cleanup

+ (instancetype)imageCache
{
	static id imageCache;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		imageCache = [self new];
	});
	return imageCache;
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		// Cap the cache at 100 items
		// This limit is arbitrary, but on devices with a lot
		// of ram, the NSCache can grow very large and then
		// fail to empty fast enough to avoid the watch dog
		_memoryCache = [NSCache new];
		_memoryCache.countLimit = 100;
		
		// Serial queue
		_syncQueue = [NSOperationQueue new];
		_syncQueue.name = @"com.katg.imagecache.syncqueue";
		_syncQueue.maxConcurrentOperationCount = 1;
		
		// Borrow the network and work queues from the data store
		_networkQueue = [KATGDataStore sharedStore].networkQueue;
		NSParameterAssert(_networkQueue);
		_workQueue = [KATGDataStore sharedStore].workQueue;
		NSParameterAssert(_workQueue);
		
		_activeImageConnections = [NSMutableDictionary new];
		_activeScalingOperations = [NSMutableDictionary new];
		_requests = [NSMutableDictionary new];
	}
	return self;
}

#pragma mark - Memory Cache Subscripting

// Allow self[key] for looking up and writing to memory cache
// This is mostly a novelty

- (id)objectForKeyedSubscript:(id)key
{
	return [self.memoryCache objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
	[self.memoryCache setObject:obj forKey:key];
}

#pragma mark - Disk IO

- (NSURL *)imageCacheURL
{
	// If the URL has already been resolved/created, return it
	if (_imageCacheURL)
	{
		return _imageCacheURL;
	}
	// Find the caches URL and create it if needed
	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	// Append an arbitrary directory name, in this case KATGImageCache
	url = [url URLByAppendingPathComponent:@"KATGImageCache"];
	// See if our directory exists and is actually a directory
	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir])
	{
		// Create the directory
		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:NO attributes:nil error:&error])
		{
			// Not much we can do about this failing, so return nil and the cache will behave as an in memory only cache
			ImageCacheLog(@"%@", error);
			return nil;
		}
	}
	else if (!isDir)
	{
		// If the directory exists, but is not a directory, then some other logic is colliding with this cache and needs to be addressed
		// either by renaming this caches directory or fixing that other logic
		@throw [NSException exceptionWithName:NSGenericException reason:@"KATGImageCache exists in caches directory, but is not a directory." userInfo:nil];
	}
	_imageCacheURL = url;
	return _imageCacheURL;
}

- (NSURL *)fileURLForImageKey:(NSString *)key extension:(NSString *)extension
{
	NSParameterAssert(key);
	NSURL *url = [self.imageCacheURL URLByAppendingPathComponent:key];
	if (extension)
	{
		url = [url URLByAppendingPathExtension:extension];
	}
	return url;
}

- (BOOL)writeImage:(UIImage *)image key:(NSString *)key
{
	ImageCacheLog(@"Write image %@", key);
	return [self writeImageData:UIImageJPEGRepresentation(image, 1.0) key:key extension:nil];
}

- (BOOL)writeImageData:(NSData *)imageData key:(NSString *)key extension:(NSString *)extension
{
	NSParameterAssert(![NSThread isMainThread]);
	NSParameterAssert(imageData);
	NSParameterAssert(key);
	ImageCacheLog(@"Write image data %@", key);
	NSURL *fileURL = [self fileURLForImageKey:key extension:extension];
	if (fileURL == nil)
	{
		return NO;
	}
	return [imageData writeToURL:fileURL atomically:YES];
}

- (NSData *)imageDataForKey:(NSString *)key extension:(NSString *)extension
{
	NSParameterAssert(![NSThread isMainThread]);
	NSParameterAssert(key);
	NSURL *fileURL = [self fileURLForImageKey:key extension:extension];
	if (fileURL == nil)
	{
		return NO;
	}
	return [NSData dataWithContentsOfURL:fileURL];
}

- (void)deleteImageForKey:(NSString *)key extension:(NSString *)extension
{
	NSParameterAssert(![NSThread isMainThread]);
	NSParameterAssert(key);
	NSURL *fileURL = [self fileURLForImageKey:key extension:extension];
	if (fileURL)
	{
		[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
	}
}

- (UIImage *)handleImageData:(NSData *)data size:(CGSize)size key:(NSString *)key sizedKey:(NSString *)sizedKey error:(NSError **)error
{
	UIImage *image = [UIImage imageWithData:data];
	if (image)
	{
		[self writeImageData:data key:key extension:nil];
		return image;
	}
	if (error)
	{
		*error = [NSError errorWithDomain:KATGImageCacheErrorDomain code:KATGImageCacheErrorCodeCorruptImageData userInfo:nil];
	}
	return nil;
}

- (UIImage *)tryToLoadImageData:(NSString *)key extension:(NSString *)extension error:(NSError **)error
{
	NSData *imageData = [self imageDataForKey:key extension:extension];
	if (imageData)
	{
		UIImage *image = [UIImage imageWithData:imageData scale:[[UIScreen mainScreen] scale]];
		if (image)
		{
			return image;
		}
		else
		{
			// If we have data but can't make an image from it, our data is no good
			[self deleteImageForKey:key extension:nil];
			if (error)
			{
				*error = [NSError errorWithDomain:KATGImageCacheErrorDomain code:KATGImageCacheErrorCodeCorruptImageData userInfo:nil];
			}
			return nil;
		}
	}
	if (error)
	{
		*error = nil;
	}
	return nil;
}

#pragma mark - Hashing

// Dead simple hash to generate a reasonably unique key from the string
NS_INLINE unsigned int KATGBernsteinHash(NSString *string)
{
	unsigned int length = MIN([string length], 256);
	unichar buffer[length];
	[string getCharacters:buffer range:NSMakeRange(0, length)];
	unsigned int result = 5381;
	for (unsigned int i = 0; i < length; i++) { result = ((result << 5) + result) + buffer[i]; }
	return result;
}

#pragma mark - Scaling

- (void)queueScalingOp:(UIImage *)image request:(KATGImageCacheRequest *)request
{
	NSParameterAssert(image);
	NSParameterAssert(request);
	NSParameterAssert(!CGSizeEqualToSize(CGSizeZero, request.size));
	[self.syncQueue addOperationWithBlock:^{
		// See if there's already an active scaling op for this size
		KATGImageScalingOperation *op = self.activeScalingOperations[request.sizedKey];
		if (!op)
		{
			ImageCacheLog(@"Queueing up scaling for %@", request.sizedKey);
			op = [[KATGImageScalingOperation alloc] initWithImage:image targetSize:request.size];
			NSParameterAssert(op);
			// Store the op for tracking
			self.activeScalingOperations[request.sizedKey] = op;
			op.completionBlock = ^ {
				ImageCacheLog(@"Done scaling %@", request.sizedKey);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
				// Toss to handling which will notify waiting completion handlers and see if there
				// are any requests waiting to be fullfilled
				[self handleScalingOperation:op request:request];
				// Clear the completion block to break the retain cycle from referencing op
				op.completionBlock = nil;
#pragma clang diagnostic pop
			};
			[self.workQueue addOperation:op];
		}
		else
		{
			ImageCacheLog(@"Already scaling for %@", request.sizedKey);
		}
	}];
}

#pragma mark - Requests

// Create a new request object
- (KATGImageCacheRequest *)newRequestForURL:(NSURL *)url size:(CGSize)size
{
	// Hash the url string to make a key
	unsigned int hash = KATGBernsteinHash([url absoluteString]);
	NSString *primaryKey = [NSString stringWithFormat:@"%u", hash];
	// Append the image size to the key
	NSString *sizedKey = [NSString stringWithFormat:@"%u-%@", hash, NSStringFromCGSize(size)];
	KATGImageCacheRequest *request = [KATGImageCacheRequest new];
	request.primaryKey = primaryKey;
	request.sizedKey = sizedKey;
	request.size = size;
	return request;
}

// Store a map of maps of requests :)
// { primaryKey => { sizedkey => request } } 
// i.e. for url hashes 1 and 2, with requests for a 60x60 and 100x100 version of each:
// { 1 => { 1-60x60 => requestForOne60x60, 1-100x100 => requestForOne100x100 }, 2 => { 2-60x60 => requestForTwo60x60, 2-100x100 => requestForTwo100x100 } }
- (void)storeRequest:(KATGImageCacheRequest *)request
{
	NSParameterAssert(request);
	NSParameterAssert(request.primaryKey);
	NSParameterAssert(request.sizedKey);
	NSParameterAssert(request.completionHandler);
	NSMutableDictionary *requestsMappedBySize = self.requests[request.primaryKey];
	if (requestsMappedBySize == nil)
	{
		requestsMappedBySize = [NSMutableDictionary new];
	}
	NSMutableArray *requestsForSize = requestsMappedBySize[request.sizedKey];
	if (requestsForSize == nil)
	{
		requestsForSize = [NSMutableArray new];
	}
	[requestsForSize addObject:request];
	requestsMappedBySize[request.sizedKey] = requestsForSize;
	self.requests[request.primaryKey] = requestsMappedBySize;
}

- (void)callCompletionHandlers:(UIImage *)image error:(NSError *)error primaryKey:(NSString *)primaryKey sizedKey:(NSString *)sizedKey
{
	ImageCacheLog(@"Calling completion handlers for %@ %@", primaryKey, sizedKey);
	NSMutableDictionary *requestsMappedBySize = self.requests[primaryKey];
	NSMutableArray *requestsForSize = requestsMappedBySize[sizedKey];
	for (KATGImageCacheRequest *request in requestsForSize)
	{
		if (request.progressHandler)
		{
			request.progressHandler(1.0f);
		}
		ImageCacheLog(@"Calling completion for %@", request.sizedKey);
		NSParameterAssert(request.completionHandler);
		request.completionHandler(image, error);
	}
	[requestsMappedBySize removeObjectForKey:sizedKey];
	// If there are no more requests in this size, we can remove this container
	if ([requestsMappedBySize count] == 0)
	{
		ImageCacheLog(@"Removing requests storage for %@", primaryKey);
		[self.requests removeObjectForKey:primaryKey];
	}
}

- (void)handleScalingOperation:(KATGImageScalingOperation *)op request:(KATGImageCacheRequest *)request
{
	// Having a scaled image indicates success
	if (op.scaledImage)
	{
		ImageCacheLog(@"Done scaling %@", request.sizedKey);
		// Bounce onto the work queue
		[self.workQueue addOperationWithBlock:^{
			// Write out to disk
#if !defined(NS_BLOCK_ASSERTIONS)
			BOOL success = 
#endif
			[self writeImage:op.scaledImage key:request.sizedKey];
			NSParameterAssert(success);
			ImageCacheLog(@"Wrote %@ to disk", request.sizedKey);
			// Put the scaled image into the memory cache
			self[request.sizedKey] = op.scaledImage;
			// Bounce to sync queue to notify and cleanup
			[self.syncQueue addOperationWithBlock:^{
				ImageCacheLog(@"Calling completion handlers after scaling %@", request.sizedKey);
				// Call any request completion handlers for our newly scaled image
				[self callCompletionHandlers:op.scaledImage error:nil primaryKey:request.primaryKey sizedKey:request.sizedKey];
				// Cleanup active scaling ops
				[self.activeScalingOperations removeObjectForKey:request.sizedKey];
				ImageCacheLog(@"Checking for requests to fullfill after scaling %@", request.sizedKey);
				// Call fullfill to empty any image requests that have shown up during scaling
				[self fullfillRequests:op.image error:nil primaryKey:request.primaryKey];
			}];
		}];
	}
	else
	{
		NSError *error = [NSError errorWithDomain:KATGImageCacheErrorDomain code:KATGImageCacheErrorCodeScalingFailed userInfo:nil];
		[self callCompletionHandlers:nil error:error primaryKey:request.primaryKey sizedKey:request.sizedKey];
	}
}

- (void)fullfillRequests:(UIImage *)image error:(NSError *)error primaryKey:(NSString *)primaryKey
{
	NSParameterAssert(primaryKey);
	if (image == nil && error == nil)
	{
		error = [NSError errorWithDomain:KATGImageCacheErrorDomain code:KATGImageCacheErrorCodeCorruptImageData userInfo:nil];
	}
	// Bounce to our serial queue 
	[self.syncQueue addOperationWithBlock:^{
		CGSize size = [image size];
		NSDictionary *requestsMappedBySize = self.requests[primaryKey];
		for (NSArray *requestsForSize in [[requestsMappedBySize allValues] copy]) 
		{
			NSParameterAssert([requestsForSize count]);
			KATGImageCacheRequest *request = requestsForSize[0];
			bool sizeIsZero = CGSizeEqualToSize(request.size, CGSizeZero);
			// CGSizeZero indicates that no scaling should occur
			if (!image || sizeIsZero || CGSizeEqualToSize(size, request.size))
			{
				ImageCacheLog(@"image is already the right size, calling completion handlers %@", request.sizedKey);
				// TODO: if image is already the right size or CGSizeZero is passed, just copy full into place
				[self callCompletionHandlers:image error:error primaryKey:primaryKey sizedKey:request.sizedKey];
			}
			else
			{
				[self queueScalingOp:image request:request];
			}
		}
		// Once our request queue empties, we can clear out active image connections
		if ([self.requests[primaryKey] count] == 0)
		{
			ImageCacheLog(@"Clearing out active connections for %@", primaryKey);
			[self.activeImageConnections removeObjectForKey:primaryKey];
		}
	}];
}

#pragma mark - Public API

- (void)imageForURL:(NSURL *)url size:(CGSize)size progressHandler:(void (^)(float))progressHandler completionHandler:(void (^)(UIImage *, NSError *))completionHandler
{
	ImageCacheLog(@"Request image for %@", url);
	// No completion handler, no dice
	NSParameterAssert(completionHandler);
	// No url, no dice
	if (url == nil)
	{
		NSParameterAssert(NO);
		completionHandler(nil, [NSError errorWithDomain:KATGImageCacheErrorDomain code:0 userInfo:nil]);
		return;
	}
	// Don't do squat on the main thread (we could be on any thread, but we're probably on the main thread)
	[self.workQueue addOperationWithBlock:^{
		KATGImageCacheRequest *imageRequest = [self newRequestForURL:url size:size];
		ImageCacheLog(@"URL %@ maps to %@", url, imageRequest.sizedKey);
		imageRequest.progressHandler = progressHandler;
		imageRequest.completionHandler = completionHandler;
		// See if an already scaled image is already in the memory cache
		UIImage *imageFromMemoryCache = self[imageRequest.sizedKey];
		if (imageFromMemoryCache)
		{
			ImageCacheLog(@"%@ from memory", imageRequest.sizedKey);
			if (progressHandler)
			{
				progressHandler(1.0);
			}
			completionHandler(imageFromMemoryCache, nil);
			return;
		}
		NSError *error;
		UIImage *sizedImageFromDisk = [self tryToLoadImageData:imageRequest.sizedKey extension:nil error:&error];
		if (sizedImageFromDisk)
		{
			ImageCacheLog(@"Read %@ from disk", imageRequest.sizedKey);
			if (progressHandler)
			{
				progressHandler(1.0);
			}
			self[imageRequest.sizedKey] = sizedImageFromDisk;
			completionHandler(sizedImageFromDisk, nil);
			return;
		}
		UIImage *fullImageFromDisk = [self tryToLoadImageData:imageRequest.primaryKey extension:nil error:&error];
		if (fullImageFromDisk)
		{
			ImageCacheLog(@"Read full image from disk %@", imageRequest.sizedKey);
			// TODO: if image is already the right size or CGSizeZero is passed, just copy full into place
			if (CGSizeEqualToSize(CGSizeZero, imageRequest.size))
			{
				if (progressHandler)
				{
					progressHandler(1.0);
				}
				completionHandler(fullImageFromDisk, nil);
			}
			else
			{
				ImageCacheLog(@"Queueing scaling %@", imageRequest.sizedKey);
				[self.syncQueue addOperationWithBlock:^{
					// Store the image request so we can use it to queue up scaling ops and to call completion handlers
					// This only works because we funnel interactions with activeImageConnections and completionHandlers through syncQueue
					[self storeRequest:imageRequest];
					// Actually queue the scaling op
					[self queueScalingOp:fullImageFromDisk request:imageRequest];
				}];
			}
			return;
		}
		// Before we can interrogate active network or image operations, we have to be on the sync queue
		[self.syncQueue addOperationWithBlock:^{
			// Store the image request so we can use it to queue up scaling ops and to call completion handlers
			// This only works because we funnel interactions with activeImageConnections and completionHandlers through syncQueue
			[self storeRequest:imageRequest];
			// See if we're already fetching the image
			ESHTTPOperation *op = self.activeImageConnections[imageRequest.primaryKey];
			op.queuePriority = NSOperationQueuePriorityHigh;
			if (!op)
			{
				// TODO: need to call all the progress handlers, not just the one from the request that triggered the network call
				ImageCacheLog(@"Downloading %@", imageRequest.sizedKey);
				NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
				op = [ESHTTPOperation newHTTPOperationWithRequest:request work:^id<NSObject>(ESHTTPOperation *op, NSError *__autoreleasing *error) {
					return [self handleImageData:op.responseBody size:size key:imageRequest.primaryKey sizedKey:imageRequest.sizedKey error:error];
				} completion:^(ESHTTPOperation *op) {
					ImageCacheLog(@"Done downloading %@", imageRequest.sizedKey);
					[self fullfillRequests:op.processedResponse error:op.error primaryKey:imageRequest.primaryKey];
				}];
				[op setDownloadProgressBlock:^(NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead) {
					if (imageRequest.progressHandler)
					{
						float progress = (((float)totalBytesRead/(float)totalBytesExpectedToRead)*0.9f);
						imageRequest.progressHandler(progress);
					}
				}];
				self.activeImageConnections[imageRequest.primaryKey] = op;
				op.queuePriority = NSOperationQueuePriorityHigh;
				op.workQueue = self.workQueue;
				[self.networkQueue addOperation:op];
			}
		}];
	}];
}

- (void)requestImages:(id<NSFastEnumeration>)urlStrings size:(CGSize)size
{
	NSArray *ops = [[self.activeImageConnections allValues] copy];
	for (ESHTTPOperation *op in ops)
	{
		op.queuePriority = NSOperationQueuePriorityNormal;
	}
	for (NSString *urlString in urlStrings)
	{
		if (urlString == (id)[NSNull null])
		{
			continue;
		}
		NSParameterAssert([urlString isKindOfClass:[NSString class]]);
		NSURL *url = [NSURL URLWithString:urlString];
		if (url)
		{
			[self imageForURL:url size:size progressHandler:nil completionHandler:^(UIImage *image, NSError *error) {
				
			}];
		}
		else
		{
			NSParameterAssert(NO);
		}
	}
}

@end

@implementation KATGImageCacheRequest

@end
