//
//  KATGImage.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString *const KATGImageMediaURLAttributeName;
extern NSString *const KATGImageShowAttributeName;

@class KATGGuest, KATGShow;

@interface KATGImage : NSManagedObject

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *media_url;
@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) KATGGuest *guest;
@property (nonatomic, retain) KATGShow *show;

+ (NSString *)katg_entityName;

@end
