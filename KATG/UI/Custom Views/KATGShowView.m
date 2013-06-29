//
//  KATGShowView.m
//  KATG
//
//  Created by Timothy Donnelly on 12/6/12.
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

#import "KATGShowView.h"
#import "KATGContentContainerView_Internal.h"
#import "TDRoundedShadowView.h"
#import "KATGButton.h"

#define kKATGSideMargins 10.0f
#define kKATGColumnMargins 4.0f
#define kKATGShowNumberWidth 52.0f
#define kKATGCloseButtonWidth 60.0f

@interface KATGShowNumberLabel : UILabel

@end

@implementation KATGShowNumberLabel

- (void)setText:(NSString *)text
{
	[super setText:text];
	self.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Show number %@", nil), text];
}

@end

@interface KATGShowTitleLabel : UILabel

@end

@implementation KATGShowTitleLabel

- (void)setText:(NSString *)text
{
	[super setText:text];
	self.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Show title %@", nil), text];
}

@end

@interface KATGShowView ()

@end

@implementation KATGShowView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		_showNumberLabel = [[KATGShowNumberLabel alloc] initWithFrame:CGRectZero];
		_showNumberLabel.backgroundColor = [UIColor clearColor];
		_showNumberLabel.textColor = [UIColor lightGrayColor];
		_showNumberLabel.shadowColor = [UIColor whiteColor];
		_showNumberLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_showNumberLabel.font = [UIFont boldSystemFontOfSize:22.0f];
		[self addSubview:_showNumberLabel];
		
		_showTitleLabel = [[KATGShowTitleLabel alloc] initWithFrame:CGRectZero];
		_showTitleLabel.backgroundColor = [UIColor clearColor];
		_showTitleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
		_showTitleLabel.textColor = [UIColor darkGrayColor];
		_showTitleLabel.shadowColor = [UIColor whiteColor];
		_showTitleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_showTitleLabel.textAlignment = NSTextAlignmentLeft;
		_showTitleLabel.numberOfLines = 0;
		[self addSubview:_showTitleLabel];
		
		_closeButton = [[KATGButton alloc] initWithFrame:CGRectZero];
		[_closeButton setTitle:@"Close" forState:UIControlStateNormal];
		_closeButton.accessibilityLabel = NSLocalizedString(@"Close show detail", nil);
		[self addSubview:_closeButton];
		
		_showMetaView = [[UIView alloc] initWithFrame:CGRectZero];
		[self.footerView addSubview:_showMetaView];
		
		_showMetaFirstColumn = [[UILabel alloc] initWithFrame:self.bounds];
		[_showMetaView addSubview:_showMetaFirstColumn];
		
		_showMetaSecondColumn = [[UILabel alloc] initWithFrame:self.bounds];
		[_showMetaView addSubview:_showMetaSecondColumn];
		
		_showMetaThirdColumn = [[UILabel alloc] initWithFrame:self.bounds];
		[_showMetaView addSubview:_showMetaThirdColumn];
		
		_showMetaFirstColumn.backgroundColor = _showMetaSecondColumn.backgroundColor = _showMetaThirdColumn.backgroundColor = [UIColor clearColor];
		_showMetaFirstColumn.textColor = _showMetaSecondColumn.textColor = _showMetaThirdColumn.textColor = [UIColor lightGrayColor];
		_showMetaFirstColumn.font = _showMetaSecondColumn.font = _showMetaThirdColumn.font = [UIFont systemFontOfSize:10.0f];
		_showMetaFirstColumn.lineBreakMode = _showMetaSecondColumn.lineBreakMode = _showMetaThirdColumn.lineBreakMode = NSLineBreakByWordWrapping;
		_showMetaFirstColumn.numberOfLines = _showMetaSecondColumn.numberOfLines = _showMetaThirdColumn.numberOfLines = 0;
		
		self.isAccessibilityElement = YES;
		
		self.accessibilityElements = @[_showNumberLabel, _showTitleLabel, _closeButton, self.contentView, self.footerView];
	}
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	self.showNumberLabel.frame = CGRectMake(kKATGSideMargins, kKATGSideMargins, kKATGShowNumberWidth, self.headerHeight - kKATGSideMargins - kKATGSideMargins);
	
	self.closeButton.frame = CGRectMake(self.headerView.bounds.size.width - 5.0f - kKATGCloseButtonWidth, 4.0f, kKATGCloseButtonWidth, self.headerHeight - 8.0f);
	
	self.showTitleLabel.frame = CGRectMake(kKATGSideMargins + kKATGColumnMargins + kKATGShowNumberWidth, 0.0f, self.headerView.bounds.size.width - (kKATGSideMargins*2) - (kKATGColumnMargins*2) - (_closeButtonVisible ? kKATGCloseButtonWidth : 0.0f) - kKATGShowNumberWidth, self.headerHeight);
	
	// meta
	
	self.showMetaView.frame = self.footerView.bounds;
	
	CGFloat columnWidth = (self.showMetaView.bounds.size.width - kKATGSideMargins*2 - kKATGColumnMargins*2)/3;
	
	CGSize maxColSize = CGSizeMake(columnWidth, CGFLOAT_MAX);
	
	CGSize col1Size = [self.showMetaFirstColumn.text sizeWithFont:self.showMetaFirstColumn.font constrainedToSize:maxColSize lineBreakMode:self.showMetaFirstColumn.lineBreakMode];
	CGSize col2Size = [self.showMetaSecondColumn.text sizeWithFont:self.showMetaSecondColumn.font constrainedToSize:maxColSize lineBreakMode:self.showMetaSecondColumn.lineBreakMode];
	CGSize col3Size = [self.showMetaThirdColumn.text sizeWithFont:self.showMetaThirdColumn.font constrainedToSize:maxColSize lineBreakMode:self.showMetaThirdColumn.lineBreakMode];
	
	CGRect colRect = CGRectMake(kKATGSideMargins, kKATGSideMargins, col1Size.width, col1Size.height);
	self.showMetaFirstColumn.frame = colRect;
	
	colRect.origin.x += kKATGColumnMargins + columnWidth;
	colRect.size.width = col2Size.width;
	colRect.size.height = col2Size.height;
	self.showMetaSecondColumn.frame = colRect;
	
	colRect.origin.x += kKATGColumnMargins + columnWidth;
	colRect.size.width = col3Size.width;
	colRect.size.height = col3Size.height;
	self.showMetaThirdColumn.frame = colRect;
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel
{
	return [NSString stringWithFormat:NSLocalizedString(@"Show %@: %@", nil), self.showNumberLabel.text, self.showTitleLabel.text];
}

- (BOOL)accessibilityPerformEscape
{
	[self.closeButton sendActionsForControlEvents:UIControlEventTouchUpInside];
	return YES;
}

@end
