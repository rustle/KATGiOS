//
//  KATGShowImageThumbnailCell.m
//  KATG
//
//  Created by Tim Donnelly on 3/9/13.
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

#import "KATGShowImageThumbnailCell.h"
#import "KATGImage.h"

@interface KATGShowImageThumbnailCell ()
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UIView *shadowView;
@end

@implementation KATGShowImageThumbnailCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		self.contentView.backgroundColor = [UIColor clearColor];
		
		self.shadowView = [[UIView alloc] initWithFrame:self.contentView.bounds];
		self.shadowView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		self.shadowView.layer.shadowColor = [[UIColor blackColor] CGColor];
		self.shadowView.layer.shadowOpacity = 0.35f;
		self.shadowView.layer.shadowRadius = 2.0f;
		self.shadowView.layer.shadowOffset = CGSizeZero;
		self.shadowView.backgroundColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
		self.shadowView.layer.shouldRasterize = YES;
		[self.contentView addSubview:self.shadowView];
		
		self.imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
		self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.imageView.backgroundColor = [UIColor clearColor];
		self.imageView.contentMode = UIViewContentModeScaleAspectFill;
		self.imageView.clipsToBounds = YES;
		[self.contentView addSubview:self.imageView];
		
		self.activityIndicatorView = [(UIActivityIndicatorView *)[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
		[self.activityIndicatorView sizeToFit];
		[self.contentView addSubview:self.activityIndicatorView];
		self.activityIndicatorView.backgroundColor = [UIColor clearColor];
		self.activityIndicatorView.frame = self.contentView.bounds;
		[self.activityIndicatorView startAnimating];
		
		self.button = [[UIButton alloc] initWithFrame:self.contentView.bounds];
		self.button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:self.button];
	}
	return self;
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	self.activityIndicatorView.frame = self.contentView.bounds;
	[self.activityIndicatorView startAnimating];
}

- (void)buttonTapped:(UIButton *)button
{
	[self.delegate imageThumbnailCellWasTapped:self];
}

- (void)assignImage:(UIImage *)image requestedForObjectID:(NSManagedObjectID *)objectID
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([[self.currentImage objectID] isEqual:objectID])
		{
			self.imageView.image = image;
			[self.activityIndicatorView stopAnimating];
			self.activityIndicatorView.hidden = YES;
			self.imageView.alpha = 0.0f;
			[UIView animateWithDuration:0.2f animations:^{
				self.imageView.alpha = 1.0f;
			}];
		}
	});
}

@end
