//
//  main.m
//  KATG
//
//  Created by Doug Russell on 8/26/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KATGAppDelegate_iPhone.h"
#import "KATGAppDelegate_iPad.h"

int main(int argc, char *argv[])
{
	@autoreleasepool {
		Class appDelegateClass;
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			appDelegateClass = [KATGAppDelegate_iPad class];
		else
			appDelegateClass = [KATGAppDelegate_iPhone class];
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass(appDelegateClass));
	}
}