//
//  KATGChatViewController.m
//  KATG
//
//  Created by Timothy Donnelly on 9/24/12.
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

#import "KATGChatViewController.h"

@interface KATGChatViewController ()
@property (nonatomic, strong)UIWebView *webView;
@end

@implementation KATGChatViewController

#pragma mark - Object Life Cycle

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self.navigationItem.title = @"Chat";
		self.title = @"Chat";
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];
	}
	return self;
}

- (void)dealloc
{
	self.webView = nil;
}

#pragma mark - View Life Cycle

- (void)loadView
{
	[super loadView];
	self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.webView.scalesPageToFit = YES;
	[self.view addSubview:self.webView];
	
	NSURL *url = [NSURL URLWithString:kKATGChatURLString];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	[self.webView loadRequest:requestObj];
}

- (void)close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
