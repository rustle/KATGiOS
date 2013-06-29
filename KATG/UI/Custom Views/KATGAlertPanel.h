//
//  KATGAlertPanel.h
//  KATG
//
//  Created by Doug Russell on 4/28/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGAlertPanel : UIView

@property (copy, nonatomic) void (^layoutBlock)(KATGAlertPanel *panel);

+ (instancetype)panelWithText:(NSString *)text;
- (void)showFromView:(UIView *)view completionBlock:(void (^)(void))completionBlock;
- (void)hideWithCompletionBlock:(void (^)(void))completionBlock;

@end
