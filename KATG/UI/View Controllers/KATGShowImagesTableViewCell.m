//
//  KATGShowImagesTableViewCell.m
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

#import "KATGShowImagesTableViewCell.h"
#import "KATGShowImageThumbnailCell.h"
#import "KATGImageCache.h"
#import "KATGImage.h"

#define SIDE_MARGIN 20.0f
#define VERTICAL_MARGIN 4.0f
#define INTER_IMAGE_GAP 10.0f

static NSString *imageThumbnailCellIdentifier = @"imageThumbnailCellIdentifier";

@interface KATGShowImagesTableViewCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, KATGShowImageThumbnailCellDelegate>
@property (strong, nonatomic) UICollectionView *collectionView;
@end

@implementation KATGShowImagesTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self)
	{
		UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
		flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		flowLayout.minimumInteritemSpacing = 0.0f;
		flowLayout.minimumLineSpacing = 0.0f;
		_collectionView = [[UICollectionView alloc] initWithFrame:self.contentView.bounds collectionViewLayout:flowLayout];
		_collectionView.delegate = self;
		_collectionView.dataSource = self;
		_collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		_collectionView.backgroundColor = [UIColor clearColor];
		[_collectionView registerClass:[KATGShowImageThumbnailCell class] forCellWithReuseIdentifier:imageThumbnailCellIdentifier];
		[self.contentView addSubview:_collectionView];
		
		_collectionView.isAccessibilityElement = YES;
		_collectionView.accessibilityLabel = NSLocalizedString(@"Image gallery", nil);
		_collectionView.accessibilityHint = NSLocalizedString(@"Double tap for full screen image gallery", nil);
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self.collectionView reloadData];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	KATGShowImageThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageThumbnailCellIdentifier forIndexPath:indexPath];
	KATGImage *image = self.images[indexPath.row];
	cell.currentImage = image;
	cell.imageView.image = nil;
	cell.delegate = self;
	NSURL *url = [NSURL URLWithString:cell.currentImage.media_url];
	NSManagedObjectID *objectID = [image objectID];
	__weak KATGShowImageThumbnailCell *weakThumbCell = cell;
	[[KATGImageCache imageCache] imageForURL:url size:cell.imageView.bounds.size progressHandler:nil completionHandler:^(UIImage *img, NSError *error) {
		[weakThumbCell assignImage:img requestedForObjectID:objectID];
	}];
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat size = collectionView.frame.size.height - (VERTICAL_MARGIN*2);
	return CGSizeMake(size, size);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return INTER_IMAGE_GAP;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return INTER_IMAGE_GAP;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
	return CGSizeMake(SIDE_MARGIN, collectionView.frame.size.height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
	return CGSizeMake(SIDE_MARGIN, collectionView.frame.size.height);
}

- (void)setImages:(NSArray *)images
{
	NSParameterAssert([NSThread isMainThread]);
	if (_images != images)
	{
		_images = images;
		[self.collectionView reloadData];
	}
}

- (void)scrollToImageAtIndex:(NSInteger)index animated:(BOOL)animated
{
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
}

- (UIView *)viewForImageAtIndex:(NSInteger)index
{
	KATGShowImageThumbnailCell *thumbCell = (KATGShowImageThumbnailCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
	return thumbCell.imageView;
}

#pragma mark - KATGShowImageThumbnailCellDelegate

- (void)imageThumbnailCellWasTapped:(KATGShowImageThumbnailCell *)thumbnailCell
{
	[self.delegate showImagesCell:self thumbnailWasTappedForImage:thumbnailCell.currentImage inImageView:thumbnailCell.imageView];
}

@end
