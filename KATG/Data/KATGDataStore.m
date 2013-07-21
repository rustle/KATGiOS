//
//  KATGEpisodeStore.m
//  KATG
//
//  Created by Timothy Donnelly on 12/5/12.
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

#import "KATGDataStore.h"
#import "KATGDataStore_Internal.h"

#import "KATGShow.h"
#import "KATGGuest.h"
#import "KATGImage.h"
#import "KATGScheduledEvent.h"

#import "ESHTTPOperation.h"
#import "ESJSONOperation.h"

#import "KATGDownloadOperation.h"
#import "KATGDownloadToken.h"

#import "Reachability.h"
#import "KATGReachabilityOperation.h"

#import "NSMutableURLRequest+ESNetworking.h"

#if DEBUG && 0
#define EventsLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define EventsLog(fmt, ...) 
#endif //DEBUG

#if DEBUG && 0
#define ShowsLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define ShowsLog(fmt, ...) 
#endif //DEBUG

#if DEBUG && 0
#define CoreDataLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define CoreDataLog(fmt, ...) 
#endif //DEBUG

#if DEBUG && 0
#define EpisodeAudioLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define EpisodeAudioLog(fmt, ...) 
#endif //DEBUG

NSString *const kKATGDataStoreIsReachableViaWifiKey = @"isReachableViaWifi";

NSString * const KATGDataStoreConnectivityRestoredNotification = @"KATGDataStoreConnectivityRestoredNotification";
NSString * const KATGDataStoreConnectivityFailureNotification = @"KATGDataStoreConnectivityFailureNotification";

NSString *const KATGDataStoreIsShowLiveDidChangeNotification = @"KATGDataStoreIsShowLiveDidChangeNotification";
NSString *const kKATGDataStoreIsShowLiveKey = @"isShowLive";

NSString *const KATGDataStoreEventsDidChangeNotification = @"KATGDataStoreEventsDidChangeNotification";

@interface KATGDataStore ()

// General Core Data
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSManagedObjectContext *writerContext;
@property (nonatomic) NSManagedObjectContext *readerContext;

// Base URL
@property (nonatomic) NSURL *baseURL;

// Polling timer
@property (nonatomic) NSTimer *timer;

// Download tracking
@property (nonatomic) NSMutableDictionary *urlToTokenMap;

// Reachability
@property (nonatomic) Reachability *reachabilityForConnectionType;
@property (nonatomic, getter=isReachableViaWifi) BOOL reachableViaWifi;
@property (nonatomic) KATGReachabilityOperation *reachabilityOp;

//
@property (nonatomic) BOOL live;

@end

@implementation KATGDataStore

+ (KATGDataStore *)sharedStore
{
	static KATGDataStore *sharedStore = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedStore = [[self class] new];
	});
	return sharedStore;
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		[self coreDataInitialize];
		
		// Build queues for network and core data operations.
		_networkQueue = [NSOperationQueue new];
		[_networkQueue setMaxConcurrentOperationCount:10];
		
		_workQueue = [NSOperationQueue new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate:) name:UIApplicationWillTerminateNotification object:nil];
		
		_baseURL = [NSURL URLWithString:kServerBaseURL];
		
		_urlToTokenMap = [NSMutableDictionary new];
		
		_reachabilityForConnectionType = [Reachability reachabilityWithHostName:kReachabilityURL];
		NSParameterAssert(_reachabilityForConnectionType);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:_reachabilityForConnectionType];
		[_reachabilityForConnectionType startNotifier];
		
		[self startPolling];
	}
	return self;
}

#pragma mark - Core Data Stack

- (void)coreDataInitialize
{
	_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
	
	NSURL *url = [self storeURL];
	
	// nuke the database on every launch
//	[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
	
	NSError *error = nil;
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{
		// Error adding persistent store
		[NSException raise:@"Could not add persistent store" format:@"%@", [error localizedDescription]];
	}
	else
	{
		[[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:[url path] error:nil];
	}
	
	_writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	_writerContext.persistentStoreCoordinator = _persistentStoreCoordinator;
	
	_readerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	_readerContext.parentContext = _writerContext;
}

- (NSURL *)storeURL
{
	NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	return [directoryURL URLByAppendingPathComponent:@"katg2.sqlite"];
}

- (NSManagedObjectContext *)childContext
{
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.parentContext = self.readerContext;
	return context;
}

- (void)saveContext:(NSManagedObjectContext *)context completion:(void (^)(NSError *error))completion
{
	CoreDataLog(@"Save Context: %@", context);
	NSError *error;
	if (![context save:&error])
	{
		CoreDataLog(@"Core Data Error: %@", error);
	}
	else
	{
		error = nil;
	}
	if (completion)
	{
		completion(error);
	}
}

- (void)saveChildContext:(NSManagedObjectContext *)context completion:(void (^)(NSError *error))completion
{
	[self saveContext:context completion:^(NSError *childError) {
		if (childError)
		{
			if (completion)
			{
				completion(childError);
			}
		}
		else
		{
			[self.readerContext performBlock:^{
				[self saveContext:self.readerContext completion:^(NSError *readerError) {
					if (readerError)
					{
						if (completion)
						{
							completion(readerError);
						}
					}
					else
					{
						[self.writerContext performBlock:^{
							[self saveContext:self.writerContext completion:^(NSError *writerError) {
								if (completion)
								{
									completion(writerError);
								}
							}];
						}];
					}
				}];
			}];
		}
	}];
}

#pragma mark - 

- (void)willTerminate:(NSNotification *)notification
{
	NSManagedObjectContext *context = self.writerContext;
	[context performBlockAndWait:^{
		[self saveContext:context completion:nil];
	}];
}

#pragma mark - 

- (void)reachabilityChanged:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	NSParameterAssert([[note object] isEqual:self.reachabilityForConnectionType]);
	self.reachableViaWifi = [self.reachabilityForConnectionType isReachableViaWiFi];
}

+ (BOOL)automaticallyNotifiesObserversOfReachableViaWifi
{
	return NO;
}

- (void)setReachableViaWifi:(BOOL)reachableViaWifi
{
	if (_reachableViaWifi != reachableViaWifi)
	{
		[self willChangeValueForKey:kKATGDataStoreIsReachableViaWifiKey];
		_reachableViaWifi = reachableViaWifi;
		[self didChangeValueForKey:kKATGDataStoreIsReachableViaWifiKey];
	}
}

#pragma mark - Request from server

- (void)startPolling
{
	self.timer = [NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(pollForData:) userInfo:nil repeats:YES];
	[self.timer fire];
}

- (void)stopPolling
{
	[self.timer invalidate];
	self.timer = nil;
}

- (void)pollForData:(NSTimer *)timer
{
	[self pollForData];
}

- (void)pollForData
{
	[self downloadAllEpisodes];
	[self downloadEvents];
	[self checkLive];
}

- (void)downloadAllEpisodes
{
	//	Retrieve list of shows
	NSURL *url = [NSURL URLWithString:kShowListURIAddress relativeToURL:self.baseURL];
	NSParameterAssert(url);
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	ShowsLog(@"Download Shows");
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request
															   success:^(ESJSONOperation *op, NSArray *JSON) {
																   NSParameterAssert([JSON isKindOfClass:[NSArray class]]);
																   NSParameterAssert(([JSON count] > 0));
																   if ([JSON count] > 0)
																   {
																	   [self processEpisodeList:JSON];
																   }
															   } failure:^(ESJSONOperation *op) {
																   ShowsLog(@"Shows Download Failed %@", op.error);
																   [self handleError:op.error];
															   }];
	[self.networkQueue addOperation:op];
}

- (void)downloadEpisodeDetails:(NSNumber *)episodeID
{
	if (!episodeID)
	{
		NSParameterAssert(NO);
		return;
	}
	NSURL *url = [NSURL URLWithString:[kServerBaseURL stringByAppendingPathComponent:[NSString stringWithFormat:kShowDetailsURIAddress, episodeID]]];
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request
															   success:^(ESJSONOperation *op, NSDictionary *JSON) {
																   NSParameterAssert([JSON isKindOfClass:[NSDictionary class]]);
																   [self processEpisodeDetails:JSON episodeID:episodeID];
															   } failure:^(ESJSONOperation *op) {
																   ShowsLog(@"Shows Details Download Failed %@", op.error);
																   [self handleError:op.error];
															   }];
	[self.networkQueue addOperation:op];
}

- (NSURL *)fileURLForEpisodeID:(NSNumber *)episodeID
{
	NSParameterAssert(episodeID);
	NSString *fileName = [NSString stringWithFormat:@"%@", episodeID];
	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	url = [url URLByAppendingPathComponent:@"Media"];
	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir])
	{
		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:NO attributes:nil error:nil])
		{
			NSLog(@"%@", error);
			return nil;
		}
	}
	else
	{
		NSParameterAssert(isDir);
	}
	url = [url URLByAppendingPathComponent:fileName];
	return url;
}

- (id<KATGDownloadToken>)activeEpisodeAudioDownload:(KATGShow *)show
{
	NSString *mediaURL = show.media_url;
	EpisodeAudioLog(@"Check for download of %@", show.media_url);
	if (mediaURL == nil)
	{
		NSParameterAssert(NO);
		return nil;
	}
	NSURL *url = [NSURL URLWithString:mediaURL];
	if (url == nil)
	{
		NSParameterAssert(NO);
		return nil;
	}
	KATGDownloadToken *token = self.urlToTokenMap[url];
	return token;
}

- (id<KATGDownloadToken>)downloadEpisodeAudio:(KATGShow *)show progress:(void (^)(CGFloat progress))progress completion:(void (^)(NSError *error))completion
{
	NSString *mediaURL = show.media_url;
	if (mediaURL == nil)
	{
		NSParameterAssert(NO);
		return nil;
	}
	NSURL *url = [NSURL URLWithString:mediaURL];
	if (url == nil)
	{
		NSParameterAssert(NO);
		return nil;
	}
	__block KATGDownloadToken *token = self.urlToTokenMap[url];
	if (token)
	{
		token.progressBlock = progress;
		token.completionBlock = completion;
		EpisodeAudioLog(@"Already downloading %@", show.media_url);
		return token;
	}
	EpisodeAudioLog(@"Download %@", show.media_url);
	NSNumber *episodeID = show.episode_id;
	NSParameterAssert(episodeID);
	NSURL *fileURL = [[self fileURLForEpisodeID:episodeID] URLByAppendingPathExtension:[url pathExtension]];
	void (^finishWithError)(NSError *) = ^(NSError *error) {
		if (error)
		{
			[self handleError:error];
		}
		[token callCompletionBlockWithError:error];
		[self.urlToTokenMap removeObjectForKey:url];
	};
	KATGDownloadOperation *op = [KATGDownloadOperation newDownloadOperationWithRemoteURL:url fileURL:fileURL completion:^(ESHTTPOperation *op) {
		if (op.error)
		{
			finishWithError(op.error);
		}
		else
		{
			[[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:[fileURL path] error:nil];
			NSManagedObjectContext *context = [self childContext];
			NSParameterAssert(context);
			[context performBlock:^{
				KATGShow *fetchedShow = [self fetchShowWithID:episodeID context:context];
				if (fetchedShow)
				{
					fetchedShow.downloaded = @YES;
					fetchedShow.file_url = [fileURL path];
					[self saveChildContext:context completion:^(NSError *saveError) {
						CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
							if (saveError)
							{
								EpisodeAudioLog(@"Core Data Error %@", saveError);
							}
							finishWithError(saveError);
						});
					}];
				}
			}];
		}
	}];
	if (progress)
	{
		[op setDownloadProgressBlock:^(NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead) {
			CGFloat progress = (CGFloat)totalBytesRead/(CGFloat)totalBytesExpectedToRead;
			progress = floorf(progress * 100.0f) / 100.0f;
			[token callProgressBlockWithProgress:progress];
		}];
	}
	token = [[KATGDownloadToken alloc] initWithOperation:op];
	NSParameterAssert(token);
	token.progressBlock = progress;
	token.completionBlock = completion;
	self.urlToTokenMap[url] = token;
	[self.networkQueue addOperation:op];
	return token;
}

- (void)downloadEvents
{
	EventsLog(@"Download Events");
	NSURL *url = [NSURL URLWithString:kUpcomingURIAddress relativeToURL:self.baseURL];
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	id success = ^(ESJSONOperation *op, id JSON) {
		NSParameterAssert([JSON isKindOfClass:[NSDictionary class]]);
		NSParameterAssert(([(NSDictionary *)JSON count] > 0));
		[self processEvents:[(NSDictionary *)JSON objectForKey:@"events"]];
	};
	id failure = ^(ESJSONOperation *op) {
		[self handleError:op.error];
	};
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSParameterAssert(request);
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request success:success failure:failure];
	NSParameterAssert(op);
	[self.networkQueue addOperation:op];
}

- (void)handleError:(NSError *)error
{
	NSParameterAssert(error);
	if ([[error domain] isEqualToString:NSURLErrorDomain])
	{
		switch ([error code]) {
			case NSURLErrorNotConnectedToInternet:
			{
				if (self.reachabilityOp)
				{
					return;
				}
				[self stopPolling];
				self.reachabilityOp = [[KATGReachabilityOperation alloc] initWithHost:kReachabilityURL];
				NSParameterAssert(self.reachabilityOp);
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityRestored:) name:kKATGReachabilityIsReachableNotification object:nil];
				// For now, just start the op manually since the network op preflight logic only expects ESHTTPOperation subclasses
				[self.reachabilityOp start];
				[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreConnectivityFailureNotification object:nil];
				break;
			}
			default:
				break;
		}
	}
}

- (void)reachabilityRestored:(NSNotification *)note
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self startPolling];
		[self downloadAllEpisodes];
		[self downloadEvents];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kKATGReachabilityIsReachableNotification object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreConnectivityRestoredNotification object:nil];
	});
}

- (bool)networkOperationPreflight:(NSURL *)url
{
	for (ESHTTPOperation *operation in [[self.networkQueue operations] copy])
	{
		if ([operation isFinished] || [operation isCancelled])
			continue;
		
		if ([[operation.URL absoluteString] isEqualToString:[url absoluteString]])
		{
			return false;
		}
	}
	return true;
}

#pragma mark - Parse incoming data

- (void)processEpisodeList:(NSArray *)shows
{
	NSManagedObjectContext *context = [self childContext];
	[context performBlock:^{
		@autoreleasepool {
			NSMutableSet *showObjectIDs = [NSMutableSet new];
			for (NSDictionary *showDictionary in shows)
			{
				NSManagedObjectID *showObjectID = [self insertOrUpdateShow:showDictionary context:context];
				if (showObjectID)
				{
					[showObjectIDs addObject:showObjectID];
				}
			}
			ShowsLog(@"Processed %ld show", (long)[showObjectIDs count]);
			[self deleteOldEpisodes:showObjectIDs context:context];
			[self saveChildContext:context completion:nil];
		}
	}];
}

- (void)processEpisodeDetails:(NSDictionary *)episodeDetails episodeID:(NSNumber *)episodeID
{
	if (!episodeDetails)
	{
		NSParameterAssert(episodeDetails);
		return;
	}
	if (!episodeID)
	{
		NSParameterAssert(episodeID);
		return;
	}
	NSManagedObjectContext *context = [self childContext];
	[context performBlock:^{
		@autoreleasepool {
			KATGShow *show = [self fetchShowWithID:episodeID context:context];
			if (!show)
			{
				return;
			}
			NSArray *images = episodeDetails[@"images"];
			NSUInteger index = 0;
			for (NSDictionary *imageDictionary in images)
			{
				KATGImage *image = [self fetchOrInsertImageWithShow:show url:imageDictionary[@"media_url"] context:context];
				if (image)
				{
					image.index = @(index);
					index++;
					[image configureWithDictionary:imageDictionary];
				}
			}
			NSString *notes = episodeDetails[@"notes"];
			NSMutableString *noteLines = [NSMutableString new];
			[notes enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
				// Make sure the line isn't just whitespace
				NSMutableString *mutableLine = [line mutableCopy];
				CFStringTrimWhitespace((__bridge CFMutableStringRef)mutableLine);
				if ([mutableLine length])
				{
					[noteLines appendFormat:@" • %@\n", line];
				}
			}];
			if ([noteLines length])
			{
				[noteLines deleteCharactersInRange:NSMakeRange([noteLines length] - 1, 1)];
				show.desc = [noteLines copy];
			}
			[self saveChildContext:context completion:nil];
		}
	}];
}

- (void)processEvents:(NSArray *)eventDictionaries
{
	if (![eventDictionaries count]) 
	{
		NSParameterAssert(NO);
		return;
	}
	NSManagedObjectContext *context = [self childContext];
	[context performBlock:^{
		@autoreleasepool {
			NSMutableSet *newEvents = [NSMutableSet new];
			for (NSDictionary *eventDictionary in eventDictionaries)
			{
				KATGScheduledEvent *event = [self fetchOrInsertEventWithID:eventDictionary[@"eventid"] context:context];
				if (event)
				{
					[event configureWithDictionary:eventDictionary];
					if ([event futureTest])
					{
						[newEvents addObject:[event objectID]];
					}
					else
					{
						[context deleteObject:event];
					}
				}
			}
			EventsLog(@"Processed %ld events", (unsigned long)[newEvents count]);
			[self deleteOldEvents:newEvents context:context];
			[self saveChildContext:context completion:^(NSError *error) {
				if (error)
				{
					[self handleError:error];
				}
				else
				{
					CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
						[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreEventsDidChangeNotification object:nil];
					});
				}
			}];
		}
	}];
}

#pragma mark - Shows

- (NSManagedObjectID *)insertOrUpdateShow:(NSDictionary *)showDictionary context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!showDictionary)
	{
		NSParameterAssert(showDictionary);
		return nil;
	}
	KATGShow *show = [self fetchOrInsertShowWithID:[KATGShow episodeIDForShowDictionary:showDictionary] context:context];
	NSParameterAssert(show);
	if (show)
	{
		[show configureWithDictionary:showDictionary];
		[self insertOrUpdateGuests:show showDictionary:showDictionary context:context];
	}
	return [show objectID];
}

- (KATGShow *)fetchOrInsertShowWithID:(NSNumber *)episodeID context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!episodeID)
	{
		NSParameterAssert(episodeID);
		return nil;
	}
	KATGShow *show = [self fetchShowWithID:episodeID context:context];
	if (!show)
	{
		show = [NSEntityDescription insertNewObjectForEntityForName:[KATGShow katg_entityName] inManagedObjectContext:context];
		show.episode_id = episodeID;
	}
	NSParameterAssert(show);
	return show;
}

- (KATGShow *)fetchShowWithID:(NSNumber *)episodeID context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!episodeID)
	{
		NSParameterAssert(episodeID);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGShow katg_entityName] inManagedObjectContext:context];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGShowEpisodeIDAttributeName, episodeID];
	NSError *error;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	NSParameterAssert([result count] < 2);
	return [result lastObject];
}

- (void)deleteOldEpisodes:(NSSet *)currentShowObjectIDs context:(NSManagedObjectContext *)context
{
	NSParameterAssert(currentShowObjectIDs);
	NSParameterAssert(context);
	if (![currentShowObjectIDs count])
	{
		return;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGShow katg_entityName] inManagedObjectContext:context];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", currentShowObjectIDs];
	NSError *error;
	NSArray *result = [context executeFetchRequest:request error:&error];
	ShowsLog(@"Deleting %ld shows", (long)[result count]);
	for (KATGShow *show in result)
	{
		if (show.file_url)
		{
			[[NSFileManager defaultManager] removeItemAtPath:show.file_url error:nil];
		}
		[context deleteObject:show];
	}
}

#pragma mark - Guests

- (void)insertOrUpdateGuests:(KATGShow *)show showDictionary:(NSDictionary *)showDictionary context:(NSManagedObjectContext *)context
{
	if (!show)
	{
		NSParameterAssert(show);
		return;
	}
	if (!showDictionary)
	{
		NSParameterAssert(showDictionary);
		return;
	}
	NSArray *guests = [KATGShow guestDictionariesForShowDictionary:showDictionary];
	NSParameterAssert(guests);
	for (NSDictionary *guestDict in guests)
	{
		KATGGuest *guest = [self fetchOrInsertGuestWithID:[KATGGuest guestIDForGuestDictionary:guestDict] context:context];
		NSParameterAssert(guest);
		if (guest)
		{
			[guest configureWithDictionary:guestDict];
			[guest addShowsObject:show];
			[show addGuestsObject:guest];
		}
	}
}

- (KATGGuest *)fetchOrInsertGuestWithID:(NSNumber *)guestID context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!guestID)
	{
		NSParameterAssert(guestID);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGGuest katg_entityName] inManagedObjectContext:context];
	request.entity = entity;	
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGGuestGuestIDAttributeName, guestID];
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	if ([result count])
	{
		return result[0];
	}
	// Does not exist, create it
	KATGGuest *guest = [NSEntityDescription insertNewObjectForEntityForName:[KATGGuest katg_entityName] inManagedObjectContext:context];
	guest.guest_id = guestID;
	return guest;
}

#pragma mark - Images

- (KATGImage *)fetchOrInsertImageWithShow:(KATGShow *)show url:(NSString *)url context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!show)
	{
		NSParameterAssert(show);
		return nil;
	}
	if (!url)
	{
		NSParameterAssert(url);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGImage katg_entityName] inManagedObjectContext:context];
	request.entity = entity;	
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGImageMediaURLAttributeName, url];
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	if ([result count])
	{
		return result[0];
	}
	// Does not exist, create it
	KATGImage *image = [NSEntityDescription insertNewObjectForEntityForName:[KATGImage katg_entityName] inManagedObjectContext:context];
	NSParameterAssert(image);
	image.show = show;
	[show addImagesObject:image];
	return image;
}

#pragma mark - Events

- (KATGScheduledEvent *)fetchOrInsertEventWithID:(NSString *)eventid context:(NSManagedObjectContext *)context
{
	if (!eventid)
	{
		NSParameterAssert(eventid);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:context];
	request.entity = entity;	
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGScheduledEventEventIDAttributeName, eventid];
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	if ([result count])
	{
		return result[0];
	}
	// Does not exist, create it
	KATGScheduledEvent *event = [NSEntityDescription insertNewObjectForEntityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:context];
	NSParameterAssert(event); 
	event.eventid = eventid;
	return event;
}

- (void)deleteOldEvents:(NSSet *)currentEventsObjectIDs context:(NSManagedObjectContext *)context
{
	NSParameterAssert(currentEventsObjectIDs);
	if (![currentEventsObjectIDs count])
	{
		return;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:context];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", currentEventsObjectIDs];
	NSError *error;
	NSArray *result = [context executeFetchRequest:request error:&error];
	EventsLog(@"Deleting %ld events", (unsigned long)[result count]);
	for (KATGScheduledEvent *event in result)
	{
		[context deleteObject:event];
	}
}

#pragma mark - Live

// Observable
- (BOOL)isShowLive
{
	return self.live;
}

- (void)setLive:(BOOL)live
{
	NSParameterAssert([NSThread isMainThread]);
	if (_live != live)
	{
		[self willChangeValueForKey:kKATGDataStoreIsShowLiveKey];
		_live = live;
		[self didChangeValueForKey:kKATGDataStoreIsShowLiveKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreIsShowLiveDidChangeNotification object:nil];
	}
}

- (void)checkLive
{
	// See if show is live
	NSURL *url = [NSURL URLWithString:kLiveShowStatusURIAddress relativeToURL:self.baseURL];
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request
															   success:^(ESJSONOperation *op, NSDictionary *JSON) {
																   NSParameterAssert([JSON isKindOfClass:[NSDictionary class]]);
																   BOOL live = [JSON[@"broadcasting"] boolValue];
																   dispatch_async(dispatch_get_main_queue(), ^(void) {
																	   self.live = live;
																   });
															   } failure:^(ESJSONOperation *op) {
																   [self handleError:op.error];
															   }];
	NSParameterAssert(op);
	[self.networkQueue addOperation:op];
}

#pragma mark - Feedback

- (void)submitFeedback:(NSString *)name location:(NSString *)location comment:(NSString *)comment completion:(void (^)(NSError *))completion
{
	if (![comment length])
	{
		if (completion)
		{
			completion([NSError errorWithDomain:@"KATGFeedbackErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Invalid input", nil)}]);
		}
		return;
	}
	if (name == nil)
	{
		name = @"";
	}
	if (location == nil)
	{
		location = @"";
	}
	NSURL *url = [NSURL URLWithString:kFeedbackURL];
	NSParameterAssert(url);
	// No preflight check since all feedback submissions will have the same URL
	NSMutableURLRequest *request = [NSMutableURLRequest postRequestWithURL:url body:@{@"Name" : [name copy], @"Location" : [location copy], @"Comment" : [comment copy], @"Send+Comment" : @"ButtonSubmit", @"3" : @"HiddenVoxbackId", @"IEOSE" : @"HiddenMixerCode",}];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	id networkWork = ^id<NSObject>(ESHTTPOperation *op, NSError *__autoreleasing *error) {
#if DEBUG
		NSString *responseString = [[NSString alloc] initWithData:op.responseBody encoding:NSUTF8StringEncoding];
		return responseString;
#else
		return nil;
#endif 
	};
	id networkCompletion = ^(ESHTTPOperation *op) {
		if (op.error)
		{
			if (completion)
			{
				completion(op.error);
			}
		}
		else
		{
			if (completion)
			{
				completion(nil);
			}
		}
	};
	ESHTTPOperation *op = [ESHTTPOperation newHTTPOperationWithRequest:request work:networkWork completion:networkCompletion];
	NSParameterAssert(op);
	[self.networkQueue addOperation:op];
}

@end
