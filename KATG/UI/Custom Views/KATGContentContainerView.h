//
//  KATGContentContainerView.h
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

//	Consists of a header, content area, and footer. Used as a container for show information.

#import <UIKit/UIKit.h>

@class KATGShowMetaView, TDRoundedShadowView;

@interface KATGContentContainerView : UIView

// Tracks size of the main view
@property (nonatomic, readonly) UIView *backgroundView;

// Height determined by headerHeight
@property (nonatomic, readonly) UIView *headerView;

// Height = main view height - headerHeight - footerHeight
@property (nonatomic, readonly) UIScrollView *contentView;

// Height determined by footerHeight
@property (nonatomic, readonly) UIView *footerView;

// These shadows overlap the content area from the header and footer
@property (nonatomic, readonly) TDRoundedShadowView *headerShadowView;
@property (nonatomic, readonly) TDRoundedShadowView *footerShadowView;

// Header/footer metrics
@property (nonatomic) CGFloat headerHeight;
@property (nonatomic) CGFloat footerHeight;

@end
