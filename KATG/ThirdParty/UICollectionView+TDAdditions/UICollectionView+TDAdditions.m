//
//  UICollectionView+TDAdditions.m
//
//  Created by Timothy Donnelly on 12/8/12.
//  Copyright (c) 2012 Timothy Donnelly. All rights reserved.
//
// This source code is licenced under The MIT License:
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "UICollectionView+TDAdditions.h"

@implementation UICollectionView (TDAdditions)

- (NSInteger)closestSectionForContentOffset:(CGPoint)contentOffset
{
	NSInteger closestSection = 0;
	CGFloat closestSectionDistance = CGFLOAT_MAX;
	for (int i=0; i < [self numberOfSections]; i++)
	{
		if ([self numberOfItemsInSection:i] > 0)
		{
			NSIndexPath *firstItemIndexPath = [NSIndexPath indexPathForItem:0 inSection:i];
			UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:firstItemIndexPath];
			CGFloat dx = (contentOffset.x - attributes.frame.origin.x);
			CGFloat dy = (contentOffset.y - attributes.frame.origin.y);
			CGFloat dist = sqrt(dx*dx + dy*dy);
			if (dist < closestSectionDistance)
			{
				closestSection = i;
				closestSectionDistance = dist;
			}
		}
	}
	return closestSection;
}

- (NSIndexPath *)nearestIndexPathForContentOffset:(CGPoint)contentOffset
{
	NSIndexPath *nearestIndexPath;
	CGFloat nearestDistance = CGFLOAT_MAX;
	
	// Find cell closest to center of the screen
	for (UICollectionViewCell *cell in [self visibleCells])
	{
		CGFloat dx = ((self.frame.size.width/2)+contentOffset.x) - (cell.frame.origin.x+(cell.frame.size.width/2));
		CGFloat dy = ((self.frame.size.height/2)+contentOffset.y) - (cell.frame.origin.y+(cell.frame.size.height/2));
		CGFloat dist = sqrt(dx*dx + dy*dy);
		if (dist < nearestDistance)
		{
			nearestIndexPath = [self indexPathForCell:cell];
			nearestDistance = dist;
		}
	}
	return nearestIndexPath;
}

@end
