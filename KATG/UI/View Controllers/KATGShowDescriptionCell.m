//
//  KATGShowDescriptionCell.m
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

#import "KATGShowDescriptionCell.h"

#define kKATGShowDescriptionFont [UIFont systemFontOfSize:12.0f]
#define kKATGShowDescriptionCellMargin 10.0f

@implementation KATGShowDescriptionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
	{
		_descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_descriptionLabel.font = kKATGShowDescriptionFont;
		_descriptionLabel.numberOfLines = 0;
		_descriptionLabel.textColor = [UIColor darkGrayColor];
		_descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_descriptionLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:_descriptionLabel];
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	self.descriptionLabel.frame = CGRectInset(self.contentView.bounds, kKATGShowDescriptionCellMargin, kKATGShowDescriptionCellMargin);
}

+ (CGFloat)cellHeightWithString:(NSString *)string width:(CGFloat)width
{
	CGSize maxSize = CGSizeMake(width-(kKATGShowDescriptionCellMargin*2), CGFLOAT_MAX);
	CGSize textSize = [string sizeWithFont:kKATGShowDescriptionFont constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
	return textSize.height + (kKATGShowDescriptionCellMargin*2);
}

@end
