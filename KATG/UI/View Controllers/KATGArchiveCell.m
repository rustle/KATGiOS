//
//  KATGArchiveCell.m
//  KATG
//
//  Created by Timothy Donnelly on 11/12/12.
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

#import "KATGArchiveCell.h"
#import "KATGShow.h"
#import "KATGGuest.h"
#import "KATGShowView.h"
#import "TDRoundedShadowView.h"
#import "KATGButton.h"

@interface KATGArchiveCell ()
@end

@implementation KATGArchiveCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_showView = [[KATGShowView alloc] initWithFrame:CGRectZero];
		_showView.closeButtonVisible = NO;
		_showView.closeButton.alpha = 0.0f;
		_showView.footerShadowView.alpha = 0.0f;
		[self.contentView addSubview:_showView];
		
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.showView.frame = self.bounds;
}

- (void)configureWithShow:(KATGShow *)show
{
	self.showView.showNumberLabel.text = [show.number stringValue];
	self.showView.showTitleLabel.text = show.title;
	
	NSMutableString *guestNames = [NSMutableString new];
	for (NSUInteger i = 0; i < MIN(4, [show.sortedGuests count]); i++)
	{
		KATGGuest *guest = show.sortedGuests[i];
		if (i > 0)
		{
			[guestNames appendString:@"\n"];
		}
		if (i == 3)
		{
			[guestNames appendString:@"..."];
		}
		else
		{
			[guestNames appendFormat:@"%@", guest.name];
		}
	}
	if (guestNames.length == 0)
	{
		[guestNames appendString:@"(no guests)"];
	}
	self.showView.showMetaFirstColumn.text = [guestNames copy];
	
	self.showView.showMetaSecondColumn.text = [show formattedTimestamp];
	
	[self.showView setNeedsLayout];
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
	return NO;
}

- (NSInteger)accessibilityElementCount
{
	return 1;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
	return self.showView;
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
	return 0;
}

@end