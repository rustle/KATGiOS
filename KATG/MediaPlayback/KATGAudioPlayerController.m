//
//  KATGAudioPlayerController.m
//  KATG
//
//  Created by Doug Russell on 3/17/12.
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

#import "KATGAudioPlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "KATGAudioSessionManager.h"

NSString *const KATGCurrentTimeObserverKey = @"currentTime";
NSString *const KATGDurationObserverKey = @"duration";
NSString *const KATGStateObserverKey = @"state";

static NSString *const KATGAudioPlayerStatusKeyPath = @"status";
static NSString *const KATGAudioPlayerRateKeyPath = @"rate";

static void *KATGAudioPlayerStatusObserverContext = @"StatusObserverContext";
static void *KATGAudioPlayerRateObserverContext = @"RateObserverContext";

@interface KATGAudioPlayerController ()

@property (nonatomic) AVPlayer *avPlayer;
@property (nonatomic) AVPlayerItem *avPlayerItem;

@property (nonatomic) CMTime currentTime;
@property (nonatomic) CMTime duration;

// track this so it can be removed when avplayer is recreated
@property (nonatomic) id timeObserver;
// track this so it can be removed when playback ends
@property (nonatomic) id didEndObserver;

@property (nonatomic) bool isApplicationActive;

@property (nonatomic) bool shouldSwitchToAmbientOnActive;

- (instancetype)initWithURL:(NSURL *)url;

@end

@implementation KATGAudioPlayerController

#pragma mark - Init/Dealloc

+ (instancetype)audioPlayerWithURL:(NSURL *)url
{
	return [[[self class] alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
	self = [super init];
	if (self)
	{
		_url = [url copy];
		_state = KATGAudioPlayerStateUnknown;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
		_isApplicationActive = (bool)([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
	}
	return self;
}

- (void)dealloc
{
	if (_avPlayerItem != nil)
	{
		[_avPlayerItem removeObserver:self forKeyPath:KATGAudioPlayerStatusKeyPath context:KATGAudioPlayerStatusObserverContext];
		[[NSNotificationCenter defaultCenter] removeObserver:self.didEndObserver];
	}
	if (_avPlayer != nil)
	{
		[_avPlayer removeObserver:self forKeyPath:KATGAudioPlayerRateKeyPath context:KATGAudioPlayerRateObserverContext];
		[_avPlayer setRate:0.0f];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 

- (void)willResignActive:(NSNotification *)notification
{
	self.isApplicationActive = false;
}

- (void)didBecomeActive:(NSNotification *)notification
{
	self.isApplicationActive = true;
	if (self.shouldSwitchToAmbientOnActive)
	{
		KATGConfigureAudioSessionState(KATGAudioSessionStateAmbient);
		self.shouldSwitchToAmbientOnActive = false;
	}
}

#pragma mark - Accessors

- (void)setUrl:(NSURL *)url
{
	if (_url != url)
	{
		[self.avPlayer setRate:0.0f];
		self.avPlayerItem = nil;
		self.avPlayer = nil;
		_url = url;
	}
}

+ (BOOL)automaticallyNotifiesObserversOfState
{
	return NO;
}

- (void)setState:(KATGAudioPlayerState)state
{
	if (_state != state)
	{
		_state = state;
		[self.delegate player:self didChangeState:_state];
	}
}

- (void)setAvPlayerItem:(AVPlayerItem *)avPlayerItem
{
	if (_avPlayerItem != avPlayerItem)
	{
		if (_avPlayerItem != nil)
		{
			[_avPlayerItem removeObserver:self forKeyPath:KATGAudioPlayerStatusKeyPath context:KATGAudioPlayerStatusObserverContext];

			[[NSNotificationCenter defaultCenter] removeObserver:self.didEndObserver];
			self.didEndObserver = nil;
		}
		_avPlayerItem = avPlayerItem;
		if (_avPlayerItem != nil)
		{
			[_avPlayerItem addObserver:self forKeyPath:KATGAudioPlayerStatusKeyPath options:0 context:KATGAudioPlayerStatusObserverContext];

			__weak KATGAudioPlayerController *weakSelf = self;
			self.didEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
				weakSelf.state = KATGAudioPlayerStateDone;
			}];
		}
	}
}

- (void)setAvPlayer:(AVPlayer *)avPlayer
{
	if (_avPlayer != avPlayer)
	{
		if (_avPlayer != nil)
		{
			[_avPlayer removeObserver:self forKeyPath:KATGAudioPlayerRateKeyPath context:KATGAudioPlayerRateObserverContext];
			[_avPlayer removeTimeObserver:self.timeObserver];
			[_avPlayer setRate:0.0f];
		}
		_avPlayer = avPlayer;
		if (_avPlayer != nil)
		{
			[_avPlayer addObserver:self forKeyPath:KATGAudioPlayerRateKeyPath options:0 context:KATGAudioPlayerRateObserverContext];

			__weak KATGAudioPlayerController *weakSelf = self;
			self.timeObserver = [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:nil usingBlock:^(CMTime time) {
				weakSelf.currentTime = time;
			}];
		}
		self.currentTime = CMTimeMake(0, 0);
		self.duration = CMTimeMake(0, 0);
	}
}

- (void)setDuration:(CMTime)duration
{
	if (CMTimeCompare(duration, _duration) != 0)
	{
		_duration = duration;
		[self.delegate player:self didChangeDuration:_duration];
	}
}

#pragma mark - KVO

NS_INLINE BOOL KATGFloatEqual(float A, float B)
{
	return (BOOL)(fabs(A - B) < 0.0000001);
}

- (void)updateState
{
	CGFloat rate = self.avPlayer.rate;
	AVPlayerItemStatus status = self.avPlayerItem.status;
	self.duration = self.avPlayerItem.duration;
	if (status == AVPlayerItemStatusFailed)
	{
		self.state = KATGAudioPlayerStateFailed;
		self.avPlayerItem = nil;
		self.avPlayer = nil;
		return;
	}
	if (KATGFloatEqual(rate, 0.0f))
	{
		self.state = KATGAudioPlayerStatePaused;
	}
	else if (KATGFloatEqual(rate, 1.0f))
	{
		if (status == AVPlayerItemStatusUnknown)
		{
			self.state = KATGAudioPlayerStateLoading;
		}
		else
		{
			self.state = KATGAudioPlayerStatePlaying;
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ((context == KATGAudioPlayerStatusObserverContext) ||
	    (context == KATGAudioPlayerRateObserverContext))
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateState];
		});
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Actions

- (void)play
{
	if (self.url == nil)
	{
		NSLog(@"Attempted play with nil URL");
		return;
	}
	if (self.avPlayerItem == nil)
	{
		self.avPlayerItem = [AVPlayerItem playerItemWithURL:self.url];
		if (self.avPlayerItem == nil)
		{
			NSLog(@"Failed to create avplayeritem with URL %@", self.url);
			return;
		}
	}
	if (self.avPlayer == nil)
	{
		self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
		if (self.avPlayer == nil)
		{
			NSLog(@"Failed to create avplayer with avplayeritem %@", self.avPlayerItem);
			return;
		}
	}
	self.shouldSwitchToAmbientOnActive = false;
	KATGConfigureAudioSessionState(KATGAudioSessionStatePlayback);
	[self.avPlayer play];
}

- (void)pause
{
	if (self.isApplicationActive)
	{
		KATGConfigureAudioSessionState(KATGAudioSessionStateAmbient);
	}
	else
	{
		self.shouldSwitchToAmbientOnActive = true;
	}
	[self.avPlayer pause];
}

- (void)seekToTime:(CMTime)currentTime
{
	[self.avPlayer seekToTime:currentTime];
	_currentTime = currentTime;
}

@end
