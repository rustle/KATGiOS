//
//  KATGDownloadEpisodeCell.h
//  KATG
//
//  Created by Tim Donnelly on 4/10/13.
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

#import <UIKit/UIKit.h>
#import "KATGShowCell.h"

typedef NS_ENUM(NSUInteger, KATGDownloadEpisodeCellState) {
	KATGDownloadEpisodeCellStateUnknown,
	KATGDownloadEpisodeCellStateActive,
	KATGDownloadEpisodeCellStateDownloading,
	KATGDownloadEpisodeCellStateDownloaded,
	KATGDownloadEpisodeCellStateDisabled,
};

@protocol KATGDownloadEpisodeCellDelegate;

@interface KATGDownloadEpisodeCell : KATGShowCell

@property (weak, nonatomic) id<KATGDownloadEpisodeCellDelegate> delegate;
@property (nonatomic) KATGDownloadEpisodeCellState state;
@property (nonatomic) CGFloat progress;

@end

@protocol KATGDownloadEpisodeCellDelegate <NSObject>

- (void)downloadButtonPressed:(KATGDownloadEpisodeCell *)cell;

@end