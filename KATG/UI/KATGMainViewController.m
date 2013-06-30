//
//  KATGMainViewController.m
//  KATG
//
//  Created by Timothy Donnelly on 12/8/12.
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

#import "KATGMainViewController.h"

#import <EventKit/EventKit.h>

#import "KATGSettingsViewController.h"
#import "KATGLiveShowFeedbackViewController.h"
#import "KATGShowViewController.h"
#import "KATGShowView.h"

#import "KATGTabBar.h"
#import "KATGTabBarItem.h"
#import "KATGTabBarTabItem.h"
#import "KATGTabBarButtonItem.h"
#import "KATGTabBarBackgroundView.h"
#import "KATGSearchBar.h"

#import "UICollectionView+TDAdditions.h"
#import "TDCollectionView.h"

#import "KATGPlaybackManager.h"

#import "KATGScheduleCell.h"
#import "KATGLiveCell.h"
#import "KATGArchiveCell.h"

#import "KATGDataStore.h"
#import "KATGShow.h"
#import "KATGScheduledEvent.h"

#import "KATGImageCache.h"

#import "UINavigationController+KATGAdditions.h"

#import "KATGMainDataSource.h"

#import "KATGAlertPanel.h"
#import "KATGButton.h"

#if DEBUG && 0
#define RemoteEventsLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define RemoteEventsLog(fmt, ...) 
#endif //DEBUG

@interface KATGMainViewController () <KATGTabBarDelegate, KATGShowViewControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIView *uiContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uiContainerViewBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet KATGTabBar *tabBar;
@property (weak, nonatomic) IBOutlet KATGSearchBar *searchBar;

@property (nonatomic) KATGShowViewController *currentlyPresentedShowViewController;
@property (nonatomic) UIView *modalPresentationDimmerView;

// Layout constraints for modification at runtime
@property (nonatomic) IBOutlet NSLayoutConstraint *collectionViewLeadingSpaceConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *collectionViewTrailingSpaceConstraint;

// Custom collection view class
@property (weak, nonatomic) IBOutlet TDCollectionView *collectionView;

@property (nonatomic) bool receivingRemoteEvents;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic) KATGMainDataSource *mainDataSource;

@property (nonatomic) UIActionSheet *actionSheet;
@property (nonatomic) NSUInteger indexForActionSheet;
@property (nonatomic) KATGAlertPanel *connectivityPanel;

@end

static void * KATGCurrentShowObserverContext = @"CurrentShowObserverContext";
static void * KATGIsLiveObserverContext = @"IsLiveObserverContext";

@implementation KATGMainViewController

#pragma mark - Setup/Cleanup

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		_mainDataSource = [KATGMainDataSource new];
		_backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		[self registerNotifications];
		[self registerObservers];
	}
	return self;
}

- (void)dealloc
{
	[self unregisterNotifications];
	[self unregisterObservers];
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[[KATGDataStore sharedStore] downloadAllEpisodes];
	[[KATGDataStore sharedStore] downloadEvents];
	
	UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	
	[self configureTabBar];
	[self configureNavBar];
	
	self.mainDataSource.mainCollectionView = self.collectionView;
	self.mainDataSource.mainViewController = self;
	NSError *error;
	if (![self.mainDataSource performFetch:&error])
	{
		NSLog(@"%@", error);
	}
}

- (void)configureTabBar
{
	// Setup the tab bar
	NSMutableArray *items = [NSMutableArray new];
	
	KATGTabBarTabItem *archiveItem = [[KATGTabBarTabItem alloc] initWithImage:[UIImage imageNamed:@"schedule-tab-icon.png"] title:@"Schedule"];
	[items addObject:archiveItem];
	
	KATGTabBarTabItem *liveItem = [[KATGTabBarTabItem alloc] initWithImage:[UIImage imageNamed:@"live-tab-icon.png"] title:@"Live"];
	[items addObject:liveItem];
	
	KATGTabBarTabItem *scheduleItem = [[KATGTabBarTabItem alloc] initWithImage:[UIImage imageNamed:@"archive-tab-icon.png"] title:@"Archive"];
	[items addObject:scheduleItem];
	
	self.tabBar.tabItems = items;

#if 0
	KATGTabBarButtonItem *leftButtonItem = [[KATGTabBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] target:self action:@selector(openSettings:)];
	leftButtonItem.accessibilityLabel = @"Settings";
	self.tabBar.leftButtonItem = leftButtonItem;
	
	KATGTabBarButtonItem *rightButtonItem = [[KATGTabBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] target:self action:@selector(foo)];
	rightButtonItem.accessibilityLabel = @"Search";
	rightButtonItem.actsAsDrawer = YES;
	
	KATGTabBarBackgroundView *drawerBackgroundView = [[KATGTabBarBackgroundView alloc] init];
	drawerBackgroundView.topGradientColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
	drawerBackgroundView.bottomGradientColor = [UIColor colorWithWhite:0.4f alpha:1.0f];
	rightButtonItem.drawerBackgroundView = drawerBackgroundView;
	self.searchBar = [[KATGSearchBar alloc] init];
	rightButtonItem.drawerContentView = self.searchBar;
	self.tabBar.rightButtonItem = rightButtonItem;
#endif
}

- (void)configureNavBar
{
	if (![self isViewLoaded])
	{
		return;
	}
	[self.navigationBar setItems:@[self.navigationItem] animated:NO];
	if ([[KATGPlaybackManager sharedManager] currentShow])
	{
		// [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Now Playing" style:UIBarButtonItemStyleBordered target:self action:@selector(nowPlaying:)] animated:YES];
		KATGButton *nowPlayingButton = [[KATGButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
		[nowPlayingButton setTitle:@"Now Playing" forState:UIControlStateNormal];
		nowPlayingButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
		[nowPlayingButton addTarget:self action:@selector(nowPlaying:) forControlEvents:UIControlEventTouchUpInside];
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:nowPlayingButton]];		
	}
	else
	{
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
	}
	
	self.navigationItem.title = @"KATG";
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (![self.presentedViewController isBeingDismissed])
	{
		[self.collectionView setContentOffset:CGPointZero];
	}
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
	NSValue *animationCurve = [[notification userInfo] valueForKey:UIKeyboardAnimationCurveUserInfoKey];
	UIViewAnimationCurve curve;
	[animationCurve getValue:&curve];
	
	NSValue *animationDuration = [[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSTimeInterval duration;
	[animationDuration getValue:&duration];
	
	NSValue *endingFrame = [[notification userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect frame;
	[endingFrame getValue:&frame];
	
	CGRect uiContainerViewRect = self.uiContainerView.frame;
	uiContainerViewRect.size.height = 20.0f;
	
	[self.collectionView.collectionViewLayout invalidateLayout];
	[UIView animateWithDuration:duration
						  delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.uiContainerViewBottomSpaceConstraint.constant = frame.size.height;
						 [self.view layoutIfNeeded];
					 } completion:^(BOOL finished) {
						 
					 }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	NSValue *animationDuration = [[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSTimeInterval duration;
	[animationDuration getValue:&duration];
	
	[self.collectionView.collectionViewLayout invalidateLayout];
		
	[UIView animateWithDuration:duration
						  delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.uiContainerViewBottomSpaceConstraint.constant = 0.0f;
						 [self.view layoutIfNeeded];
					 } completion:^(BOOL finished) {
						 
					 }];
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	if (self.currentlyPresentedShowViewController)
	{
		KATGShow *show = self.currentlyPresentedShowViewController.show;
		NSParameterAssert(show);
		NSIndexPath *showIndexPath = [NSIndexPath indexPathForItem:[self.mainDataSource.shows indexOfObject:show] inSection:KATGSectionArchive];
		[self scrollCollectionViewToIndexPath:showIndexPath animated:NO];
	}
	else
	{
		NSIndexPath *indexPath = [self.collectionView nearestIndexPathForContentOffset:self.collectionView.contentOffset];
		[self scrollCollectionViewToIndexPath:indexPath animated:YES];
	}
}

- (void)scrollCollectionViewToIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
	[self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
}

#pragma mark - KATGShowViewControllerDelegate

- (void)closeShowViewController:(KATGShowViewController *)showViewController
{
	if (!self.currentlyPresentedShowViewController)
	{
		return;
	}
	
	KATGShow *show = self.currentlyPresentedShowViewController.show;
	NSParameterAssert(show);
	NSIndexPath *showIndexPath = [NSIndexPath indexPathForItem:[self.mainDataSource.shows indexOfObject:show] inSection:KATGSectionArchive];
	[self.collectionView scrollToItemAtIndexPath:showIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
	[self closeActiveShowToArchiveCell:(KATGArchiveCell *)[self.collectionView cellForItemAtIndexPath:showIndexPath]];
}

#pragma mark - Show presentation

- (void)addDimmingViewForModalWithDuration:(NSTimeInterval)duration
{	
	if (!self.modalPresentationDimmerView)
	{
		self.modalPresentationDimmerView = [UIView new];
		self.modalPresentationDimmerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		self.modalPresentationDimmerView.backgroundColor = [UIColor blackColor];
	}
	self.modalPresentationDimmerView.frame = self.view.bounds;
	[self.view addSubview:self.modalPresentationDimmerView];
	self.modalPresentationDimmerView.alpha = 0.0f;
	
	[UIView animateWithDuration:duration
					 animations:^{
						 self.modalPresentationDimmerView.alpha = 1.0f;
					 } completion:NULL];
}

- (void)removeDimmingViewForModalWithDuration:(NSTimeInterval)duration
{	
	[UIView animateWithDuration:duration
					 animations:^{
						 self.modalPresentationDimmerView.alpha = 0.0f;
					 } completion:^(BOOL finished) {
						 [self.modalPresentationDimmerView removeFromSuperview];
					 }];
}

- (void)presentShow:(KATGShow *)show fromArchiveCell:(KATGArchiveCell *)cell
{
	if (self.currentlyPresentedShowViewController)
	{
		return;
	}
	
	[self addDimmingViewForModalWithDuration:0.5f];

	KATGShowView *showView = cell.showView;
	
	KATGShowViewController *showViewController = [KATGShowViewController new];
	showViewController.delegate = self;
	showViewController.showObjectID = [show objectID];
	self.currentlyPresentedShowViewController = showViewController;
	
	// Prepare the show view controller for presentation
	showViewController.collapsedFooterHeight = showView.footerHeight;
	
	[showViewController willMoveToParentViewController:self];
	[self addChildViewController:showViewController];
	[self.view addSubview:showViewController.view];
	showViewController.view.frame = self.view.bounds;
	
	// find the starting rect for the show view within the view controller.
	CGRect showViewRect = showView.bounds;
	CGPoint center = [showViewController.view convertPoint:showView.center fromView:showView.superview];
	showViewRect.origin.x = center.x - (showViewRect.size.width/2);
	showViewRect.origin.y = center.y - (showViewRect.size.height/2);
	showViewController.collapsedShowViewRect = showViewRect;
	
	[showViewController setInterfaceState:KATGShowViewControllerInterfaceStateCollapsed];
			
	// Make the tableView large initially - this prevents everything from animating in from CGRectZero
	showViewController.tableView.frame = showViewController.view.bounds;
	
	NSArray *visibleCells = [self.collectionView visibleCells];
	
	// This is dispatched async because there was a nasty animation jump occuring with the meta columns in the footer.
	// I was unable to track it down, but there is probably a cleaner way to solve this.
	dispatch_async(dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:0.5f delay:0.0f options:0 animations:^{
							 for (UICollectionViewCell *cell in visibleCells)
							 {
								 cell.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
							 }
							 [showViewController setInterfaceState:KATGShowViewControllerInterfaceStateExpanded];
						 }
						 completion:^(BOOL finished) {
							 self.collectionView.hidden = YES;
							 [showViewController didMoveToParentViewController:self];
						 }];
	});
}

- (void)closeActiveShowToArchiveCell:(KATGArchiveCell *)cell
{
	if (!self.currentlyPresentedShowViewController)
	{
		return;
	}
	
	KATGShowView *showView = cell.showView;
	
	// find the starting rect for the show view within the view controller. Because a transform is involved, use bounds and calculate the center
	CGRect showViewRect = showView.bounds;
	CGPoint center = [self.currentlyPresentedShowViewController.view convertPoint:showView.center fromView:showView.superview];
	showViewRect.origin.x = center.x - (showViewRect.size.width/2);
	showViewRect.origin.y = center.y - (showViewRect.size.height/2);
	self.currentlyPresentedShowViewController.collapsedShowViewRect = showViewRect;
	
	NSArray *visibleCells = [self.collectionView visibleCells];
	self.collectionView.hidden = NO;
	
	[self.currentlyPresentedShowViewController willMoveToParentViewController:nil];
	[self removeDimmingViewForModalWithDuration:0.5f];
	
	[UIView animateWithDuration:0.5f delay:0.0f options:0
					 animations:^{
						 for (UICollectionViewCell *cell in visibleCells)
						 {
							 cell.transform = CGAffineTransformIdentity;
						 }
						 [self.currentlyPresentedShowViewController setInterfaceState:KATGShowViewControllerInterfaceStateCollapsed];
					 }
					 completion:^(BOOL finished) {
						 self.currentlyPresentedShowViewController.delegate = nil;
						 [self.currentlyPresentedShowViewController.view removeFromSuperview];
						 [self.currentlyPresentedShowViewController didMoveToParentViewController:nil];
						 self.currentlyPresentedShowViewController = nil;
					 }];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
	[self addDimmingViewForModalWithDuration:flag ? 0.3f : 0.0f];
	[super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
	[self removeDimmingViewForModalWithDuration:flag ? 0.3f : 0.0f];
	[super dismissViewControllerAnimated:flag completion:completion];
}

#pragma mark - 

- (void)longPressRecognized:(KATGScheduleItemTableViewCell *)cell
{
	NSParameterAssert(self.actionSheet == nil);
	self.indexForActionSheet = cell.index;
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Add %@ to calendar?", @""), cell.episodeNameLabel.text] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add to calendar", @""), nil];
	[self.actionSheet showInView:cell];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSParameterAssert(actionSheet == self.actionSheet);
	self.actionSheet = nil;
	if (actionSheet.cancelButtonIndex == buttonIndex)
	{
		return;
	}
	
	EKEventStore *store = [[EKEventStore alloc] init];
	[store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
		if (granted)
		{
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				//TODO: See if event is already in store (maybe store the identifier in the event object?)
				KATGScheduledEvent *event = self.mainDataSource.events[self.indexForActionSheet];
				EKEvent *ekEvent = [EKEvent eventWithEventStore:store];
				if (ekEvent)
				{
					ekEvent.title = [NSString stringWithFormat:@"KATG: %@", event.title];
					ekEvent.allDay = NO;
					ekEvent.startDate = event.timestamp;
					//TODO: use real end date from feed
					ekEvent.endDate = [NSDate dateWithTimeInterval:3600.0 sinceDate:event.timestamp];
					ekEvent.calendar = store.defaultCalendarForNewEvents;
					NSError *error;
					if (![store saveEvent:ekEvent span:EKSpanThisEvent error:&error])
					{
						// TODO: Tell user
						NSLog(@"Event error %@", error);
					}
				}
			});
		}
		else
		{
			// TODO: tell user that they can't save events unless they grant access which they can now do in settings
			NSLog(@"Event error %@", error);
		}
	}];
}

#pragma mark - Actions

- (void)openSettings:(id)sender
{
    KATGSettingsViewController *settingsVC = [[KATGSettingsViewController alloc] initWithTableViewStyle:UITableViewStyleGrouped];
	[self presentViewController:[UINavigationController katg_navigationControllerWithRootViewController:settingsVC] animated:YES completion:NULL];
}

- (IBAction)nowPlaying:(id)sender
{
	KATGShow *show = [[KATGPlaybackManager sharedManager] currentShow];
	if (!show)
	{
		return;
	}
	KATGShowViewController *showViewController = [KATGShowViewController new];
	showViewController.showObjectID = [show objectID];
	[showViewController setInterfaceState:KATGShowViewControllerInterfaceStateExpanded];
	[self presentViewController:showViewController animated:YES completion:NULL];
}

#pragma mark - KATGTabBarDelegate

- (BOOL)tabBar:(KATGTabBar *)tabBar shouldSelectItemAtIndex:(NSInteger)index wasTapped:(BOOL)wasTapped
{
	switch ((KATGSection)index)
	{
		case KATGSectionArchive:
			if (![self.mainDataSource.shows count])
			{
				return NO;
			}
		default:
			return YES;
	}
}

- (void)tabBar:(KATGTabBar *)tabBar didSelectItemAtIndex:(NSInteger)index wasTapped:(BOOL)wasTapped
{
	if (!wasTapped)
	{
		return;
	}
	
	NSIndexPath *indexPath = nil;
	
	switch ((KATGSection)index)
	{
		case KATGSectionSchedule:
			// Schedule
			indexPath = [NSIndexPath indexPathForItem:0 inSection:KATGSectionSchedule];
			break;
		case KATGSectionLive:
			// Live
			indexPath = [NSIndexPath indexPathForItem:0 inSection:KATGSectionLive];
			break;
		case KATGSectionArchive:
			// Archive
			indexPath = [NSIndexPath indexPathForItem:0 inSection:KATGSectionArchive];
			break;
	}
	
	[self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
	self.mainDataSource.collectionViewScrollingAnimationInProgress = true;
}

- (void)tabBarDidOpenDrawer:(KATGTabBar *)tabBar
{
	[self.searchBar.textField becomeFirstResponder];
}

#pragma mark - KVO

- (void)registerObservers
{
	[[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	[[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"currentShow" options:0 context:KATGCurrentShowObserverContext];
	[[KATGDataStore sharedStore] addObserver:self forKeyPath:kKATGDataStoreIsShowLiveKey options:0 context:KATGIsLiveObserverContext];
}

- (void)unregisterObservers
{
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:@"state"];
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:@"currentShow" context:KATGCurrentShowObserverContext];
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:kKATGDataStoreIsShowLiveKey context:KATGIsLiveObserverContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == KATGCurrentShowObserverContext)
	{
		[self configureNavBar];
	}
	else if (context == KATGIsLiveObserverContext)
	{
		[self configureLiveCell];
	}
	else if ([keyPath isEqualToString:@"state"])
	{
		switch ([KATGPlaybackManager sharedManager].state) {
			case KATGAudioPlayerStatePlaying:
				[self startReceivingRemoteEvents];
				break;
			case KATGAudioPlayerStateUnknown:
			case KATGAudioPlayerStateDone:
				[self endReceivingRemoteEvents];
				break;
			default:
				break;
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Notifications

- (void)registerNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectivityFailed) name:KATGDataStoreConnectivityFailureNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectivityRestored) name:KATGDataStoreConnectivityRestoredNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverIsOffline:) name:KATGLiveShowStreamingServerOfflineNotification object:nil];
}

- (void)unregisterNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:KATGDataStoreConnectivityFailureNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:KATGDataStoreConnectivityRestoredNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:KATGLiveShowStreamingServerOfflineNotification object:nil];
}

- (void)serverIsOffline:(NSNotification *)note
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Streaming Server Offline" message:@"The live show stream appears to be offline" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

#pragma mark - Remote

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)startBackgroundTaskForAudio
{
	if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid)
	{
		RemoteEventsLog(@"startBackgroundTaskForAudio");
		self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			RemoteEventsLog(@"expire");
			[self cleanupBackgroundTask];
		}];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cleanupBackgroundTask) object:nil];
		[self performSelector:@selector(cleanupBackgroundTask) withObject:nil afterDelay:30.0f];
	}
}

- (void)endBackgroundTaskForAudio
{
	if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid)
	{
		RemoteEventsLog(@"endBackgroundTaskForAudio");
		[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
		self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cleanupBackgroundTask) object:nil];
	}
}

- (void)cleanupBackgroundTask
{
	if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid)
	{
		RemoteEventsLog(@"cleanup");
		[self endReceivingRemoteEvents];
		[[KATGPlaybackManager sharedManager] stop];
		[self endBackgroundTaskForAudio];
	}
}

- (void)startReceivingRemoteEvents
{
	RemoteEventsLog(@"becomeFirstResponder");
	[self becomeFirstResponder];
	if (!self.receivingRemoteEvents)
	{
		RemoteEventsLog(@"beginReceivingRemoteControlEvents");
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		self.receivingRemoteEvents = true;
	}
}

- (void)endReceivingRemoteEvents
{
	if (self.receivingRemoteEvents)
	{
		RemoteEventsLog(@"endReceivingRemoteControlEvents");
		[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
		self.receivingRemoteEvents = false;
	}
	RemoteEventsLog(@"resignFirstResponder");
	[self resignFirstResponder];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
	if (receivedEvent.type == UIEventTypeRemoteControl)
	{
		switch (receivedEvent.subtype) {
			case UIEventSubtypeRemoteControlTogglePlayPause:
				if ([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
				{
					if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
					{
						[self startBackgroundTaskForAudio];
					}
					[[KATGPlaybackManager sharedManager] pause];
				}
				else
				{
					[[KATGPlaybackManager sharedManager] play];
					[self endBackgroundTaskForAudio];
				}
				break;
			case UIEventSubtypeRemoteControlPreviousTrack:
				[[KATGPlaybackManager sharedManager] jumpBackward];
				break;
			case UIEventSubtypeRemoteControlNextTrack:
				[[KATGPlaybackManager sharedManager] jumpForward];
				break;
			default:
				break;
		}
	}
}

- (void)willResignActive:(NSNotification *)notification
{
	switch ([KATGPlaybackManager sharedManager].state) {
		case KATGAudioPlayerStatePaused:
		case KATGAudioPlayerStateLoading:
			[self startBackgroundTaskForAudio];
			break;
		case KATGAudioPlayerStateUnknown:
		case KATGAudioPlayerStateDone:
			[self endReceivingRemoteEvents];
			break;
		default:
			break;
	}
}

- (void)didBecomeActive:(NSNotification *)notification
{
	[self endBackgroundTaskForAudio];
}

#pragma mark - Connectivity

- (void)connectivityFailed
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		if (self.connectivityPanel)
		{
			return;
		}
		KATGAlertPanel *panel = [KATGAlertPanel panelWithText:NSLocalizedString(@"Check your internet connection", nil)];
		self.connectivityPanel = panel;
		[panel showFromView:self.navigationBar completionBlock:^{
			self.connectivityPanel = nil;
		}];
	});
}

- (void)connectivityRestored
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self.connectivityPanel hideWithCompletionBlock:^{
			self.connectivityPanel = nil;
		}];
	});
}

#pragma mark - Live Show

- (void)liveShowFeedbackButtonPressed:(KATGLiveCell *)cell
{
	UIViewController *controller = [KATGLiveShowFeedbackViewController new];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentViewController:controller animated:YES completion:NULL];
}

- (void)configureLiveCell
{
	NSParameterAssert([NSThread isMainThread]);
	KATGLiveCell *cell = (KATGLiveCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:KATGSectionLive]];
	[cell setLiveMode:[[KATGDataStore sharedStore] isShowLive] animated:YES];
}

@end
