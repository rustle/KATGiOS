//
//  KATGLiveShowFeedbackViewController.m
//  KATG
//
//  Created by Timothy Donnelly on 5/2/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGLiveShowFeedbackViewController.h"
#import "KATGButton.h"
#import "KATGDataStore.h"
#import "KATGContentContainerView.h"
#import <QuartzCore/QuartzCore.h>

@interface KATGLiveShowFeedbackViewController ()
@property (weak, nonatomic) KATGContentContainerView *containerView;
@property (weak, nonatomic) KATGButton *doneButton;
@property (weak, nonatomic) UITextField *nameTextField;
@property (weak, nonatomic) UITextField *locationTextField;
@property (weak, nonatomic) UITextView *messagesTextView;
@property (weak, nonatomic) KATGButton *sendButton;
@end

@implementation KATGLiveShowFeedbackViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	KATGContentContainerView *container = [[KATGContentContainerView alloc] initWithFrame:CGRectZero];
	[self.view addSubview:container];
	self.containerView = container;
	
	UITextField *nameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
	nameTextField.borderStyle = UITextBorderStyleRoundedRect;
	[self.containerView.contentView addSubview:nameTextField];
	self.nameTextField = nameTextField;
	
	UITextField *locationTextField = [[UITextField alloc] initWithFrame:CGRectZero];
	locationTextField.borderStyle = UITextBorderStyleRoundedRect;
	[self.containerView.contentView addSubview:locationTextField];
	self.locationTextField = locationTextField;
	
	UITextView *messagesTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	messagesTextView.layer.cornerRadius = 8.0f;
	messagesTextView.contentInset = UIEdgeInsetsMake(4.0f, 4.0f, 4.0f, 4.0f);
	[self.containerView.contentView addSubview:messagesTextView];
	self.messagesTextView = messagesTextView;
	
	KATGButton *doneButton = [[KATGButton alloc] initWithFrame:CGRectZero];
	[doneButton setTitle:@"Done" forState:UIControlStateNormal];
	doneButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
	doneButton.accessibilityLabel = NSLocalizedString(@"Double tap to close feedback", nil);
	[doneButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
	[container.headerView addSubview:doneButton];
	self.doneButton = doneButton;
	
	KATGButton *sendButton = [[KATGButton alloc] initWithFrame:CGRectMake(4.0f, 0.0f, 60.0f, 44.0f)];
	[sendButton setTitle:@"Send" forState:UIControlStateNormal];
	sendButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
	[sendButton addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
	[self.containerView.headerView addSubview:sendButton];
	self.sendButton = sendButton;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.messagesTextView becomeFirstResponder];
}

#define kFeedbackMargin 10.0f

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	CGRect bounds = self.view.bounds;
	self.containerView.frame = bounds;
	[self.containerView layoutSubviews];
	bounds = self.containerView.contentView.bounds;
	CGFloat textFieldWidth = (bounds.size.width - kFeedbackMargin * 3.0f) / 2.0f;
	self.nameTextField.frame = CGRectMake(kFeedbackMargin, kFeedbackMargin, textFieldWidth, 30.0f);
	self.locationTextField.frame = CGRectMake(kFeedbackMargin * 2.0f + textFieldWidth, kFeedbackMargin, textFieldWidth, 30.0f);
	CGFloat y = kFeedbackMargin + CGRectGetMaxY(self.locationTextField.frame);
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		self.messagesTextView.frame = CGRectMake(kFeedbackMargin, y, bounds.size.width - kFeedbackMargin * 2.0f, CGRectGetHeight(bounds) - y - kFeedbackMargin);
	}
	else
	{
		self.messagesTextView.frame = CGRectMake(kFeedbackMargin, y, bounds.size.width - kFeedbackMargin * 2.0f, 140.0f);
	}
	CGRect buttonFrame = self.sendButton.frame;
	buttonFrame.origin.x = CGRectGetMaxX(self.containerView.headerView.bounds) - buttonFrame.size.width - 4.0f;
	self.doneButton.frame = buttonFrame;
}

- (void)close:(id)sender
{
	if (self.presentingViewController)
	{
		[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
	}
	else
	{
		[self.delegate closeLiveShowFeedbackViewController:self];
	}
}

- (void)send:(id)sender
{
	NSString *name = self.nameTextField.text;
	NSString *location = self.locationTextField.text;
	NSString *message = self.messagesTextView.text;
	if (![message length])
	{
		return;
	}
	self.nameTextField.enabled = NO;
	self.locationTextField.enabled = NO;
	self.messagesTextView.editable = NO;
	__weak typeof(*self) *weakSelf = self;
	[[KATGDataStore sharedStore] submitFeedback:name location:location comment:message completion:^(NSError *error) {
		__weak typeof(*weakSelf) *strongSelf = weakSelf;
		if (strongSelf)
		{
			if (error)
			{
				// TODO: Inform user
			}
			else
			{
				strongSelf.messagesTextView.text = @"";
			}
			strongSelf.nameTextField.enabled = YES;
			strongSelf.locationTextField.enabled = YES;
			strongSelf.messagesTextView.editable = YES;
		}
	}];
}

@end
