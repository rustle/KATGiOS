//
//  KATGImageScalingOperation.m
//  KATG
//
//  Created by Doug Russell on 3/14/13.
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

#import "KATGImageScalingOperation.h"

@interface UIImage (KATGScaling)
// Opaque image scaled proportionally to size in points with the scale of the main screen
// No consideration is given to rotation
- (UIImage *)katg_imageScaledToSize:(CGSize)size;
@end

@interface KATGImageScalingOperation ()
@property (nonatomic) UIImage *scaledImage;
@end

@implementation KATGImageScalingOperation

- (instancetype)initWithImage:(UIImage *)image targetSize:(CGSize)targetSize
{
	self = [super init];
	if (self)
	{
		NSParameterAssert(image);
		NSParameterAssert(!CGSizeEqualToSize(CGSizeZero, targetSize));
		_targetSize = targetSize;
		_image = image;
	}
	return self;
}

- (void)main
{
	@autoreleasepool {
		self.scaledImage = [self.image katg_imageScaledToSize:self.targetSize];
	}
}

@end

@implementation UIImage (KATGScaling)

CG_INLINE CGFloat GetScaleForProportionalResize(CGSize theSize, CGSize intoSize, bool onlyScaleDown, bool maximize)
{
	CGFloat sx = theSize.width;
	CGFloat sy = theSize.height;
	CGFloat dx = intoSize.width;
	CGFloat dy = intoSize.height;
	CGFloat scale	= 1.0f;
	if (sx != 0 && sy != 0)
	{
		dx = dx / sx;
		dy = dy / sy;
		// if maximize is true, take LARGER of the scales, else smaller
		if( maximize ) 
		{
			scale = (dx > dy) ? dx : dy;
		}
		else
		{
			scale = (dx < dy) ? dx : dy;
		}
		if (scale > 1 && onlyScaleDown)	// reset scale
		{
			scale = 1;
		}
	}
	else
	{
		scale = 0;
	}
	return scale;
}

- (UIImage *)katg_imageScaledToSize:(CGSize)size
{
	if (CGSizeEqualToSize(size, [self size]))
	{
		return self;
	}
	CGFloat scale = GetScaleForProportionalResize([self size], size, true, false);
	CGSize scaledSize = CGSizeMake(floorf([self size].width * scale), floorf([self size].height * scale));
	UIGraphicsBeginImageContextWithOptions(scaledSize, YES, 0);
	[self drawInRect:CGRectMake(0.0f, 0.0f, scaledSize.width, scaledSize.height)];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

@end
