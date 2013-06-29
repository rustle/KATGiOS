//
//  KATGShowSectionTitleCell.m
//  KATG
//
//  Created by Timothy Donnelly on 12/10/12.
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

#import "KATGShowSectionTitleCell.h"

#define kKATGShowSectionTitleCellMargin 10.0f

@interface KATGShowSectionTitleCell ()

@end

@implementation KATGShowSectionTitleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) 
	{		
		_sectionTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:_sectionTitleLabel];
		_sectionTitleLabel.backgroundColor = [UIColor clearColor];
		_sectionTitleLabel.textColor = [UIColor darkGrayColor];
		_sectionTitleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
		_sectionTitleLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
		_sectionTitleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		
		self.showTopRule = YES;
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self.sectionTitleLabel sizeToFit];
	
	self.sectionTitleLabel.frame = CGRectMake(kKATGShowSectionTitleCellMargin,
											  self.contentView.frame.size.height - self.sectionTitleLabel.frame.size.height - kKATGShowSectionTitleCellMargin,
											  self.contentView.frame.size.width - (kKATGShowSectionTitleCellMargin*2),
											  self.sectionTitleLabel.frame.size.height);
}

@end
