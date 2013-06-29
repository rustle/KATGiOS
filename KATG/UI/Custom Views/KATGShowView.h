//
//  KATGShowView.h
//  KATG
//
//  Created by Timothy Donnelly on 12/6/12.
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

// Adds some show specific UI elements to KATGContentContainerView

#import <UIKit/UIKit.h>
#import "KATGContentContainerView.h"

@class KATGButton;

@interface KATGShowView : KATGContentContainerView

// Located in the header
@property (strong, readonly) UILabel *showNumberLabel;
@property (strong, readonly) UILabel *showTitleLabel;
@property (strong, readonly) KATGButton *closeButton;

// Text columns in the footer (used for collapsed state)
@property (strong, nonatomic) UIView *showMetaView;
@property (strong, nonatomic, readonly) UILabel *showMetaFirstColumn;
@property (strong, nonatomic, readonly) UILabel *showMetaSecondColumn;
@property (strong, nonatomic, readonly) UILabel *showMetaThirdColumn;

// This determines if the close button's width is taken into account when laying
// out the items in the header.
@property (nonatomic, getter=isCloseButtonVisible) BOOL closeButtonVisible;

@end
