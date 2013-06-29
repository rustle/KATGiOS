//
//  KATGCollectionViewController.m
//  KATG
//
//  Created by Tim Donnelly on 9/22/12.
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

#import "KATGCollectionViewController.h"

@interface KATGCollectionViewController ()

@end

@implementation KATGCollectionViewController

#pragma mark - Object Life Cycle

- (void)dealloc
{
	_collectionView.delegate = nil;
	_collectionView.dataSource = nil;
}

#pragma mark - View Life Cycle

- (UICollectionView *)collectionView
{
	if (_collectionView == nil && [self isViewLoaded])
	{
		_collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:[self newCollectionViewLayout]];
		_collectionView.backgroundColor = [UIColor clearColor];
		_collectionView.delegate = self;
		_collectionView.dataSource = self;
		_collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[self.view insertSubview:_collectionView atIndex:0];
	}
	return _collectionView;
}

- (UICollectionViewLayout *)newCollectionViewLayout
{
	// Must be overridden by subclass to provide a more useful layout than the abstract UICollectionViewLayout
	return [UICollectionViewLayout new];
}

#pragma mark - Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

@end
