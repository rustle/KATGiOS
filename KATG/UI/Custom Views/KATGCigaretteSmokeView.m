//
//  KATGCigaretteSmokeView.m
//  KATG
//
//  Created by Timothy Donnelly on 5/1/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGCigaretteSmokeView.h"

#define GLOW_HUE 0.074

@interface KATGCigaretteGlowView : UIView
@property (nonatomic) CGFloat strength;
@end

@implementation KATGCigaretteGlowView

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	UIColor *glowColor = [UIColor colorWithHue:GLOW_HUE saturation:0.858 brightness:0.992 alpha:1];
	
	[glowColor setFill];
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 2.0f, [glowColor CGColor]);
	[[UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, rect.size.width/4, rect.size.height/4)] fill];
}

@end

@interface KATGCigaretteSmokeView ()
{
	// Why is this weak?
	__weak CAEmitterLayer *emitterLayer;
	CGFloat lastAngle;
	CGFloat lastBirthRate;
}

@property (strong, nonatomic) KATGCigaretteGlowView *glowView;

@end

@implementation KATGCigaretteSmokeView

+ (Class)layerClass
{
	return [CAEmitterLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		emitterLayer = (CAEmitterLayer*)self.layer;
		
		_glowSize = CGSizeMake(4.0f, 6.0f);
		
		_glowView = [[KATGCigaretteGlowView alloc] initWithFrame:CGRectZero];
		[self addSubview:_glowView];
		
		[self setupSmoke];
	}
	return self;
}

- (void)setupSmoke
{
	lastAngle = -M_PI / 2; // up
	lastBirthRate = 20.0f;
	
	emitterLayer.emitterShape = kCAEmitterLayerPoint;
	
	CAEmitterCell *smokeCell = [CAEmitterCell emitterCell];
	smokeCell.contents = (__bridge id)[[UIImage imageNamed:@"cigarette-smoke.png"] CGImage];
	[smokeCell setName:@"cigaretteSmokeCell"];
	smokeCell.birthRate = lastBirthRate;
	smokeCell.lifetime = 10.0;
	smokeCell.lifetimeRange = 0;
	smokeCell.velocity = 6;
	smokeCell.velocityRange = 2;
	smokeCell.yAcceleration = -4;
	smokeCell.emissionLongitude = lastAngle;
	smokeCell.emissionRange = M_PI / 20;
	smokeCell.scale = 0.02f;
	smokeCell.scaleSpeed = 0.025;
	smokeCell.scaleRange = 0.01;
	smokeCell.spin = M_PI/10;
	smokeCell.spinRange = M_PI / 20;
	smokeCell.color = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1] CGColor];
	smokeCell.alphaSpeed = -0.02;
	emitterLayer.emitterCells = [NSArray arrayWithObject:smokeCell];
	
	emitterLayer.birthRate = 1.0f;
	
	[self randomizeSmoke];
}

- (void)setOrigin:(CGPoint)origin
{
	_origin = origin;
	emitterLayer.emitterPosition = origin;
	[self setNeedsLayout];
}

- (void)setGlowSize:(CGSize)glowSize
{
	_glowSize = glowSize;
	[self setNeedsLayout];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.glowView.bounds = CGRectMake(0.0f, 0.0f, self.glowSize.width, self.glowSize.height);
	self.glowView.center = self.origin;
}

CGFloat randomBetweenF(CGFloat min, CGFloat max)
{
	CGFloat difference = max - min;
	CGFloat result = ((float)(arc4random() % (RAND_MAX - 1)) / RAND_MAX) * difference;
	result += min;
	return result;
}

- (void)randomizeSmoke
{
	CGFloat angleRange = M_PI/8;
	CGFloat angle = randomBetweenF(-angleRange, angleRange);
	angle += (-M_PI/2); // Orient to up
	
	CGFloat intensity = randomBetweenF(.1f, 1.0f);
	
	CGFloat birthRate = intensity * 15.0f;
	
	CGFloat duration = randomBetweenF(0.2f, 2.0f);
	
	[CATransaction begin];
	
	[CATransaction setCompletionBlock:^{
		[self performSelector:@selector(randomizeSmoke) withObject:nil afterDelay:0.0f];
	}];
	
	CABasicAnimation *angleAnimation =[CABasicAnimation animationWithKeyPath:@"emitterCells.cigaretteSmokeCell.emissionLongitude"];
	angleAnimation.duration = duration;
	angleAnimation.fromValue = @(lastAngle);
	angleAnimation.toValue = @(angle);
	angleAnimation.repeatCount = 1;
	[emitterLayer addAnimation:angleAnimation forKey:@"angle"];
	
	CABasicAnimation *birthrateAnimation =[CABasicAnimation animationWithKeyPath:@"emitterCells.cigaretteSmokeCell.birthRate"];
	birthrateAnimation.duration = duration;
	birthrateAnimation.fromValue = @(lastBirthRate);
	birthrateAnimation.toValue = @(birthRate);
	birthrateAnimation.repeatCount = 1;
	[emitterLayer addAnimation:angleAnimation forKey:@"birthrateAnimation"];

	CABasicAnimation *intensityAnimation =[CABasicAnimation animationWithKeyPath:@"opacity"];
	intensityAnimation.duration = duration;
	intensityAnimation.fromValue = @(self.glowView.layer.opacity);
	intensityAnimation.toValue = @(intensity);
	intensityAnimation.repeatCount = 1;
	[self.glowView.layer addAnimation:intensityAnimation forKey:@"opacityAnimation"];
	
	[CATransaction commit];
	
	[emitterLayer setValue:@(angle) forKeyPath:@"emitterCells.cigaretteSmokeCell.emissionLongitude"];
	[emitterLayer setValue:@(birthRate) forKeyPath:@"emitterCells.cigaretteSmokeCell.birthRate"];
	self.glowView.layer.opacity = intensity;
	
	lastAngle = angle;
	lastBirthRate = birthRate;
}

@end
