//
//  KATGControlButton.m
//  KATG
//
//  Created by Timothy Donnelly on 12/12/12.
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

#import "KATGControlButton.h"

@implementation KATGControlButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		[self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		
		_leftBorderWidth = _rightBorderWidth = 1.0f / [[UIScreen mainScreen] scale];
		_topBorderWidth = _bottomBorderWidth = 0.0f;
		
		_leftBorderColor = _topBorderColor = [UIColor colorWithWhite:1.0f alpha:0.7f];
		_rightBorderColor = _bottomBorderColor = [UIColor colorWithWhite:0.0f alpha:0.2f];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	UIBezierPath *leftBorderPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, 0.0f, self.leftBorderWidth, rect.size.height)];
	[self.leftBorderColor set];
	[leftBorderPath fill];
	
	UIBezierPath *rightBorderPath = [UIBezierPath bezierPathWithRect:CGRectMake(rect.size.width-self.rightBorderWidth, 0.0f, self.rightBorderWidth, rect.size.height)];
	[self.rightBorderColor set];
	[rightBorderPath fill];
	
	UIBezierPath *topBorderPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, 0.0f, rect.size.width, self.topBorderWidth)];
	[self.topBorderColor set];
	[topBorderPath fill];
	
	UIBezierPath *bottomBorderPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, rect.size.height - self.bottomBorderWidth, rect.size.width, self.bottomBorderWidth)];
	[self.bottomBorderColor set];
	[bottomBorderPath fill];
}

@end
