//
//  KATGImagesViewController.m
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

#import "KATGImagesViewController.h"
#import "KATGFullScreenImageCell.h"
#import "KATGImageCache.h"
#import "KATGImage.h"
#import "UICollectionView+TDAdditions.h"
#import "KATGButton.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define IMAGE_GAP 10.0f

static NSString *fullScreenImageCellIdentifier = @"fullScreenImageCellIdentifier";

@interface KATGImagesViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, KATGFullScreenImageCellDelegate, UIActionSheetDelegate>
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UINavigationBar *navigationBar;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIActionSheet *actionSheet;
@end

@implementation KATGImagesViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.accessibilityViewIsModal = YES;
	
	self.view.backgroundColor = [UIColor clearColor];
	
	self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.backgroundView.backgroundColor = [UIColor blackColor];
	self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.backgroundView];
	
	UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
	flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	CGRect collectionViewRect = self.view.bounds;
	collectionViewRect.origin.x -= (IMAGE_GAP/2.0f);
	collectionViewRect.size.width += IMAGE_GAP;
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:collectionViewRect collectionViewLayout:flowLayout];
	self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.collectionView.delegate = self;
	self.collectionView.pagingEnabled = YES;
	self.collectionView.dataSource = self;
	self.collectionView.showsHorizontalScrollIndicator = NO;
	self.collectionView.showsVerticalScrollIndicator = NO;
	[self.collectionView registerClass:[KATGFullScreenImageCell class] forCellWithReuseIdentifier:fullScreenImageCellIdentifier];
	[self.view addSubview:self.collectionView];
	
	KATGButton *closeButton = [[KATGButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 44.0f)];
	[closeButton setTitle:@"Done" forState:UIControlStateNormal];
	closeButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
	[closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:closeButton]];
	
	KATGButton *saveButton = [[KATGButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 44.0f)];
	[saveButton setTitle:@"Save" forState:UIControlStateNormal];
	saveButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
	[saveButton addTarget:self action:@selector(disclosureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:saveButton]];
	
	self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 44.0f)];
	self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	[self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
	[self.view addSubview:self.navigationBar];	
}

- (void)transitionFromImage:(KATGImage *)image inImageView:(UIImageView *)imageView animations:(void(^)())animations completion:(void(^)())completion;
{
	CGSize imageSize = imageView.image.size;
	if (!imageView.image)
	{
		imageSize = self.view.bounds.size;
	}
	
	CGRect initialRect = [self.view convertRect:imageView.frame fromView:imageView.superview];
	UIView *transitionContainerView = [[UIView alloc] initWithFrame:initialRect];
	transitionContainerView.clipsToBounds = YES;
	[self.view addSubview:transitionContainerView];
	
	UIImageView *transitionImageView = [[UIImageView alloc] initWithFrame:transitionContainerView.bounds];
	transitionImageView.image = imageView.image;
	transitionImageView.contentMode = UIViewContentModeScaleAspectFill;
	[transitionContainerView addSubview:transitionImageView];
	
	// Transitioning from aspect fill to aspect fit - figure out the new scale
	
	CGFloat imageAspect = imageSize.width / imageSize.height;
	CGFloat screenAspect = self.view.bounds.size.width / self.view.bounds.size.height;
	
	CGRect newImageRect = CGRectZero;
	
	if (imageAspect > screenAspect)
	{
		// scale by width
		newImageRect.size.width = self.view.bounds.size.width;
		newImageRect.size.height = self.view.bounds.size.width / imageAspect;
	}
	else
	{
		newImageRect.size.height = self.view.bounds.size.height;
		newImageRect.size.width = self.view.bounds.size.height * imageAspect;
	}
	
	NSInteger index = [self.images indexOfObject:image];
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
	
	self.collectionView.hidden = YES;
	
	self.backgroundView.alpha = 0.0f;
	
	[self.view bringSubviewToFront:self.navigationBar];

	self.navigationBar.alpha = 0.0f;
	CGFloat navigationBarScale = initialRect.size.width / self.view.bounds.size.width;
	self.navigationBar.transform = CGAffineTransformMakeScale(navigationBarScale, navigationBarScale);
	self.navigationBar.center = CGPointMake(CGRectGetMidX(initialRect), CGRectGetMinY(initialRect) - (navigationBarScale*44.0f));
	[self updateTitleWithImage:image];
	
	[UIView animateWithDuration:0.4f
						  delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.navigationBar.alpha = 1.0f;
						 self.navigationBar.transform = CGAffineTransformIdentity;
						 self.navigationBar.center = CGPointMake(CGRectGetMidX(self.view.bounds), 22.0f);
						 transitionContainerView.frame = self.view.bounds;
						 transitionImageView.bounds = newImageRect;
						 transitionImageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
						 self.backgroundView.alpha = 1.0f;
						 if (animations)
						 {
							 animations();
						 }
					 } completion:^(BOOL finished) {
						 self.collectionView.hidden = NO;
						 [self setNavigationBarVisible:YES animated:YES];
						 [transitionContainerView removeFromSuperview];
						 if (completion)
						 {
							 completion();
						 }
					 }];
	
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	KATGFullScreenImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:fullScreenImageCellIdentifier forIndexPath:indexPath];
	cell.imageView.image = nil;
	cell.delegate = self;
	KATGImage *image = self.images[indexPath.row];
	cell.currentImage = image;
	cell.isAccessibilityElement = YES;
	cell.accessibilityLabel = image.title;
	__weak KATGImage *weakImage = image;
	__weak KATGFullScreenImageCell *weakCell = cell;
	[[KATGImageCache imageCache] imageForURL:[NSURL URLWithString:cell.currentImage.media_url] size:CGSizeZero progressHandler:^(float progress) {
		//NSLog(@"Progress %f", progress);
	} completionHandler:^(UIImage *img, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([[weakImage objectID] isEqual:[weakCell.currentImage objectID]])
			{
				weakCell.imageView.image = img;
				[weakCell setupImageInScrollView];
				weakCell.activityIndicatorView.hidden = YES;
			}
		});
	}];
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return self.view.bounds.size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
	return CGSizeMake(IMAGE_GAP/2.0f, self.view.bounds.size.height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
	return CGSizeMake(IMAGE_GAP/2.0f, self.view.bounds.size.height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return IMAGE_GAP;
}

#pragma mark - Scrolling

- (void)updateTitle
{
	NSIndexPath *indexPath = [self.collectionView nearestIndexPathForContentOffset:self.collectionView.contentOffset];
	KATGImage *image = self.images[indexPath.row];
	[self updateTitleWithImage:image];
}

- (void)updateTitleWithImage:(KATGImage *)image
{
	self.navigationItem.title = image.title;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self setNavigationBarVisible:NO animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (decelerate)
	{
		return;
	}
	[self updateTitle];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self updateTitle];
}

#pragma mark -

- (void)setImages:(NSArray *)images
{
	NSAssert([[NSThread currentThread] isMainThread], @"Images must be set on main thread");
	_images = images;
	[self.collectionView reloadData];
}

- (void)close
{
	NSIndexPath *centerIndexPath = [self.collectionView indexPathForItemAtPoint:[self.collectionView convertPoint:self.view.center fromView:self.view.superview]];
	KATGFullScreenImageCell *centerCell = (KATGFullScreenImageCell *)[self.collectionView cellForItemAtIndexPath:centerIndexPath];
	
	UIView *collapseTargetView = [self.delegate imagesViewController:self viewToCollapseIntoForImage:centerCell.currentImage];
	CGRect collapseTargetFrame = [self.view convertRect:collapseTargetView.frame fromView:collapseTargetView.superview];
	
	CGRect initialImageRect = [self.view convertRect:centerCell.imageView.frame fromView:centerCell.imageView.superview];
	
	UIView *transitionContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
	transitionContainerView.clipsToBounds = YES;
	transitionContainerView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:transitionContainerView];
	
	UIImageView *transitionImageView = [[UIImageView alloc] initWithFrame:initialImageRect];
	transitionImageView.image = centerCell.imageView.image;
	transitionImageView.contentMode = UIViewContentModeScaleAspectFit;
	[transitionContainerView addSubview:transitionImageView];
	
	// Transitioning from aspect fit to aspect fill - figure out the new size
	CGFloat imageAspectRatio = centerCell.imageView.image.size.width / centerCell.imageView.image.size.height;
	if (!centerCell.imageView.image)
	{
		imageAspectRatio = 1.0f;
	}
	
	CGFloat newSize = collapseTargetFrame.size.width;
	CGRect newImageBounds = CGRectZero;
	if (imageAspectRatio > 1.0f)
	{
		// scale by height
		newImageBounds.size.height = newSize;
		newImageBounds.size.width = newSize * imageAspectRatio;
	}
	else
	{
		// scale by width
		newImageBounds.size.width = newSize;
		newImageBounds.size.height = newSize / imageAspectRatio;
	}
	
	self.collectionView.hidden = YES;
	[self.view bringSubviewToFront:self.navigationBar];	
	[self setNavigationBarVisible:NO animated:YES];
	
	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Dismissing image gallery", nil));
	[UIView animateWithDuration:0.4f
						  delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 
						 self.navigationBar.alpha = 0.0f;
						 CGFloat navigationBarScale = collapseTargetFrame.size.width / self.view.bounds.size.width;
						 self.navigationBar.transform = CGAffineTransformMakeScale(navigationBarScale, navigationBarScale);
						 self.navigationBar.center = CGPointMake(CGRectGetMidX(collapseTargetFrame), CGRectGetMinY(collapseTargetFrame) - (navigationBarScale*44.0f));
						 
						 transitionContainerView.frame = collapseTargetFrame;
						 transitionImageView.bounds = newImageBounds;
						 transitionImageView.center = CGPointMake(newSize/2, newSize/2);
						 self.backgroundView.alpha = 0.0f;
						 [self.delegate performAnimationsWhileImagesViewControllerIsClosing:self];
					 } completion:^(BOOL finished) {
						 [transitionContainerView removeFromSuperview];
						 [self.delegate closeImagesViewController:self];
					 }];
	
}

- (void)setNavigationBarVisible:(BOOL)visible animated:(BOOL)animated
{
	if (animated)
	{
		if (visible && self.navigationBar.hidden)
		{
			self.navigationBar.hidden = NO;
			self.navigationBar.alpha = 0.0f;
		}
		
		[UIView animateWithDuration:0.2f
						 animations:^{
							 self.navigationBar.alpha = visible ? 1.0f : 0.0f;
						 } completion:^(BOOL finished) {
							 if (!visible)
							 {
								 self.navigationBar.hidden = YES;
							 }
						 }];
	}
	else
	{
		self.navigationBar.hidden = !visible;
		self.navigationBar.alpha = 1.0f;
	}
}

#pragma mark - KATGFullScreenImageCellDelegate

- (void)didTapFullScreenImageCell:(KATGFullScreenImageCell *)cell
{
	[self setNavigationBarVisible:(self.navigationBar.hidden) animated:YES];
}

- (BOOL)katg_performAccessibilityEscape
{
	[self close];
	return YES;
}

#pragma mark - Save

- (void)disclosureButtonTapped:(id)sender
{
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Save image to camera roll", @""), nil];
	[self.actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSParameterAssert(actionSheet == self.actionSheet);
	self.actionSheet = nil;
	if (actionSheet.cancelButtonIndex == buttonIndex)
	{
		return;
	}
	
	self.navigationItem.leftBarButtonItem.enabled = NO;
	NSIndexPath *indexPath = [self.collectionView nearestIndexPathForContentOffset:self.collectionView.contentOffset];
	KATGImage *image = self.images[indexPath.row];
	[[KATGImageCache imageCache] imageForURL:[NSURL URLWithString:image.media_url] size:CGSizeZero progressHandler:^(float progress) {
		
	} completionHandler:^(UIImage *img, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			ALAssetsLibrary *library = [ALAssetsLibrary new]; 
			[library writeImageToSavedPhotosAlbum:[img CGImage] orientation:(ALAssetOrientation)[img imageOrientation] completionBlock:^(NSURL* assetURL, NSError* error) {
				if (error)
				{
					NSLog(@"%@", error);
				}
				else
				{
					
				}
				self.navigationItem.leftBarButtonItem.enabled = YES;
			}];
		});
	}];
}

@end
