//
//  KATGEpisodeStore.h
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

// Completion / error blocks are NOT GUARANTEED TO RUN ON THE MAIN THREAD.
// If they need to update the UI, dispatch back to the main queue.

#import <Foundation/Foundation.h>

@class KATGShow, KATGGuest;

extern NSString * const KATGDataStoreConnectivityRestoredNotification;
extern NSString * const KATGDataStoreConnectivityFailureNotification;

@protocol KATGDownloadToken <NSObject>
@property (nonatomic) CGFloat progress;
@property (copy, nonatomic) void (^progressBlock)(CGFloat progress);
@property (copy, nonatomic) void (^completionBlock)(NSError *error);
- (BOOL)isCancelled;
- (void)cancel;
@end

@interface KATGDataStore : NSObject

+ (KATGDataStore *)sharedStore;

// Observable
extern NSString *const kKATGDataStoreIsReachableViaWifiKey;
- (BOOL)isReachableViaWifi;

// This is an indicator that as of the last check in with the server,
// the show is believed to be live. It is not a guarantee that
// the streaming server is live or that the show hasn't
// ended since the last check in
// Observable
extern NSString *const kKATGDataStoreIsShowLiveKey;
// And notifications on change
extern NSString *const KATGDataStoreIsShowLiveDidChangeNotification;
- (BOOL)isShowLive;

// Events updated
// This shouldn't be needed, but working around an occasional failure on first load for now
extern NSString *const KATGDataStoreEventsDidChangeNotification;

// Main thread only reader context
@property (strong, nonatomic, readonly) NSManagedObjectContext *readerContext;

// Private queue context safe for writing
- (NSManagedObjectContext *)childContext;

// Synchronous save that expects to be called from the contexts private queue (i.e. from within a perform block or on the main queue for the reader context)
- (void)saveContext:(NSManagedObjectContext *)context completion:(void (^)(NSError *error))completion;

// Async save that also saves reader and then writer contexts
- (void)saveChildContext:(NSManagedObjectContext *)context completion:(void (^)(NSError *error))completion;

// Fetch episodes
- (void)downloadAllEpisodes;

// 
- (void)downloadEpisodeDetails:(NSNumber *)episodeID;

//
- (id<KATGDownloadToken>)activeEpisodeAudioDownload:(KATGShow *)show;

//
- (id<KATGDownloadToken>)downloadEpisodeAudio:(KATGShow *)show progress:(void (^)(CGFloat progress))progress completion:(void (^)(NSError *error))completion;

//
- (void)downloadEvents;

//
- (void)submitFeedback:(NSString *)name location:(NSString *)location comment:(NSString *)comment completion:(void (^)(NSError *))completion;

@end
