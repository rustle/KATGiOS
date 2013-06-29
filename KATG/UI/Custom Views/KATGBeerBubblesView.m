//
//  KATGBeerBubblesView.m
//  KATG
//
//  Created by Timothy Donnelly on 5/1/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGBeerBubblesView.h"

@interface KATGBeerBubblesView ()
{
	// Why is this weak?
	__weak CAEmitterLayer *emitterLayer;
	BOOL _lightBubbles;
}

@end

@implementation KATGBeerBubblesView

+ (Class)layerClass
{
	return [CAEmitterLayer class];
}

- (id)initWithFrame:(CGRect)frame lightBubbles:(BOOL)lightBubbles
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_lightBubbles = lightBubbles;
		self.backgroundColor = [UIColor clearColor];
		emitterLayer = (CAEmitterLayer *)self.layer;
		[self setupBubbles];
	}
	return self;
}

- (void)setupBubbles
{
	emitterLayer.emitterShape = kCAEmitterLayerRectangle;
	emitterLayer.birthRate = 1.0f;
	
	CAEmitterCell *bubbleCell = [CAEmitterCell emitterCell];
	bubbleCell.contents = (__bridge id)[[UIImage imageNamed:(_lightBubbles ? @"light-bubble.png" : @"bubble.png")] CGImage];
	[bubbleCell setName:@"bubbleCell"];
	bubbleCell.birthRate = _lightBubbles ? 3.0f : 4.0f;
	bubbleCell.lifetime = _lightBubbles ? 2.0f : 3.0f;
	bubbleCell.lifetimeRange = 0;
	bubbleCell.velocity = 12;
	bubbleCell.velocityRange = 6;
	bubbleCell.yAcceleration = -3;
	bubbleCell.emissionLongitude = -M_PI_2;
	bubbleCell.emissionRange = M_PI / 8;
	bubbleCell.scale = 0.015f;
	bubbleCell.scaleSpeed = 0;
	bubbleCell.scaleRange = 0.005;
	bubbleCell.color = _lightBubbles ? [[UIColor colorWithWhite:1.0f alpha:0.4f] CGColor] : [[UIColor colorWithWhite:0.5f alpha:0.06f] CGColor];
	bubbleCell.alphaSpeed = _lightBubbles ? -0.2f : -0.02;
	
	
	CAEmitterCell *subBubbleCell = [CAEmitterCell emitterCell];
	subBubbleCell.contents = (__bridge id)[[UIImage imageNamed:(_lightBubbles ? @"light-bubble.png" : @"bubble.png")] CGImage];
	[subBubbleCell setName:@"subBubbleCell"];
	subBubbleCell.birthRate = _lightBubbles ? 10.0f : 4.0f;
	subBubbleCell.lifetime = _lightBubbles ? 2.0f : 3.0f;
	subBubbleCell.lifetimeRange = 0;
	subBubbleCell.velocity = 5;
	subBubbleCell.velocityRange = 6;
	subBubbleCell.yAcceleration = -5;
	subBubbleCell.emissionLongitude = 0.0f;
	subBubbleCell.emissionRange = M_PI_4;
	subBubbleCell.scale = 0.8f;
	subBubbleCell.scaleSpeed = 0;
	subBubbleCell.scaleRange = 0.2f;
	subBubbleCell.color = _lightBubbles ? [[UIColor colorWithWhite:1.0f alpha:0.5f] CGColor] : [[UIColor colorWithWhite:0.5f alpha:0.06f] CGColor];
	// subBubbleCell.alphaSpeed = _lightBubbles ? -0.2f : -0.02;
	bubbleCell.emitterCells = [NSArray arrayWithObject:subBubbleCell];
	
	emitterLayer.emitterCells = [NSArray arrayWithObject:bubbleCell];
}

- (void)setBubbleRect:(CGRect)bubbleRect
{
	_bubbleRect = bubbleRect;
	[emitterLayer setEmitterSize:bubbleRect.size];
	[emitterLayer setEmitterPosition:CGPointMake(CGRectGetMidX(bubbleRect), CGRectGetMidY(bubbleRect))];
}

@end
