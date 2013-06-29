//
//  KATGAppDelegate.m
//  KATG
//
//  Created by Doug Russell on 8/26/12.
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

#import "KATGAppDelegate.h"
#import "KATGAudioSessionManager.h"
#import "KATGMainViewController.h"
#import "UIColor+KATGColors.h"
#import "KATGPushRegistration.h"

@protocol KATGNavBar7 <NSObject>

- (void)setTintColor:(UIColor *)color;

@end

@interface KATGAppDelegate ()
- (void)setupAppearance;
@end

@implementation KATGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	KATGConfigureAudioSessionState(KATGAudioSessionStateAmbient);
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor blackColor];
	[self setupAppearance];
	self.window.rootViewController = [KATGMainViewController new];
	[self.window makeKeyAndVisible];
	
	CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
	});
	
	return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	KATGPushRegistration *registration = [KATGPushRegistration sharedInstance];
	registration.deviceToken = deviceToken;
	[registration sendToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"Failed %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	// TODO: Show alert
}

- (void)setupAppearance
{
	[[UINavigationBar appearance] setBackgroundColor:[UIColor katg_whitishColor]];
	if ([[UINavigationBar class] instancesRespondToSelector:@selector(setTintColor:)])
	{
		[(id<KATGNavBar7>)[UINavigationBar appearance] setTintColor:[UIColor katg_whitishColor]];
	}
	[[UINavigationBar appearance] setBackgroundColor:[UIColor katg_whitishColor]];
	[[UINavigationBar appearance] setTitleTextAttributes:@{
								UITextAttributeTextColor:[UIColor katg_titleTextColor],
						  UITextAttributeTextShadowColor:[UIColor whiteColor],
						 UITextAttributeTextShadowOffset:[NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
									 UITextAttributeFont:[UIFont boldSystemFontOfSize:0.0f]
	 }];
	
}

@end
