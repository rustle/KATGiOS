//
//  KATGShowCell.m
//  KATG
//
//  Created by Timothy Donnelly on 4/30/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGShowCell.h"
#import "KATGInsetView.h"

@interface KATGShowCell ()
@property (strong, nonatomic) KATGInsetView *insetView;
@end

@implementation KATGShowCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_showTopRule = NO;
		
		_insetView = [[KATGInsetView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.contentView.bounds.size.width, 2.0f)];
		_insetView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		_insetView.hidden = YES;
		[self.contentView addSubview:_insetView];
	}
	return self;
}

- (void)setShowTopRule:(BOOL)showTopRule
{
	_showTopRule = showTopRule;
	self.insetView.hidden = !showTopRule;
}

@end
