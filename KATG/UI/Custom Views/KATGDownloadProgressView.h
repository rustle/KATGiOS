//
//  KATGDownloadProgressView.h
//  KATG
//
//  Created by Timothy Donnelly on 4/30/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	KATGDownloadProgressViewStateNotDownloaded,
	KATGDownloadProgressViewStateDownloading,
	KATGDownloadProgressViewStateDownloaded
} KATGDownloadProgressViewState;

@interface KATGDownloadProgressView : UIView

@property (nonatomic) KATGDownloadProgressViewState currentState;

@property (nonatomic) double downloadProgress;

@property (strong, nonatomic) UIColor *downloadRingBackgroundColor;
@property (strong, nonatomic) UIColor *downloadRingForegroundColor;

@property (strong, nonatomic) UIColor *downloadArrowColor;

@property (strong, nonatomic) UIColor *checkColor;



@end
