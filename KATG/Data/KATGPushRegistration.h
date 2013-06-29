//
//  KATGPushRegistration.h
//  KATG
//
//  Created by Doug Russell on 6/18/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

extern NSString *KATGPushErrorDomain;

typedef enum {
	KATGNoError,
	KATGDeviceTokenReadFailedError,
	KATGApplicationKeyReadFailedError,
	KATGApplicationSecretReadFailedError,
} RegistrationErrorCode;

@protocol KATGPushRegistrationDelegate;

@interface KATGPushRegistration : NSObject 

@property (weak, nonatomic) id<KATGPushRegistrationDelegate> delegate;
@property (nonatomic) NSString *deviceAlias;
@property (nonatomic) NSData *deviceToken;

+ (instancetype)sharedInstance;
- (void)sendToken;
- (void)tag:(NSString *)tag;

@end

@protocol KATGPushRegistrationDelegate <NSObject>
- (void)pushNotificationRegisterSucceeded:(id)registration;
- (void)pushNotificationRegisterFailed:(id)registration error:(NSError *)error;
@optional
- (void)tagRegisterSucceeded:(KATGPushRegistration *)registration;
- (void)tagRegisterFailed:(NSError *)error;
- (void)tagUnregisterSucceeded:(KATGPushRegistration *)registration;
- (void)tagUnregisterFailed:(NSError *)error;
@end
