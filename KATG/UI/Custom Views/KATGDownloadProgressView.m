//
//  KATGDownloadProgressView.m
//  KATG
//
//  Created by Timothy Donnelly on 4/30/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGDownloadProgressView.h"

#define DOWNLOAD_RING_WIDTH 4.0f
#define CHECK_WIDTH 6.0f

@interface KATGDownloadProgressView ()

@end

@implementation KATGDownloadProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
			_currentState = KATGDownloadProgressViewStateNotDownloaded;
			self.backgroundColor = [UIColor clearColor];
			_downloadRingBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
			_downloadRingForegroundColor = [UIColor colorWithRed:0.262745 green:0.450980 blue:0.207843 alpha:1.0];
			_downloadArrowColor = _checkColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
			[self setCurrentState:KATGDownloadProgressViewStateNotDownloaded];
    }
    return self;
}

- (void)setCurrentState:(KATGDownloadProgressViewState)currentState
{
	_currentState = currentState;
	
	switch (currentState)
	{
		case KATGDownloadProgressViewStateNotDownloaded:
		{
			break;
		}
		case KATGDownloadProgressViewStateDownloading:
		{
			break;
		}
		case KATGDownloadProgressViewStateDownloaded:
		{
			break;
		}
	}
	[self setNeedsDisplay];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
}

- (void)setDownloadProgress:(double)downloadProgress
{
	_downloadProgress = downloadProgress;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	if (self.currentState == KATGDownloadProgressViewStateDownloading)
	{
		CGContextSaveGState(context);
		
		// Clip
		UIBezierPath *clippingPath = [UIBezierPath bezierPathWithOvalInRect:rect];
		[clippingPath appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, DOWNLOAD_RING_WIDTH, DOWNLOAD_RING_WIDTH)]];
		clippingPath.usesEvenOddFillRule = YES;
		[clippingPath addClip];
		
		// Background
		[self.downloadRingBackgroundColor setFill];
		[[UIBezierPath bezierPathWithRect:rect] fill];
		
		// Foreground
		UIBezierPath *progressPath = [UIBezierPath bezierPath];
		CGPoint centerPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
		[progressPath moveToPoint:centerPoint];
		[progressPath addArcWithCenter:centerPoint
														radius:CGRectGetMidY(rect)
												startAngle:-M_PI/2
													endAngle:M_PI*self.downloadProgress*2 - (M_PI/2)
												 clockwise:YES];
		[progressPath closePath];
		[self.downloadRingForegroundColor setFill];
		[progressPath fill];
		
		// Shadow
		UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(rect, -40.0f, -40.0f)];
		[shadowPath appendPath:[UIBezierPath bezierPathWithOvalInRect:rect]];
		[shadowPath appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, DOWNLOAD_RING_WIDTH, DOWNLOAD_RING_WIDTH)]];
		shadowPath.usesEvenOddFillRule = YES;
		CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 2.0f, [[UIColor colorWithWhite:0.0f alpha:1.0f] CGColor]);
		[[UIColor colorWithWhite:0.0f alpha:0.2f] setFill];
		[shadowPath fill];
		
		CGContextRestoreGState(context);
	}
	else if (self.currentState == KATGDownloadProgressViewStateNotDownloaded)
	{
		CGContextSaveGState(context);
		
		// Arrow
		
		CGRect arrowRect = rect;
		arrowRect = CGRectInset(arrowRect, 4.0f, 4.0f);
		
		if (arrowRect.size.width > arrowRect.size.height)
		{
			arrowRect.origin.x += (arrowRect.size.width - arrowRect.size.height) / 2;
			arrowRect.size.width = arrowRect.size.height;
		}
		else if (arrowRect.size.height > arrowRect.size.width)
		{
			arrowRect.origin.y += (arrowRect.size.height - arrowRect.size.width) / 2;
			arrowRect.size.height = arrowRect.size.width;
		}
		
		// Arrow Path		
		CGFloat arrowTailHeight = arrowRect.size.height * 0.5f;
		UIBezierPath *arrowPath = [UIBezierPath bezierPath];
		[arrowPath moveToPoint:CGPointMake(CGRectGetMinX(arrowRect) + arrowRect.size.width/4,
																			CGRectGetMinY(arrowRect) + 0.0f)];
		[arrowPath addLineToPoint:CGPointMake(CGRectGetMaxX(arrowRect) - arrowRect.size.width/4,
																					CGRectGetMinY(arrowRect) + 0.0f)];
		[arrowPath addLineToPoint:CGPointMake(CGRectGetMaxX(arrowRect) - arrowRect.size.width/4,
																					CGRectGetMinY(arrowRect) + arrowTailHeight)];
		[arrowPath addLineToPoint:CGPointMake(CGRectGetMaxX(arrowRect),
																					CGRectGetMinY(arrowRect) + arrowTailHeight)];
		[arrowPath addLineToPoint:CGPointMake(CGRectGetMidX(arrowRect),
																					CGRectGetMaxY(arrowRect))];
		[arrowPath addLineToPoint:CGPointMake(CGRectGetMinX(arrowRect),
																					CGRectGetMinY(arrowRect) + arrowTailHeight)];
		[arrowPath addLineToPoint:CGPointMake(CGRectGetMinX(arrowRect) + arrowRect.size.width/4,
																					CGRectGetMinY(arrowRect) + arrowTailHeight)];
		[arrowPath addLineToPoint:CGPointMake(CGRectGetMinX(arrowRect) + arrowRect.size.width/4,
																					CGRectGetMinY(arrowRect))];
		[arrowPath closePath];
		[arrowPath addClip];
		
		
		[self.downloadArrowColor setFill];
		[[UIBezierPath bezierPathWithRect:arrowRect] fill];
		
		UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(arrowRect, -40.0f, -40.0f)];
		[shadowPath appendPath:arrowPath];
		shadowPath.usesEvenOddFillRule = YES;
		CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 2.0f, [[UIColor colorWithWhite:0.0f alpha:1.0f] CGColor]);
		[[UIColor colorWithWhite:0.0f alpha:0.2f] setFill];
		[shadowPath fill];
		
		CGContextRestoreGState(context);
	}
	else if (self.currentState == KATGDownloadProgressViewStateDownloaded)
	{
		CGContextSaveGState(context);
		
		CGRect checkRect = rect;
		checkRect = CGRectInset(checkRect, 4.0f, 4.0f);
		checkRect.origin.y = 2.0f;
		CGPoint checkRectCenter = CGPointMake(CGRectGetMidX(checkRect), CGRectGetMidY(checkRect));
		checkRect.size.width = checkRect.size.height * 0.66f;
		checkRect.origin.x = checkRectCenter.x - (checkRect.size.width/2);
		
		
		// Arrow Path
		UIBezierPath *checkPath = [UIBezierPath bezierPath];
		[checkPath moveToPoint:CGPointMake(CGRectGetMinX(checkRect),
																			 CGRectGetMaxY(checkRect))];
		[checkPath addLineToPoint:CGPointMake(CGRectGetMaxX(checkRect),
																					CGRectGetMaxY(checkRect))];
		[checkPath addLineToPoint:CGPointMake(CGRectGetMaxX(checkRect),
																					CGRectGetMinY(checkRect))];
		[checkPath addLineToPoint:CGPointMake(CGRectGetMaxX(checkRect) - CHECK_WIDTH,
																					CGRectGetMinY(checkRect))];
		[checkPath addLineToPoint:CGPointMake(CGRectGetMaxX(checkRect) - CHECK_WIDTH,
																					CGRectGetMaxY(checkRect) - CHECK_WIDTH)];
		[checkPath addLineToPoint:CGPointMake(CGRectGetMinX(checkRect),
																					CGRectGetMaxY(checkRect) - CHECK_WIDTH)];

		[checkPath closePath];
		
		// Calculate scale to fit rotated check in container
		CGAffineTransform checkTransform = CGAffineTransformMakeTranslation(-CGRectGetMidX(checkRect), -CGRectGetMidY(checkRect));
		checkTransform = CGAffineTransformRotate(checkTransform, M_PI/4);
		CGFloat checkRectSize = MAX(checkRect.size.width, checkRect.size.height);
		CGRect transformedCheckRect = CGRectApplyAffineTransform(checkRect, checkTransform);
		CGFloat transformedCheckSize = MAX(transformedCheckRect.size.width, transformedCheckRect.size.height);
		CGFloat scale = checkRectSize / transformedCheckSize;
		
		[checkPath applyTransform:CGAffineTransformMakeTranslation(-CGRectGetMidX(checkRect), -CGRectGetMidY(checkRect))];
		[checkPath applyTransform:CGAffineTransformMakeRotation(M_PI/4)];
		[checkPath applyTransform:CGAffineTransformMakeScale(scale, scale)];
		[checkPath applyTransform:CGAffineTransformMakeTranslation(CGRectGetMidX(checkRect), CGRectGetMidY(checkRect))];
		

		
		[checkPath addClip];
		
		[self.downloadArrowColor setFill];
		[[UIBezierPath bezierPathWithRect:rect] fill];
		
		// Shadow
		UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(rect, -40.0f, -40.0f)];
		[shadowPath appendPath:checkPath];
		shadowPath.usesEvenOddFillRule = YES;
		CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 2.0f, [[UIColor colorWithWhite:0.0f alpha:1.0f] CGColor]);
		[[UIColor colorWithWhite:0.0f alpha:0.2f] setFill];
		[shadowPath fill];
		
		CGContextRestoreGState(context);
	}

	
}


@end
