//
//  KATGImagesViewController.h
//  KATG
//
//  Created by Tim Donnelly on 3/9/13.
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

#import "KATGViewController.h"

@class KATGImage, KATGImagesViewController;

@protocol KATGImagesViewControllerDelegate <NSObject>
- (void)closeImagesViewController:(KATGImagesViewController *)viewController;
- (UIView *)imagesViewController:(KATGImagesViewController *)viewController viewToCollapseIntoForImage:(KATGImage *)image;
- (void)performAnimationsWhileImagesViewControllerIsClosing:(KATGImagesViewController *)viewController; // Called within animation block
@end

@interface KATGImagesViewController : KATGViewController

@property (nonatomic) NSArray *images;
@property (weak, nonatomic) id <KATGImagesViewControllerDelegate> delegate;

- (void)transitionFromImage:(KATGImage *)image inImageView:(UIImageView *)imageView animations:(void(^)())animations completion:(void(^)())completion;

@end
