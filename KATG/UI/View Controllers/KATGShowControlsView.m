//
//  KATGShowControlsView.m
//  KATG
//
//  Created by Timothy Donnelly on 12/12/12.
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

#import "KATGShowControlsView.h"
#import "KATGControlButton.h"
#import "UIColor+KATGColors.h"

#define kKATGPlayButtonRatio 0.5f
#define kKATGControlsSideMargin 0.0f
#define kKATGControlsSliderSideMargin 0.0f

@interface KATGShowControlsView ()
@property (nonatomic) KATGControlButton *playButton;
@property (nonatomic) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic) KATGControlButton *skipBackButton;
@property (nonatomic) KATGControlButton *skipForwardButton;
@property (nonatomic) KATGShowControlsScrubber *positionSlider;
@property (nonatomic) NSArray *accessibilityElements;
@end

@implementation KATGShowControlsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		_skipBackButton = [[KATGControlButton alloc] initWithFrame:CGRectZero];
		_skipBackButton.accessibilityLabel = NSLocalizedString(@"Rewind 15 seconds", nil);
		[_skipBackButton setImage:[UIImage imageNamed:@"skip-back"] forState:UIControlStateNormal];
		_skipBackButton.leftBorderWidth = 0.0f;
		[self addSubview:_skipBackButton];
		
		_playButton = [[KATGControlButton alloc] initWithFrame:CGRectZero];
		[self addSubview:_playButton];
		
		_skipForwardButton = [[KATGControlButton alloc] initWithFrame:CGRectZero];
		_skipForwardButton.accessibilityLabel = NSLocalizedString(@"Fast-Forward 15 seconds", nil);
		[_skipForwardButton setImage:[UIImage imageNamed:@"skip-forward"] forState:UIControlStateNormal];
		_skipForwardButton.rightBorderWidth = 0.0f;
		[self addSubview:_skipForwardButton];
		
		_playButton.bottomBorderWidth = _skipBackButton.bottomBorderWidth = _skipForwardButton.bottomBorderWidth = 1.0f / [[UIScreen mainScreen] scale];
		
		_positionSlider = [[KATGShowControlsScrubber alloc] initWithFrame:CGRectZero];
		[self addSubview:_positionSlider];
		
		_loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		_loadingIndicator.color = [UIColor katg_titleTextColor];
		[self addSubview:_loadingIndicator];
		
		self.accessibilityElements = @[_skipBackButton, _playButton, _skipForwardButton, _positionSlider];
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGFloat controlWidth = self.bounds.size.width - (kKATGControlsSideMargin * 2);
	CGSize playButtonSize = CGSizeMake(controlWidth * kKATGPlayButtonRatio, self.bounds.size.height/2);
	CGSize skipButtonSize = CGSizeMake((controlWidth-playButtonSize.width)/2, self.bounds.size.height/2);
	
	self.skipBackButton.frame = CGRectMake(kKATGControlsSideMargin, 0.0f, skipButtonSize.width, skipButtonSize.height);
	self.playButton.frame = CGRectMake(CGRectGetMaxX(self.skipBackButton.frame), 0.0f, playButtonSize.width, playButtonSize.height);
	self.skipForwardButton.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame), 0.0f, skipButtonSize.width, skipButtonSize.height);
	
	self.positionSlider.frame = CGRectMake(kKATGControlsSliderSideMargin, truncf(self.bounds.size.height/2.0f), self.bounds.size.width - (kKATGControlsSliderSideMargin*2), truncf(self.bounds.size.height/2.0f));
	
	self.loadingIndicator.center = self.playButton.center;
}

- (BOOL)isAccessibilityElement
{
	return NO;
}

- (NSInteger)accessibilityElementCount
{
	return [self.accessibilityElements count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
	return self.accessibilityElements[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
	return [self.accessibilityElements indexOfObject:element];
}

- (void)setCurrentState:(KATGAudioPlayerState)currentState
{
	_currentState = currentState;
	if (currentState == KATGAudioPlayerStateLoading)
	{
		[self.loadingIndicator startAnimating];
	}
	else
	{
		[self.loadingIndicator stopAnimating];
	}
	switch (currentState)
	{
		case KATGAudioPlayerStateDone:
		{
			self.playButton.enabled = YES;
			self.skipBackButton.enabled = NO;
			self.skipForwardButton.enabled = NO;
			self.positionSlider.enabled = NO;
			[self.playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateFailed:
		{
			self.playButton.enabled = YES;
			self.skipBackButton.enabled = NO;
			self.skipForwardButton.enabled = NO;
			self.positionSlider.enabled = NO;
			[self.playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateLoading:
		{
			self.playButton.enabled = NO;
			self.skipBackButton.enabled = NO;
			self.skipForwardButton.enabled = NO;
			self.positionSlider.enabled = NO;
			[self.playButton setImage:nil forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStatePaused:
		{
			self.playButton.enabled = YES;
			self.skipBackButton.enabled = YES;
			self.skipForwardButton.enabled = YES;
			self.positionSlider.enabled = YES;
			[self.playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStatePlaying:
		{
			self.playButton.enabled = YES;
			self.skipBackButton.enabled = YES;
			self.skipForwardButton.enabled = YES;
			self.positionSlider.enabled = YES;
			[self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateUnknown:
		{
			self.playButton.enabled = NO;
			self.skipBackButton.enabled = NO;
			self.skipForwardButton.enabled = NO;
			self.positionSlider.enabled = NO;
			[self.playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
	}
	
}

@end
