//
//  TDCollectionView.m
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

#import "TDCollectionView.h"

// Allow media timing function to solve for Y at time X
@interface CAMediaTimingFunction (TDAdditions)
- (CGFloat)solveForX:(CGFloat)x;
@end

@implementation CAMediaTimingFunction (TDAdditions)

double cubicFunctionValue(double a, double b, double c, double d, double x) {
	return (a*x*x*x)+(b*x*x)+(c*x)+d;
}

double cubicDerivativeValue(double a, double b, double c, double __unused d, double x) {
	// derivation of the cubic (a*x*x*x)+(b*x*x)+(c*x)+d
	return (3*a*x*x)+(2*b*x)+c;
}

double rootOfCubic(double a, double b, double c, double d, double startPoint) {
	// we use 0 as start point as the root will be in the interval [0,1]
	double x = startPoint;
	double lastX = 1;
	
	// approximate a root by using the Newton-Raphson method
	int y = 0;
	while (y <= 10 && fabs(lastX - x) > .00001f) {
		lastX = x;
		x = x - (cubicFunctionValue(a, b, c, d, x) / cubicDerivativeValue(a, b, c, d, x));
		y++;
	}
	return x;
}

- (CGFloat)solveForX:(CGFloat)x
{
	float a[2];
	float b[2];
	float c[2];
	float d[2];
	[self getControlPointAtIndex:0 values:a];
	[self getControlPointAtIndex:1 values:b];
	[self getControlPointAtIndex:2 values:c];
	[self getControlPointAtIndex:3 values:d];
	// look for t value that corresponds to provided x
	double t = rootOfCubic(-a[0]+3*b[0]-3*c[0]+d[0], 3*a[0]-6*b[0]+3*c[0], -3*a[0]+3*b[0], a[0]-x, x);
	// return corresponding y value
	double y = cubicFunctionValue(-a[1]+3*b[1]-3*c[1]+d[1], 3*a[1]-6*b[1]+3*c[1], -3*a[1]+3*b[1], a[1], t);
	return y;
}

@end


@interface TDCollectionView ()
{
	BOOL _animationInProgress;
	CGFloat _animationDuration;
	NSTimeInterval _startTime;
	CGPoint _startingContentOffset;
	CGPoint _deltaContentOffset;
}

@property (nonatomic, strong) CAMediaTimingFunction *currentTimingFunction;
@property (strong, nonatomic) CADisplayLink *displayLink;

@end

@implementation TDCollectionView

- (void)TDCollectionViewCommonInit
{
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(setNeedsDisplay)];
}

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
	self = [super initWithFrame:frame collectionViewLayout:layout];
	if (self)
	{
		[self TDCollectionViewCommonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self TDCollectionViewCommonInit];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self TDCollectionViewCommonInit];
	}
	return self;
}


- (void)scrollToContentOffset:(CGPoint)contentOffset duration:(NSTimeInterval)duration timingFunction:(CAMediaTimingFunction *)timingFunction
{
	if (_animationInProgress)
		return;
	
	_animationInProgress = YES;
	
	self.currentTimingFunction = timingFunction;
	
	_animationDuration = duration;
	_deltaContentOffset = CGPointMake(contentOffset.x-self.contentOffset.x, contentOffset.y-self.contentOffset.y);
	
	if (self.displayLink) {
		self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
		_displayLink.frameInterval = 1;
		[_displayLink addToRunLoop:[NSRunLoop currentRunLoop]
											 forMode:NSDefaultRunLoopMode];
	} else {
		self.displayLink.paused = NO;
	}
}

- (void)setContentOffset:(CGPoint)contentOffset
{
	[self cancelAnimation];
	return [super setContentOffset:contentOffset];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
	[self cancelAnimation];
	return [super setContentOffset:contentOffset animated:animated];
}

- (void)cancelAnimation
{
	self.displayLink.paused = YES;
	_animationInProgress = NO;
	_startTime = 0.0f;
}

- (void)tick:(CADisplayLink *)displayLink
{
	if (_startTime == 0.0)
	{
		_startTime = displayLink.timestamp;
		_startingContentOffset = self.contentOffset;
	}
	else
	{
		CGFloat elapsed = (CGFloat) ((displayLink.timestamp-_startTime) / _animationDuration);
		CGFloat deltaProgress = 0.0f;
		
		if (elapsed > 1)
		{
			deltaProgress = 1.0f;
		}
		else if (elapsed < 0)
		{
			deltaProgress = 0.0f;
		}
		else
		{
			deltaProgress = [self.currentTimingFunction solveForX:elapsed];
		}
		
		if (deltaProgress >= 1.0f) 
		{
			deltaProgress = 1.0f;
			self.displayLink.paused = YES;
			_animationInProgress = NO;
			_startTime = 0.0f;
		}
		CGPoint contentOffset = CGPointMake(_startingContentOffset.x + (_deltaContentOffset.x*deltaProgress), _startingContentOffset.y + (_deltaContentOffset.y*deltaProgress));
		[super setContentOffset:contentOffset];
	}
}

- (BOOL)isScrolling
{
	return [self isDragging] || [self isDecelerating] || _animationInProgress;
}

@end
