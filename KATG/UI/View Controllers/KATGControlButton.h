//
//  KATGControlButton.h
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

#import <UIKit/UIKit.h>

@interface KATGControlButton : UIButton

// Default: 1.0f
@property (nonatomic) CGFloat leftBorderWidth;
@property (nonatomic) CGFloat rightBorderWidth;

// Default: 0.0f
@property (nonatomic) CGFloat topBorderWidth;
@property (nonatomic) CGFloat bottomBorderWidth;

// Default: [UIColor colorWithWhite:1.0f alpha:0.5f];
@property (strong, nonatomic) UIColor *leftBorderColor;

// Default: [UIColor colorWithWhite:0.0f alpha:0.1f];
@property (strong, nonatomic) UIColor *rightBorderColor;

// Default: [UIColor colorWithWhite:1.0f alpha:0.5f];
@property (strong, nonatomic) UIColor *topBorderColor;

// Default: [UIColor colorWithWhite:0.0f alpha:0.1f];
@property (strong, nonatomic) UIColor *bottomBorderColor;

@end
