//
//  KATGPlaybackManager.m
//  KATG
//
//  Created by Timothy Donnelly on 12/13/12.
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

#import "KATGPlaybackManager.h"
#import "KATGShow.h"
#import "KATGAudioPlayerController.h"
#import "KATGDataStore.h"
#import "KATGAudioSessionManager.h"
#import <MediaPlayer/MediaPlayer.h>

NSString *const KATGLiveShowStreamingServerOfflineNotification = @"KATGLiveShowStreamingServerOfflineNotification";

@interface KATGPlaybackManager () <KATGAudioPlayerControllerDelegate>
@property (nonatomic) KATGAudioPlayerController *audioPlaybackController;
@property (nonatomic) KATGShow *currentShow;
@property (nonatomic) KATGAudioPlayerState state;
@property (nonatomic) NSTimer *saveTimer;
@property (nonatomic, getter=isLiveShow) bool liveShow;
@end

@implementation KATGPlaybackManager
@dynamic duration;
@dynamic currentTime;

#pragma mark - KeyPathsForValuesAffecting

+ (NSSet *)keyPathsForValuesAffectingCurrentTime
{
	static NSSet *set = nil;
	if (set == nil)
	{
		set = [[NSSet alloc] initWithObjects:@"audioPlaybackController.currentTime", nil];
	}
	return set;
}

+ (NSSet *)keyPathsForValuesAffectingDuration
{
	static NSSet *set = nil;
	if (set == nil)
	{
		set = [[NSSet alloc] initWithObjects:@"audioPlaybackController.duration", nil];
	}
	return set;
}

+ (NSSet *)keyPathsForValuesAffectingCurrentShow
{
	static NSSet *set = nil;
	if (set == nil)
	{
		set = [[NSSet alloc] initWithObjects:@"currentShowEpisodeID", @"currentShowID", nil];
	}
	return set;
}

#pragma mark - Setup/Cleanup

+ (instancetype)sharedManager
{
	static id sharedManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self class] new];
	});
	return sharedManager;
}

#pragma mark - Accessors

- (CMTime)currentTime
{
	return self.audioPlaybackController.currentTime;
}

- (CMTime)duration
{
	return self.audioPlaybackController.duration;
}

- (KATGAudioPlayerState)state
{
	return self.audioPlaybackController.state;
}

- (void)setAudioPlaybackController:(KATGAudioPlayerController *)audioPlaybackController
{
	if (_audioPlaybackController != audioPlaybackController)
	{
		_audioPlaybackController.delegate = nil;
		_audioPlaybackController = audioPlaybackController;
		_audioPlaybackController.delegate = self;
	}
}

- (Float64)currentTimeInSeconds
{
	Float64 time = CMTimeGetSeconds(self.currentTime);
	if (isnan(time))
	{
		time = 0.0;
	}
	return time;
}

- (Float64)durationInSeconds
{
	Float64 time = CMTimeGetSeconds(self.duration);
	if (isnan(time))
	{
		time = 0.0;
	}
	return time;
}

- (void)setCurrentShow:(KATGShow *)currentShow
{
	NSParameterAssert([NSThread isMainThread]);
	if (![[_currentShow objectID] isEqual:currentShow])
	{
		if (_currentShow)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:[_currentShow managedObjectContext]];
		}
		_currentShow = currentShow;
		if (_currentShow)
		{
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[_currentShow managedObjectContext]];
		}
	}
}

#pragma mark - Live Show

- (void)configureForLiveShow
{
	[self configureWithShow:nil];
	self.liveShow = true;
}

#pragma mark - Core Data

- (void)contextDidChange:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	NSParameterAssert(self.currentShow);
	NSDictionary *userInfo = [note userInfo];
	NSSet *deletedObjects = userInfo[NSDeletedObjectsKey];
	if ([deletedObjects containsObject:self.currentShow])
	{
		[self stop];
		NSParameterAssert(!self.currentShow);
	}
}

#pragma mark - Public API

- (void)configureWithShow:(KATGShow *)show
{
	self.audioPlaybackController = nil;
	self.currentShow = show;
	self.liveShow = false;
}

- (void)seekToTime:(CMTime)currentTime
{
	[self.audioPlaybackController seekToTime:currentTime];
}

- (void)play
{
	if (self.state == KATGAudioPlayerStatePlaying)
	{
		return;
	}
	KATGShow *currentShow = self.currentShow;
	if (!self.audioPlaybackController)
	{
		NSURL *url;
		if (self.liveShow)
		{
			//url = [NSURL URLWithString:@"http://141.217.119.35:8000/listen.pls"];
			url = [NSURL URLWithString:@"http://stream.keithandthegirl.com:8000/listen.pls"];
			//url = [NSURL URLWithString:@"http://stream.keithandthegirl.com:8000/stream/1/"];
			NSParameterAssert(url);
		}
		else if ([currentShow.downloaded boolValue] && [currentShow file_url])
		{
			url = [NSURL fileURLWithPath:currentShow.file_url];
		}
		else
		{
			url = [NSURL URLWithString:currentShow.media_url];
		}
		self.audioPlaybackController = [KATGAudioPlayerController audioPlayerWithURL:url];
	}
	[self.audioPlaybackController play];
	if (!self.liveShow)
	{
		double lastPlaybackTime = [currentShow.playState.lastPlaybackTime doubleValue];
		if (lastPlaybackTime > [self currentTimeInSeconds])
		{
			[self.audioPlaybackController seekToTime:CMTimeMake(lastPlaybackTime, 1)];
		}
		[self setPlaybackInfo:currentShow];
		[self startSaveTimer];
	}
	else
	{
		[self checkIfStreamingServerIsOffline];
	}
}

- (void)pause
{
	[self stopSaveTimer];
	[self saveCurrentTime];
	[self.audioPlaybackController pause];
}

- (void)stop
{
	[self stopSaveTimer];
	[self saveCurrentTime];
	self.currentShow = nil;
	self.audioPlaybackController = nil;
	self.state = KATGAudioPlayerStateUnknown;
	KATGConfigureAudioSessionState(KATGAudioSessionStateAmbient);
}

- (void)jumpForward
{
	[self jump:15.0];
}

- (void)jumpBackward
{
	[self jump:-15.0];
}

- (void)jump:(Float64)jump
{
	Float64 currentSeconds = [self currentTimeInSeconds] + jump;
	Float64 durationInSeconds = [self durationInSeconds];
	if (currentSeconds > durationInSeconds)
	{
		currentSeconds = durationInSeconds;
	}
	CMTime currentTime = CMTimeMakeWithSeconds(currentSeconds, 1);
	[self seekToTime:currentTime];
}

#pragma mark - KATGAudioPlayerControllerDelegate

- (void)player:(KATGAudioPlayerController *)player didChangeState:(KATGAudioPlayerState)state
{
	self.state = self.audioPlaybackController.state;
	if (state == KATGAudioPlayerStateDone)
	{
		self.audioPlaybackController = nil;
		[self saveCurrentTime];
	}
}

- (void)player:(KATGAudioPlayerController *)player didChangeDuration:(CMTime)duration
{
	[self setPlaybackInfo:self.currentShow];
}

#pragma mark - 

- (void)startSaveTimer
{
	if (self.saveTimer)
	{
		return;
	}
	self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(saveCurrentTime) userInfo:nil repeats:YES];
}

- (void)stopSaveTimer
{
	[self.saveTimer invalidate];
	self.saveTimer = nil;
}

- (void)saveCurrentTime
{
	if (!self.currentShow)
	{
		return;
	}
	KATGDataStore *store = [KATGDataStore sharedStore];
	NSManagedObjectContext *context = [store childContext];
	NSManagedObjectID *objectID = [self.currentShow objectID];
	Float64 time = [self currentTimeInSeconds];
	[context performBlock:^{
		NSError *fetchError;
		KATGShow *show = (KATGShow *)[context existingObjectWithID:objectID error:&fetchError];
		if (show)
		{
			if (show.playState == nil)
			{
				show.playState = [NSEntityDescription insertNewObjectForEntityForName:[KATGShowPlayState katg_entityName] inManagedObjectContext:context];
				show.playState.show = show;
			}
			show.playState.lastPlaybackTime = @(time);
			[store saveChildContext:context completion:nil];
		}
	}];
}

- (void)setPlaybackInfo:(KATGShow *)currentShow
{
	NSMutableDictionary *episodeInfo = [NSMutableDictionary dictionary];
	episodeInfo[MPMediaItemPropertyArtist] = @"Keith and The Girl";
	episodeInfo[MPMediaItemPropertyPodcastTitle] = @"Keith and The Girl";
	episodeInfo[MPMediaItemPropertyMediaType] = @(MPMediaTypePodcast);
	if (currentShow.title)
	{
		episodeInfo[MPMediaItemPropertyTitle] = currentShow.title;
	}
	if ([self durationInSeconds])
	{
		episodeInfo[MPMediaItemPropertyPlaybackDuration] = @([self durationInSeconds]);
	}
	if (currentShow.number)
	{
		episodeInfo[MPMediaItemPropertyAlbumTrackNumber] = currentShow.number;
	}
	UIImage *image = [UIImage imageNamed:@"iTunesArtwork"];
	if (image)
	{
		MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
		if (artwork)
		{
			episodeInfo[MPMediaItemPropertyArtwork] = artwork;
		}
	}
	[[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:episodeInfo];
}

#pragma mark - Hackey Hack

// Something screwy is going on with the shows shoutcast server that makes mpmovieplayer, avplayer 
// and quicktime x all stall forever in loading without ever failing if the show isn't online
// This will manually poke the server anytime playback is attempting to allow for teardown
// Eventually I will probably write an audioqueue based streamer to remove the need for this

- (void)checkIfStreamingServerIsOffline
{
	[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://stream.keithandthegirl.com:8000/listen.pls"]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		NSString *resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[resultString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"File"])
			{
				NSArray *components = [line componentsSeparatedByString:@"="];
				if ([components count] == 2)
				{
					NSString *urlString = components[1];
					NSURL *url = [NSURL URLWithString:urlString];
					if (url)
					{
						[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
							NSString *resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
							if ([resultString hasPrefix:@"ICY 401"])
							{
								if (self.liveShow && self.state == KATGAudioPlayerStateLoading)
								{
									[self stop];
									[[NSNotificationCenter defaultCenter] postNotificationName:KATGLiveShowStreamingServerOfflineNotification object:nil];
								}
							}
						}];
					}
				}
				*stop = YES;
			}
		}];
	}];
}

@end
