//
//  KATGTableViewController.m
//  KATG
//
//  Created by Doug Russell on 6/2/12.
//  Copyright 2012 (c) Doug Russell. All rights reserved.
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

#import "KATGTableViewController.h"

@interface KATGTableViewController ()
{
@private
	UITableViewStyle _tableViewStyle;
}
@end

@implementation KATGTableViewController

#pragma mark - Init/Dealloc

- (instancetype)initWithTableViewStyle:(UITableViewStyle)style
{
	self = [super initWithNibName:nil bundle:nil];
	if (self)
	{
		_tableViewStyle = style;
	}
	return self;
}

- (void)dealloc
{
	_tableView.delegate = nil;
	_tableView.dataSource = nil;
}

#pragma mark - View Life Cycle

- (void)loadView
{
	[super loadView];
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:_tableViewStyle];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	[self.view addSubview:self.tableView];
}

#pragma mark - 

- (void)reloadTableView
{
	if ([NSThread isMainThread])
	{
		[self.tableView reloadData];
	}
	else
	{
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
	}
}

- (void)selectFirstRow
{
	NSParameterAssert([NSThread isMainThread]);
	if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) 
	{
		NSIndexPath	*indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
		[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
		[self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
	}
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

@end
