//
//  KATGShowControlsScrubber.m
//  KATG
//
//  Created by Doug Russell on 2/24/13.
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

#import "KATGShowControlsScrubber.h"

#define kKATGControlsTrackInset 50.0f
#define kKATGControlsLabelInset 5.0f

@interface KATGShowControlsScrubber ()
@property (nonatomic) UILabel *currentTimeLabel;
@property (nonatomic) UILabel *remainingTimeLabel;
@end

@implementation KATGShowControlsScrubber

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		_currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_currentTimeLabel.textAlignment = NSTextAlignmentCenter;
		_currentTimeLabel.backgroundColor = [UIColor clearColor];
		_currentTimeLabel.textColor = [UIColor darkGrayColor];
		_currentTimeLabel.shadowColor = [UIColor whiteColor];
		_currentTimeLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_currentTimeLabel.font = [UIFont systemFontOfSize:9.0f];
		[self addSubview:_currentTimeLabel];
		
		_remainingTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_remainingTimeLabel.textAlignment = NSTextAlignmentCenter;
		_remainingTimeLabel.backgroundColor = [UIColor clearColor];
		_remainingTimeLabel.textColor = [UIColor darkGrayColor];
		_remainingTimeLabel.shadowColor = [UIColor whiteColor];
		_remainingTimeLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_remainingTimeLabel.font = [UIFont systemFontOfSize:9.0f];
		[self addSubview:_remainingTimeLabel];
		
		[self setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal];
		[self setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal];
		
		[self updateAccessibilityValue];
	}
	return self;
}

#pragma mark - 

- (void)setValue:(float)value animated:(BOOL)animated
{
	[super setValue:value animated:animated];
	[self updateAccessibilityValue];
	self.currentTimeLabel.text = [self currentTimeLabelText];
	self.remainingTimeLabel.text = [self remainingTimeLabelText];
	[self setNeedsDisplay];
}

#pragma mark - Layout

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGFloat width = kKATGControlsTrackInset - kKATGControlsLabelInset*2.0f;
	self.currentTimeLabel.frame = CGRectMake(kKATGControlsLabelInset, 0.0f, width, self.bounds.size.height);
	self.remainingTimeLabel.frame = CGRectMake(self.bounds.size.width - kKATGControlsTrackInset + kKATGControlsLabelInset, 0.0f, width, self.bounds.size.height);
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
	CGRect trackRect = [super trackRectForBounds:bounds];
	trackRect = CGRectInset(trackRect, kKATGControlsTrackInset, 0.0);
	return trackRect;
}

#pragma mark - 

- (NSString *)timeLabelTextStringWithSeconds:(float)interval
{
	bool negative = (interval < 0.0f);
	interval = fabsf(interval);
	int64_t hours = (int64_t)interval / 3600;
	int64_t minutes = ((int64_t)interval - hours * 3600) / 60;
	int64_t seconds = (int64_t)interval - hours * 3600 - minutes * 60;
	if (hours)
	{
		return [NSString stringWithFormat:@"%@%lld:%02lld:%02lld", negative ? @"-" : @"", hours, minutes, seconds];
	}
	return [NSString stringWithFormat:@"%@%02lld:%02lld", negative ? @"-" : @"", minutes, seconds];
}

- (NSString *)currentTimeLabelText
{
	return [self timeLabelTextStringWithSeconds:self.value];
}

- (NSString *)remainingTimeLabelText
{
	return [self timeLabelTextStringWithSeconds:-(self.maximumValue - self.value)];
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
	return YES;
}

- (void)accessibilityIncrement
{
	self.value += 300.0f;
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)accessibilityDecrement
{
	self.value -= 300.0f;
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (NSString *)accessibilityLabel
{
	return NSLocalizedString(@"Track position", nil);
}

- (NSString *)accessibilityIntervalStringWithSeconds:(float)interval
{
	bool negative = (interval < 0.0f);
	interval = fabsf(interval);
	NSMutableString *string = [NSMutableString string];
	int64_t hours = (int64_t)interval / 3600;
	if (hours)
	{
		[string appendFormat:@"%lld %@", hours, (hours == 1) ? NSLocalizedString(@"hour", @"hour singular") : NSLocalizedString(@"hours", @"hours plural")];
	}
	int64_t minutes = ((int64_t)interval - hours * 3600) / 60;
	if (hours || minutes)
	{
		[string appendFormat:@"%02lld %@", minutes, (minutes == 1) ? NSLocalizedString(@"minute", @"minute singular") : NSLocalizedString(@"minutes", @"minutes plural")];
	}
	int64_t seconds = (int64_t)interval - hours * 3600 - minutes * 60;
	[string appendFormat:@"%02lld %@", seconds, (seconds == 1) ? NSLocalizedString(@"second", @"second singular") : NSLocalizedString(@"seconds", @"seconds plural")];
	if (negative)
	{
		[string appendString:NSLocalizedString(@" remaining", nil)];
	}
	return [string copy];
}

- (void)updateAccessibilityValue
{
	if (self.maximumValue > 1.0f)
	{
		self.accessibilityValue = [NSString stringWithFormat:NSLocalizedString(@"%@ of %@", nil), [self accessibilityIntervalStringWithSeconds:self.value], [self accessibilityIntervalStringWithSeconds:self.maximumValue]];
	}
	else
	{
		self.accessibilityValue = @"";
	}
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect trackRect = [self trackRectForBounds:self.bounds];
	trackRect.size.height = 8.0f;
	trackRect.origin.y -= 4.0f;
	
	// Clip
	UIBezierPath *trackPath = [UIBezierPath bezierPathWithRoundedRect:trackRect cornerRadius:4.0f];
	[trackPath addClip];
	
	// Background
	[[UIColor colorWithWhite:0.0f alpha:0.1f] setFill];
	[[UIBezierPath bezierPathWithRect:rect] fill];
	
	// Progress
	[[UIColor colorWithRed:0.404 green:0.678 blue:0.333 alpha:1] setFill];
	CGRect progressRect = CGRectMake(0.0f,
																	 0.0f,
																	 trackRect.origin.x + trackRect.size.width*self.value/self.maximumValue,
																	 rect.size.height);
	[[UIBezierPath bezierPathWithRect:progressRect] fill];
	
	// Shadow
	UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(rect, -40.0f, -40.0f)];
	[shadowPath appendPath:trackPath];
	shadowPath.usesEvenOddFillRule = YES;
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 2.0f, [[UIColor colorWithWhite:0.0f alpha:1.0f] CGColor]);
	[[UIColor colorWithWhite:0.0f alpha:0.2f] setFill];
	[shadowPath fill];
	
}

@end
