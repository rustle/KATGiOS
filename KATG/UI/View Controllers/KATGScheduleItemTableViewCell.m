//
//  KATGScheduleItemTableViewCell.m
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

#import "KATGScheduleItemTableViewCell.h"
#import "KATGScheduledEvent.h"
#import "TDRoundedShadowView.h"

#define kKATGScheduleItemSideMargin 10.0f

@interface KATGScheduleItemTableViewCell ()
@property (strong, nonatomic) TDRoundedShadowView *roundedShadowView;
+ (UIFont *)nameFont;
+ (UIFont *)dateFont;
+ (UIFont *)timeFont;
+ (UIFont *)guestsFont;
@end

@implementation KATGScheduleItemTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
		_roundedShadowView = [[TDRoundedShadowView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.contentView.bounds.size.width, 5.0f)];
		_roundedShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		_roundedShadowView.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.03f];
		[self.contentView addSubview:_roundedShadowView];
		
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		_episodeNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_episodeNameLabel.backgroundColor = [UIColor clearColor];
		_episodeNameLabel.textColor = [UIColor colorWithRed:0.643 green:0.733 blue:0.502 alpha:1];
		_episodeNameLabel.font = [[self class] nameFont];
		_episodeNameLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
		_episodeNameLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		[self.contentView addSubview:_episodeNameLabel];
		
		_episodeDateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_episodeDateLabel.backgroundColor = [UIColor clearColor];
		_episodeDateLabel.font = [[self class] dateFont];
		_episodeDateLabel.textColor = [UIColor darkGrayColor];
		_episodeDateLabel.numberOfLines = 0;
		_episodeDateLabel.textAlignment = NSTextAlignmentLeft;
		_episodeDateLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
		_episodeDateLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		[self.contentView addSubview:_episodeDateLabel];
		
		_episodeTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_episodeTimeLabel.backgroundColor = [UIColor clearColor];
		_episodeTimeLabel.font = [[self class] timeFont];
		_episodeTimeLabel.textColor = [UIColor darkGrayColor];
		_episodeTimeLabel.numberOfLines = 0;
		_episodeTimeLabel.textAlignment = NSTextAlignmentLeft;
		_episodeTimeLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
		_episodeTimeLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		[self.contentView addSubview:_episodeTimeLabel];
		
		_episodeGuestLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_episodeGuestLabel.backgroundColor = [UIColor clearColor];
		_episodeGuestLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1.0f];
		_episodeGuestLabel.font = [[self class] guestsFont];
		_episodeGuestLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
		_episodeGuestLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_episodeGuestLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_episodeGuestLabel.numberOfLines = 0;
		[self.contentView addSubview:_episodeGuestLabel];
		
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
		[self.contentView addGestureRecognizer:longPress];
    }
    return self;
}

- (void)longPressed:(UILongPressGestureRecognizer *)sender
{
	if ([sender state] == UIGestureRecognizerStateRecognized)
	{
		[self.longPressDelegate longPressRecognized:self];
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGSize size = [self.episodeNameLabel.text sizeWithFont:self.episodeNameLabel.font constrainedToSize:self.contentView.bounds.size lineBreakMode:NSLineBreakByTruncatingTail];
	self.episodeNameLabel.frame = CGRectMake(self.contentView.bounds.size.width-size.width - kKATGScheduleItemSideMargin,
											 kKATGScheduleItemSideMargin,
											 size.width,
											 size.height);
	
	CGSize leftColMaxSize = CGSizeMake(self.contentView.bounds.size.width - size.width - (kKATGScheduleItemSideMargin * 3), CGFLOAT_MAX);
	CGRect leftColRect = CGRectZero;
	leftColRect.origin.x = kKATGScheduleItemSideMargin;
	leftColRect.origin.y = kKATGScheduleItemSideMargin;
	
	leftColRect.size = [self.episodeDateLabel.text sizeWithFont:self.episodeDateLabel.font
																						constrainedToSize:leftColMaxSize
																								lineBreakMode:NSLineBreakByTruncatingTail];
	self.episodeDateLabel.frame = leftColRect;
	leftColRect.origin.y += leftColRect.size.height + 2.0f;

	leftColRect.size = [self.episodeTimeLabel.text sizeWithFont:self.episodeTimeLabel.font
																						constrainedToSize:leftColMaxSize
																								lineBreakMode:NSLineBreakByTruncatingTail];
	self.episodeTimeLabel.frame = leftColRect;
	leftColRect.origin.y += leftColRect.size.height + 2.0f;
	
	leftColRect.size = [self.episodeGuestLabel.text sizeWithFont:self.episodeGuestLabel.font
																						 constrainedToSize:CGSizeMake(self.contentView.bounds.size.width - (kKATGScheduleItemSideMargin*2), CGFLOAT_MAX)
																								 lineBreakMode:NSLineBreakByTruncatingTail];
	self.episodeGuestLabel.frame = leftColRect;
}

- (void)configureWithScheduledEvent:(KATGScheduledEvent *)scheduledEvent
{
	self.episodeNameLabel.text = scheduledEvent.title;
	self.episodeGuestLabel.text = [scheduledEvent.subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	self.episodeDateLabel.text = [scheduledEvent formattedDate];
	self.episodeTimeLabel.text = [scheduledEvent formattedTime];
}

+ (CGFloat)heightForScheduledEvent:(KATGScheduledEvent *)scheduledEvent forWidth:(CGFloat)width
{
	NSString *name = scheduledEvent.title;
	NSString *guests = scheduledEvent.subtitle;
	NSString *date = [scheduledEvent formattedDate];
	NSString *time = [scheduledEvent formattedTime];
	
	CGSize nameSize = [name sizeWithFont:[self nameFont]
										 constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
												 lineBreakMode:NSLineBreakByTruncatingTail];
	
	CGSize leftColMaxSize = CGSizeMake(width - nameSize.width - (kKATGScheduleItemSideMargin * 3), CGFLOAT_MAX);
	
		CGFloat height = 0;
	
	height += kKATGScheduleItemSideMargin;
	
	height += [date sizeWithFont:[self dateFont]
						 constrainedToSize:leftColMaxSize
								 lineBreakMode:NSLineBreakByTruncatingTail].height;
	
	height += 2.0f;

	height += [time sizeWithFont:[self timeFont]
						 constrainedToSize:leftColMaxSize
								 lineBreakMode:NSLineBreakByTruncatingTail].height;
	
	height += 2.0f;
	
	height += [guests sizeWithFont:[self guestsFont]
							 constrainedToSize:CGSizeMake(width - (kKATGScheduleItemSideMargin*2), CGFLOAT_MAX)
									 lineBreakMode:NSLineBreakByWordWrapping].height;
	
	height += kKATGScheduleItemSideMargin;
	
	return height;
}

#pragma mark - Font styles

+ (UIFont *)nameFont
{
	return [UIFont boldSystemFontOfSize:14.0f];
}

+ (UIFont *)dateFont
{
	return [UIFont boldSystemFontOfSize:14.0f];
}

+ (UIFont *)timeFont
{
	return [UIFont systemFontOfSize:12.0f];
}

+ (UIFont *)guestsFont
{
	return [UIFont boldSystemFontOfSize:12.0f];
}

@end
