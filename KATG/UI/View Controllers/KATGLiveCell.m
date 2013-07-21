//
//  KATGLiveCell.m
//  KATG
//
//  Created by Timothy Donnelly on 12/8/12.
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

#import "KATGLiveCell.h"
#import "KATGContentContainerView.h"
#import "KATGScheduledEvent.h"
#import "KATGButton.h"
#import "KATGControlButton.h"
#import "KATGCigaretteSmokeView.h"
#import "KATGBeerBubblesView.h"
#import "KATGPlaybackManager.h"
#import "UIColor+KATGColors.h"

@interface KATGTimerTarget : NSProxy
@property (weak, nonatomic) id target;
@end
@implementation KATGTimerTarget
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	id target = self.target;
	NSAssert(target, @"Timer target has gone to nil. This will crash and is probably caused by not cleaning up the timer associated with this target.");
	return target;
}
@end

@interface KATGLiveCell ()
@property (nonatomic) KATGContentContainerView *containerView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *nextShowLabel;
@property (nonatomic) UILabel *countLabel;
@property (nonatomic) UILabel *onAirLabel;

@property (nonatomic) KATGButton *feedbackButton;
@property (nonatomic) KATGTimerTarget *target;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) UIImageView *micImageView;
@property (nonatomic) KATGCigaretteSmokeView *smokeView;
@property (nonatomic) KATGBeerBubblesView *lightBubblesView;

@property (nonatomic) KATGControlButton *playButton;
@property (nonatomic) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic) KATGButton *liveToggleButton;

@property (nonatomic) UIRefreshControl *refreshControl;

@end

@implementation KATGLiveCell

#pragma mark - 

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_containerView = [[KATGContentContainerView alloc] initWithFrame:CGRectZero];
		_containerView.footerHeight = 8.0f;
		[self.contentView addSubview:_containerView];
		
		_refreshControl = [UIRefreshControl new];
		[_refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
		[self.containerView.contentView addSubview:_refreshControl];
		self.containerView.contentView.alwaysBounceVertical = YES;
		
		_titleLabel = [[UILabel alloc] initWithFrame:_containerView.headerView.bounds];
		_titleLabel.text = @"Next Live Show";
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.textAlignment = NSTextAlignmentCenter;
		_titleLabel.font = [UIFont boldSystemFontOfSize:20.0f];
		_titleLabel.textColor = [UIColor darkGrayColor];
		_titleLabel.shadowColor = [UIColor whiteColor];
		_titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[_containerView.headerView addSubview:_titleLabel];
		
#if DEBUG
		_liveToggleButton = [[KATGButton alloc] initWithFrame:CGRectMake(4.0f, 4.0f, 60.0f, 36.0f)];
		[_liveToggleButton setTitle:@"DbgLv" forState:UIControlStateNormal];
		[_liveToggleButton addTarget:self action:@selector(toggleLive:) forControlEvents:UIControlEventTouchUpInside];
		[_containerView.headerView addSubview:_liveToggleButton];
#endif
		
		_micImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live-mic.png"]];
		_micImageView.alpha = 0.1f;
		CGRect micFrame = CGRectZero;
		micFrame.size = _micImageView.image.size;
		micFrame.origin.x = (_containerView.contentView.bounds.size.width - micFrame.size.width) / 2;
		micFrame.origin.y = (_containerView.contentView.bounds.size.height - micFrame.size.height);
		_micImageView.frame = micFrame;
		_micImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
		[_containerView.contentView addSubview:_micImageView];
		
		_smokeView = [[KATGCigaretteSmokeView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 600.0f, 600.0f)];
		_smokeView.glowSize = CGSizeMake(2.0f, 5.0f);
		_smokeView.origin = CGPointMake(300.0f, 300.0f);
		[_containerView.contentView addSubview:_smokeView];
		
		_lightBubblesView = [[KATGBeerBubblesView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 200.0f) lightBubbles:YES];
		_lightBubblesView.bubbleRect = CGRectMake(40, 185, 26, 1);
		[_containerView.contentView addSubview:_lightBubblesView];

		_countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self setCountLabelDefaultText];
		_countLabel.isAccessibilityElement = NO;
		_countLabel.backgroundColor = [UIColor clearColor];
		_countLabel.textAlignment = NSTextAlignmentCenter;
		_countLabel.font = [UIFont boldSystemFontOfSize:42.0f];
		_countLabel.textColor = [UIColor darkGrayColor];
		[_containerView.contentView addSubview:_countLabel];
		
		_onAirLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_onAirLabel.text = @"On Air";
		_onAirLabel.isAccessibilityElement = NO;
		_onAirLabel.backgroundColor = [UIColor clearColor];
		_onAirLabel.textAlignment = NSTextAlignmentCenter;
		_onAirLabel.font = [UIFont boldSystemFontOfSize:28.0f];
		_onAirLabel.textColor = [UIColor darkGrayColor];
		[_containerView.contentView addSubview:_onAirLabel];
		
		_nextShowLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_nextShowLabel.backgroundColor = [UIColor clearColor];
		_nextShowLabel.textAlignment = NSTextAlignmentCenter;
		_nextShowLabel.font = [UIFont systemFontOfSize:14.0f];
		_nextShowLabel.textColor = [UIColor lightGrayColor];
		_nextShowLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
		_nextShowLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_nextShowLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
		_nextShowLabel.numberOfLines = 0;
		_nextShowLabel.accessibilityTraits = _nextShowLabel.accessibilityTraits|UIAccessibilityTraitSummaryElement|UIAccessibilityTraitUpdatesFrequently;
		[_containerView.contentView addSubview:_nextShowLabel];
		
		_feedbackButton = [[KATGButton alloc] initWithFrame:CGRectZero];
		[_feedbackButton setTitle:NSLocalizedString(@"Send Feedback", nil) forState:UIControlStateNormal];
		[_feedbackButton addTarget:self action:@selector(sendFeedbackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[_containerView.contentView addSubview:_feedbackButton];
		
		_playButton = [[KATGControlButton alloc] initWithFrame:_containerView.footerView.bounds];
		_playButton.leftBorderWidth = _playButton.rightBorderWidth = 0.0f;
		_playButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[_containerView.footerView addSubview:_playButton];
		
		_loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		_loadingIndicator.color = [UIColor katg_titleTextColor];
		[_containerView.footerView addSubview:_loadingIndicator];

		self.currentAudioPlayerState = KATGAudioPlayerStateUnknown;
		
		_target = [KATGTimerTarget alloc];
		_target.target = self;
		
		_timer = [NSTimer timerWithTimeInterval:1.0f target:_target selector:@selector(updateCounter) userInfo:nil repeats:YES];		
		[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
		
		[self addPlaybackManagerKVO];
	}
	return self;
}

- (void)dealloc
{
	[_timer invalidate];
	[self removePlaybackManagerKVO];
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	[self.refreshControl endRefreshing];
}

#pragma mark - 

- (void)sendFeedbackButtonPressed:(id)sender
{
	[self.liveShowDelegate liveShowFeedbackButtonTapped:self];
}

#pragma mark - 

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.containerView.frame = self.contentView.bounds;
	[self.containerView layoutSubviews];
	[self layoutLiveMode];
}

- (void)layoutLiveMode
{
	BOOL liveMode = self.liveMode;
	
	self.containerView.footerHeight = liveMode ? 44.0f : 8.0f;
	self.playButton.alpha = liveMode ? 1.0f : 0.0f;
	self.feedbackButton.alpha = liveMode ? 1.0f : 0.0f;
	
	self.feedbackButton.bounds = CGRectMake(0.0f, 0.0f, self.containerView.contentView.bounds.size.width - 20.0f, 44.0f);
	
	CGPoint feedbackButtonCenter;
	feedbackButtonCenter.x = self.containerView.contentView.bounds.size.width / 2.0f;
	feedbackButtonCenter.y = liveMode ? self.containerView.contentView.bounds.size.height - self.feedbackButton.bounds.size.height/2 - 20.0f : self.containerView.bounds.size.height + self.feedbackButton.bounds.size.height/2;
	self.feedbackButton.center = feedbackButtonCenter;
	self.nextShowLabel.bounds = CGRectMake(0.0f, 0.0f, self.containerView.contentView.bounds.size.width, 60.0f);
	self.nextShowLabel.center = CGPointMake(self.containerView.contentView.bounds.size.width/2, self.nextShowLabel.bounds.size.height/2 + (liveMode ? 0.0f : 20.0f));
	
	CGRect countLabelRect = CGRectMake(0.0f, self.containerView.contentView.bounds.size.height - (liveMode ? 120.0f : 60.0f), self.containerView.contentView.bounds.size.width, 40.0f);
	
	if (liveMode)
	{
		self.onAirLabel.frame = countLabelRect;
		countLabelRect.origin.x -= self.containerView.bounds.size.width;
		self.countLabel.frame = countLabelRect;
	}
	else
	{
		self.countLabel.frame = countLabelRect;
		countLabelRect.origin.x += self.containerView.bounds.size.width;
		self.onAirLabel.frame = countLabelRect;
	}
	
	self.countLabel.alpha = liveMode ? 0.0f : 1.0f;
	self.onAirLabel.alpha = liveMode ? 1.0f : 0.0f;
	
	CGPoint smokeCenter = [self.smokeView.superview convertPoint:CGPointZero fromView:self.micImageView];
	CGPoint bubbleCenter = smokeCenter;
	
	smokeCenter.x += 106.0f;
	smokeCenter.y += 91.0f;
	self.smokeView.center = smokeCenter;
	
	bubbleCenter.x += 161.0f;
	bubbleCenter.y += 6.0f;
	self.lightBubblesView.center = bubbleCenter;
	
	self.loadingIndicator.center = self.playButton.center;
}

#pragma mark - Counter State

- (void)updateCounter
{
	if (!self.timestamp || self.liveMode)
	{
		return;
	}
	NSDateComponents *components = [self currentComponents];
	NSString *countdown = [NSString stringWithFormat:@"%d : %02d : %02d", components.hour, components.minute, components.second];
	self.countLabel.text = countdown;
	self.nextShowLabel.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"The next show will begin in %d hours %d minutes %d seconds", nil), components.hour, components.minute, components.second];
}

- (NSDateComponents *)currentComponents
{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:[NSDate date] toDate:self.timestamp options:0];
	return components;
}

- (void)setCountLabelDefaultText
{
	self.countLabel.text = @"00 : 00 : 00";
}

- (void)setTimestamp:(NSDate *)timestamp
{
	if (timestamp != _timestamp)
	{
		_timestamp = timestamp;
		if (_timestamp)
		{
			[self updateCounter];
		}
		else
		{
			[self setCountLabelDefaultText];
		}
	}
}

#pragma mark - state

- (void)setLiveMode:(bool)liveMode
{
	[self setLiveMode:liveMode animated:NO];
}

- (void)setLiveMode:(bool)liveMode animated:(BOOL)animated
{	
	_liveMode = liveMode;
	self.containerView.contentView.scrollEnabled = !liveMode;
	[UIView animateWithDuration:animated ? 0.3f : 0.0f
					 animations:^{
						 [self layoutLiveMode];
					 } completion:^(BOOL finished) {
						 
					 }];
}

- (void)toggleLive:(id)sender
{
	[self setLiveMode:!_liveMode animated:YES];
}

#pragma mark - Playback controls

- (void)playButtonTapped:(id)sender
{
	if ([[KATGPlaybackManager sharedManager] isLiveShow])
	{
		if ([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
		{
			[[KATGPlaybackManager sharedManager] pause];
		}
		else
		{
			[[KATGPlaybackManager sharedManager] play];
		}
	}
	else
	{
		[[KATGPlaybackManager sharedManager] configureForLiveShow];
		[[KATGPlaybackManager sharedManager] play];
	}
}

- (void)setCurrentAudioPlayerState:(KATGAudioPlayerState)currentAudioPlayerState
{
	_currentAudioPlayerState = currentAudioPlayerState;
	if (_currentAudioPlayerState == KATGAudioPlayerStateLoading)
	{
		[self.loadingIndicator startAnimating];
	}
	else
	{
		[self.loadingIndicator stopAnimating];
	}
	switch (currentAudioPlayerState)
	{
		case KATGAudioPlayerStateDone:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateFailed:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateLoading:
		{
			self.playButton.enabled = NO;
			[_playButton setImage:nil forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStatePaused:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStatePlaying:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateUnknown:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
			break;
		}
	}
}

#pragma mark - KATGPlaybackManager

- (void)addPlaybackManagerKVO
{
	[[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:KATGStateObserverKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)removePlaybackManagerKVO
{
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:KATGStateObserverKey];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:KATGStateObserverKey])
	{
		if ([[KATGPlaybackManager sharedManager] isLiveShow])
		{
			CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
				self.currentAudioPlayerState = [[KATGPlaybackManager sharedManager] state];
			});
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -

- (void)setScheduledEvent:(KATGScheduledEvent *)scheduledEvent
{
	_scheduledEvent = scheduledEvent;
	self.timestamp = scheduledEvent.timestamp;
	
	NSDictionary *smallTextAttrs = @{
		NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
		NSForegroundColorAttributeName : [UIColor lightGrayColor]
	};
	
	NSDictionary *largeTextAttrs = @{
		NSFontAttributeName : [UIFont boldSystemFontOfSize:18.0f],
		NSForegroundColorAttributeName : [UIColor darkGrayColor]
	};
	
	NSString *subtitle = _scheduledEvent.subtitle;
	NSMutableAttributedString *nextShowText = nil;
	if ([subtitle length])
	{
		nextShowText = [[NSMutableAttributedString alloc] init];
		[nextShowText appendAttributedString:[[NSAttributedString alloc] initWithString:@"Featuring\n" attributes:smallTextAttrs]];
		[nextShowText appendAttributedString:[[NSAttributedString alloc] initWithString:self.scheduledEvent.subtitle attributes:largeTextAttrs]];
	}
	
	self.nextShowLabel.attributedText = nextShowText;
	[self layoutLiveMode];
}

#pragma mark - 

- (void)refresh:(id)sender
{
	[self.liveShowDelegate liveShowRefreshButtonTapped:self];
}

- (void)endRefreshing
{
	[self.refreshControl endRefreshing];
}

@end
