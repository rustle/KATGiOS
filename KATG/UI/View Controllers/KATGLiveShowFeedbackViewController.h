//
//  KATGLiveShowFeedbackViewController.h
//  KATG
//
//  Created by Timothy Donnelly on 5/2/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGViewController.h"

@protocol KATGLiveShowFeedbackViewControllerDelegate;

@interface KATGLiveShowFeedbackViewController : KATGViewController
@property (weak, nonatomic) id<KATGLiveShowFeedbackViewControllerDelegate> delegate;
@end

@protocol KATGLiveShowFeedbackViewControllerDelegate <NSObject>
- (void)closeLiveShowFeedbackViewController:(KATGLiveShowFeedbackViewController *)liveShowFeedbackViewController;
@end