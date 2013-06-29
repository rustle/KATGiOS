//
//  KATGFullScreenImageCell.m
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

#import "KATGFullScreenImageCell.h"

@interface KATGFullScreenImageCell () <UIScrollViewDelegate>
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic) UITapGestureRecognizer *doubleTapRecognizer;
@end

@implementation KATGFullScreenImageCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.isAccessibilityElement = YES;
		
		self.contentView.backgroundColor = [UIColor blackColor];
		
		_scrollView = [[UIScrollView alloc] initWithFrame:self.contentView.bounds];
		_scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		_scrollView.delegate = self;
		_scrollView.alwaysBounceVertical = YES;
		[self.contentView addSubview:_scrollView];
		
		_imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
		_imageView.contentMode = UIViewContentModeScaleToFill;
		[self.scrollView addSubview:_imageView];
		
		_activityIndicatorView = [(UIActivityIndicatorView *)[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
		[_activityIndicatorView sizeToFit];
		[self.contentView addSubview:_activityIndicatorView];
		_activityIndicatorView.backgroundColor = [UIColor clearColor];
		_activityIndicatorView.frame = self.contentView.bounds;
		[_activityIndicatorView startAnimating];
		
		_doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
		_doubleTapRecognizer.numberOfTapsRequired = 2;
		[_scrollView addGestureRecognizer:_doubleTapRecognizer];
		
		_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
		[_tapRecognizer requireGestureRecognizerToFail:_doubleTapRecognizer];
		[_scrollView addGestureRecognizer:_tapRecognizer];
	}
	return self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
	(scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
	
	CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
	(scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
	
	self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	[self.scrollView setZoomScale:1.0f];
	self.activityIndicatorView.hidden = NO;
	self.activityIndicatorView.frame = self.contentView.bounds;
	[self.activityIndicatorView startAnimating];
}

- (void)setupImageInScrollView
{
	CGSize imageSize = self.imageView.image.size;
	self.scrollView.contentSize = imageSize;
	CGRect imageViewRect = CGRectZero;
	imageViewRect.size = imageSize;
	self.imageView.bounds = imageViewRect;
	
	// Setup zoom scale
	CGFloat imageAspectRatio = imageSize.width / imageSize.height;
	CGFloat viewAspectRatio = self.bounds.size.width / self.bounds.size.height;
	if (imageAspectRatio > viewAspectRatio)
	{
		// scale by width
		self.scrollView.minimumZoomScale = self.scrollView.frame.size.width/imageViewRect.size.width;
	}
	else
	{
		// scale by height
		self.scrollView.minimumZoomScale = self.scrollView.frame.size.height/imageViewRect.size.height;
	}
	self.scrollView.maximumZoomScale = self.scrollView.minimumZoomScale*3.0f;
	
	// Default zoom fits the image to screen width
	[self.scrollView setZoomScale:self.scrollView.frame.size.width/imageViewRect.size.width animated:NO];
}

#pragma mark - Gesture Recognizers

- (void)tapped:(UITapGestureRecognizer *)tapRecognizer
{
	[self.delegate didTapFullScreenImageCell:self];
}

- (void)doubleTapped:(UITapGestureRecognizer *)tapRecognizer
{
	CGPoint locationInImage = [tapRecognizer locationInView:self.imageView];

	CGFloat newZoomScale = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) ? self.scrollView.maximumZoomScale : self.scrollView.minimumZoomScale;
	
	CGRect zoomRect = CGRectZero;
	zoomRect.size.width = self.bounds.size.width / newZoomScale;
	zoomRect.size.height = self.bounds.size.height / newZoomScale;
	zoomRect.origin.x = locationInImage.x - zoomRect.size.width / 2;
	zoomRect.origin.y = locationInImage.y - zoomRect.size.height / 2;
	
	[self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)wasDoubleTappedAtLocation:(CGPoint)location
{
	
}

- (UIAccessibilityTraits)accessibilityTraits
{
	return [super accessibilityTraits] | UIAccessibilityTraitImage;
}

- (BOOL)accessibilityPerformEscape	
{
	return [self.delegate katg_performAccessibilityEscape];
}

@end
