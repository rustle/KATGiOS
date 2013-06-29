//
//  KATGMainResultsController.m
//  KATG
//
//  Created by Doug Russell on 3/28/13.
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

#import "KATGMainResultsController.h"

#import "KATGDataStore.h"

#import "KATGScheduledEvent.h"
#import "KATGShow.h"

@interface KATGMainResultsController () <NSFetchedResultsControllerDelegate>

@property (nonatomic) NSFetchRequest *eventsFetchRequest;
@property (nonatomic) NSFetchedResultsController *eventsFetchedResultsController;

@property (nonatomic) NSFetchRequest *showsFetchRequest;
@property (nonatomic) NSFetchedResultsController *showsFetchedResultsController;

@property (nonatomic) NSManagedObjectContext *readerContext;
@end

@implementation KATGMainResultsController
@dynamic events;
@dynamic shows;

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		_readerContext = [[KATGDataStore sharedStore] readerContext];
		NSParameterAssert(_readerContext);
	}
	return self;
}

- (void)dealloc
{
	_eventsFetchedResultsController.delegate = nil;
	_showsFetchedResultsController.delegate = nil;
}

#pragma mark - Fetch Requests

- (NSFetchRequest *)eventsFetchRequest
{
	if (_eventsFetchRequest)
	{
		return _eventsFetchRequest;
	}
	_eventsFetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:self.readerContext];
	_eventsFetchRequest.entity = entity;
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:KATGScheduledEventTimestampAttributeName ascending:YES];
	_eventsFetchRequest.sortDescriptors = [NSArray arrayWithObject:sort];
	return _eventsFetchRequest;
}

- (NSFetchedResultsController *)eventsFetchedResultsController
{
	if (_eventsFetchedResultsController)
	{
		return _eventsFetchedResultsController;
	}
	_eventsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.eventsFetchRequest managedObjectContext:self.readerContext sectionNameKeyPath:nil cacheName:@"Events"];
	_eventsFetchedResultsController.delegate = self;
	return _eventsFetchedResultsController;
}

- (NSFetchedResultsController *)showsFetchedResultsController
{
	if (_showsFetchedResultsController)
	{
		return _showsFetchedResultsController;
	}
	_showsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.showsFetchRequest managedObjectContext:self.readerContext sectionNameKeyPath:nil cacheName:@"Shows"];
	_showsFetchedResultsController.delegate = self;
	return _showsFetchedResultsController;
}

- (NSFetchRequest *)showsFetchRequest
{
	if (_showsFetchRequest)
	{
		return _showsFetchRequest;
	}
	_showsFetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGShow katg_entityName] inManagedObjectContext:self.readerContext];
	_showsFetchRequest.entity = entity;
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:KATGShowEpisodeIDAttributeName ascending:NO];
	_showsFetchRequest.sortDescriptors = [NSArray arrayWithObject:sort];
	return _showsFetchRequest;
}

#pragma mark - Public API

- (bool)performFetch:(NSError *__autoreleasing*)error
{
	NSParameterAssert([NSThread isMainThread]);
	[self registerNotifications];
	if (![self.eventsFetchedResultsController performFetch:error])
	{
		[self unregisterNotifications];
		return false;
	}
	if (![self.showsFetchedResultsController performFetch:error])
	{
		[self unregisterNotifications];
		return false;
	}
	return true;
}

- (NSArray *)events
{
	NSParameterAssert([NSThread isMainThread]);
	return [self.eventsFetchedResultsController fetchedObjects];
}

- (NSArray *)shows
{
	NSParameterAssert([NSThread isMainThread]);
	return [self.showsFetchedResultsController fetchedObjects];
}

#pragma mark - Changes

- (void)registerNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsChanged:) name:KATGDataStoreEventsDidChangeNotification object:nil];
	NSParameterAssert(self.readerContext);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.readerContext];
}

- (void)unregisterNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:KATGDataStoreEventsDidChangeNotification object:nil];
	NSParameterAssert(self.readerContext);
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:self.readerContext];
}

- (void)contextDidChange:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	NSParameterAssert([note object] == self.readerContext);
	NSDictionary *userInfo = [note userInfo];
	if (userInfo[NSInvalidatedAllObjectsKey])
	{
		[NSFetchedResultsController deleteCacheWithName:@"Events"];
		[NSFetchedResultsController deleteCacheWithName:@"Shows"];
		[self performFetch:nil];
		[self.delegate reloadAllData];
		return;
	}
}

//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {}
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	id <KATGMainResultsControllerDelegate> delegate = self.delegate;
	if (controller == self.eventsFetchedResultsController)
	{
		[delegate didChangeEvents];
	}
	else if (controller == self.showsFetchedResultsController)
	{
		[delegate didChangeShows];
	}
	else
	{
		NSParameterAssert(NO);
	}
}

- (void)eventsChanged:(NSNotification *)note
{
	id <KATGMainResultsControllerDelegate> delegate = self.delegate;
	[delegate didChangeEvents];
}

@end
