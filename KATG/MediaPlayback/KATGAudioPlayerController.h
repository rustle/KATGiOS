//
//  KATGAudioPlayerController.h
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, KATGAudioPlayerState) {
	KATGAudioPlayerStateUnknown,
	KATGAudioPlayerStateLoading,
	KATGAudioPlayerStatePaused,
	KATGAudioPlayerStatePlaying,
	KATGAudioPlayerStateFailed,
	KATGAudioPlayerStateDone,
};

@protocol KATGAudioPlayerControllerDelegate;

extern NSString * const KATGCurrentTimeObserverKey;
extern NSString * const KATGDurationObserverKey;
extern NSString * const KATGStateObserverKey;

@interface KATGAudioPlayerController : NSObject

+ (instancetype)audioPlayerWithURL:(NSURL *)url;

@property (copy, nonatomic) NSURL *url;
@property (weak, nonatomic) id<KATGAudioPlayerControllerDelegate> delegate;
@property (nonatomic) KATGAudioPlayerState state;

@property (nonatomic, readonly) CMTime currentTime;
@property (nonatomic, readonly) CMTime duration;

- (void)seekToTime:(CMTime)currentTime;
- (void)play;
- (void)pause;

@end

@protocol KATGAudioPlayerControllerDelegate <NSObject>

- (void)player:(KATGAudioPlayerController *)player didChangeState:(KATGAudioPlayerState)state;
- (void)player:(KATGAudioPlayerController *)player didChangeDuration:(CMTime)duration;

@end
