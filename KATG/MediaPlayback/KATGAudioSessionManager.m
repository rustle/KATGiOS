//
//  KATGAudioSessionManager.m
//  KATG
//
//  Created by Doug Russell on 6/2/12.
//  Copyright 2012 (c) Doug Russell. All rights reserved.
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

#import "KATGAudioSessionManager.h"
#import <AudioToolbox/AudioToolbox.h>

static void ConfigurePlaybackAudioSession(void)
{
	AudioSessionInitialize(NULL, // 'NULL' to use the default (main) run loop
						   NULL, // 'NULL' to use the default run loop mode
						   NULL, // callbacks
						   NULL); // data to pass to your interruption listener callback
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
							sizeof(sessionCategory),
							&sessionCategory);
	AudioSessionSetActive(true);
}

static void ConfigureAmbientAudioSession(void)
{
	AudioSessionInitialize(NULL, // 'NULL' to use the default (main) run loop
						   NULL, // 'NULL' to use the default run loop mode
						   NULL, // callbacks
						   NULL); // data to pass to your interruption listener callback
	UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
							sizeof(sessionCategory),
							&sessionCategory);
	AudioSessionSetActive(true);
}

static KATGAudioSessionState _state = 0;
void KATGConfigureAudioSessionState(KATGAudioSessionState state)
{
	if (state == _state)
		return;
	_state = state;
	switch (_state) {
		case KATGAudioSessionStateAmbient:
			ConfigureAmbientAudioSession();
			break;
		case KATGAudioSessionStatePlayback:
			ConfigurePlaybackAudioSession();
			break;
		default:
			break;
	}
}
