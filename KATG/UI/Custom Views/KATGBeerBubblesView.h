//
//  KATGBeerBubblesView.h
//  KATG
//
//  Created by Timothy Donnelly on 5/1/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGBeerBubblesView : UIView

- (id)initWithFrame:(CGRect)frame lightBubbles:(BOOL)lightBubbles;

@property (nonatomic) CGRect bubbleRect;

@end
