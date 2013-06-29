//
//  KATGPushRegistration.m
//  KATG
//
//  Created by Doug Russell on 6/18/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGPushRegistration.h"
#import "KATGPushRegistrationKeys.h"

NSString *KATGPushErrorDomain = @"KATGPushErrorDomain";

// From: http://www.cocoadev.com/index.pl?BaseSixtyFour
static NSString *KATGCreateBase64StringFromData(NSData *inData)
{
    const uint8_t* input = (const uint8_t*)[inData bytes];
    NSInteger length = [inData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) 
	{
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) 
		{
            value <<= 8;
            
            if (j < length) 
			{
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@interface KATGPushRegistration ()
@property (nonatomic) NSString *applicationKey;
@property (nonatomic) NSString *applicationSecret;
@property (nonatomic) NSURLConnection *tokenConnection;
@property (nonatomic) NSURLConnection *tagConnection;
@property (nonatomic) NSURLConnection *untagConnection;
@property (nonatomic) NSString *formattedToken;
- (void)setBasicAuthHeader:(NSMutableURLRequest *)request;
- (NSURLRequest *)sendRequest;
- (NSURLRequest *)tagRequest:(NSString *)tag;
- (NSURLRequest *)untagRequest:(NSString *)tag;
- (NSString *)deviceUUID;
- (NSString *)bundleIdentifier;
- (NSString *)bundleVersion;
@end

@implementation KATGPushRegistration

+ (KATGPushRegistration *)sharedInstance
{
	static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self class] new];
    });
	return sharedInstance;
}

#pragma mark - Send Registration
- (void)sendToken
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSURLRequest *request = [self sendRequest];
	
	if ([NSURLConnection canHandleRequest:request])
	{
		NSURLConnection *connection = nil;
		connection = [NSURLConnection connectionWithRequest:request delegate:self];
		if (connection != nil)
		{
			self.tokenConnection = connection;
			[self.tokenConnection start];
		}
		else
		{ // Unable to make connection
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
			if (self.delegate && [self.delegate respondsToSelector:@selector(pushNotificationRegisterFailed:)])
			{
				[self.delegate pushNotificationRegisterFailed:self error:error];
			}
		}
	}
}

#pragma mark - Tagging
- (void)tag:(NSString *)tag
{
	NSURLRequest *request = [self tagRequest:tag];
	if ([NSURLConnection canHandleRequest:request])
	{
		NSURLConnection *connection	= nil;
		connection = [NSURLConnection connectionWithRequest:request delegate:self];
		if (connection != nil)
		{
			self.tagConnection = connection;
			[self.tagConnection start];
		}
		else
		{ // Unable to make connection
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
			if (self.delegate && [self.delegate respondsToSelector:@selector(tagRegisterFailed:)])
			{
				[self.delegate tagRegisterFailed:error];
			}
		}
	}
}

- (void)untag:(NSString *)tag
{
	NSURLRequest *request = [self untagRequest:tag];
	if ([NSURLConnection canHandleRequest:request])
	{
		NSURLConnection *connection = nil;
		connection = [NSURLConnection connectionWithRequest:request delegate:self];
		if (connection != nil)
		{
			self.untagConnection = connection;
			[self.untagConnection start];
		}
		else
		{ // Unable to make connection
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
			if (self.delegate && [self.delegate respondsToSelector:@selector(tagUnregisterFailed:)])
			{
				[self.delegate tagUnregisterFailed:error];
			}
		}
	}
}

- (void)setDeviceToken:(NSData *)deviceToken
{
	if (_deviceToken != deviceToken)
	{
		_deviceToken = deviceToken;
		//
		//c/o stephen joseph butler
		//http://www.cocoabuilder.com/archive/cocoa/194181-convert-hex-values-in-an-nsdata-object-to-nsstring.html#194188
		//
		NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([self.deviceToken length] * 2)];
		const unsigned char *dataBuffer = [self.deviceToken bytes];
		int i;
		for (i = 0; i < [self.deviceToken length]; ++i) 
		{
			[stringBuffer appendFormat:@"%02X", (unsigned int)dataBuffer[i]];
		}
		NSString *stringCopy = [stringBuffer copy];
		self.formattedToken = stringCopy;
	}
}

#pragma mark - Init/Dealloc

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self.applicationKey = kApplicationKey;
		self.applicationSecret = kApplicationSecret;
	}
	return self;
}

#pragma mark - Send Request
- (NSURLRequest *)sendRequest
{
	if (self.formattedToken == nil || self.formattedToken.length != 64)
	{
		NSError *error = [NSError errorWithDomain:KATGPushErrorDomain code:KATGDeviceTokenReadFailedError userInfo:nil];
		[self.delegate pushNotificationRegisterFailed:self error:error];
		return nil;
	}
	
	NSString *server = @"https://go.urbanairship.com";
	NSString *urlString = [NSString stringWithFormat:@"%@%@%@/", server, @"/api/device_tokens/", self.formattedToken];
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"PUT"];
	
	if (self.deviceAlias == nil && self.deviceAlias.length == 0)
	{
		self.deviceAlias = [NSString stringWithFormat:@"%@-%@-%@", [self bundleIdentifier], [self bundleVersion], [self deviceUUID]];
	}
	[request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[[NSString stringWithFormat: @"{\"alias\": \"%@\"}", self.deviceAlias] dataUsingEncoding:NSUTF8StringEncoding]];
	
	if (self.applicationKey == nil || self.applicationKey.length == 0)
	{
		NSError *error = [NSError errorWithDomain:KATGPushErrorDomain code:KATGApplicationKeyReadFailedError userInfo:nil];
		[self.delegate pushNotificationRegisterFailed:self error:error];
		return nil;
	}
	
	if (self.applicationSecret == nil || self.applicationSecret.length == 0)
	{
		NSError *error = [NSError errorWithDomain:KATGPushErrorDomain code:KATGApplicationSecretReadFailedError userInfo:nil];
		[self.delegate pushNotificationRegisterFailed:self error:error];
		return nil;
	}
	[self setBasicAuthHeader:request];
	
	return (NSURLRequest *)request;
}

- (NSURLRequest *)tagRequest:(NSString *)tag
{
	if (self.formattedToken == nil || self.formattedToken.length != 64)
	{
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagRegisterFailed:)])
		{
			[self.delegate tagRegisterFailed:[NSError errorWithDomain:KATGPushErrorDomain code:KATGDeviceTokenReadFailedError userInfo:nil]];
		}
		return nil;
	}
	
	NSString *server = @"https://go.urbanairship.com";
	NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@%@", server, @"/api/device_tokens/", self.formattedToken, @"/tags/", tag];
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"PUT"];
	
	if (self.applicationKey == nil || self.applicationKey.length == 0)
	{
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagRegisterFailed:)])
		{
			[self.delegate tagRegisterFailed:[NSError errorWithDomain:KATGPushErrorDomain code:KATGApplicationKeyReadFailedError userInfo:nil]];
		}
		return nil;
	}
	
	if (self.applicationSecret == nil || self.applicationSecret.length == 0)
	{
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagRegisterFailed:)])
		{
			[self.delegate tagRegisterFailed:[NSError errorWithDomain:KATGPushErrorDomain code:KATGApplicationSecretReadFailedError userInfo:nil]];
		}
		return nil;
	}
	[self setBasicAuthHeader:request];
	
	return (NSURLRequest *)request;
}

- (NSURLRequest *)untagRequest:(NSString *)tag
{
	if (self.formattedToken == nil || self.formattedToken.length != 64)
	{
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagUnregisterFailed:)])
		{
			[self.delegate tagUnregisterFailed:[NSError errorWithDomain:KATGPushErrorDomain code:KATGDeviceTokenReadFailedError userInfo:nil]];
		}
		return nil;
	}
	
	NSString *server = @"https://go.urbanairship.com";
	NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@%@", server, @"/api/device_tokens/", self.formattedToken, @"/tags/", tag];
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"DELETE"];
	
	if (self.applicationKey == nil || self.applicationKey.length == 0)
	{
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagUnregisterFailed:)])
		{
			[self.delegate tagUnregisterFailed:[NSError errorWithDomain:KATGPushErrorDomain code:KATGApplicationKeyReadFailedError userInfo:nil]];
		}
		return nil;
	}
	
	if (self.applicationSecret == nil || self.applicationSecret.length == 0)
	{
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagUnregisterFailed:)])
		{
			[self.delegate tagUnregisterFailed:[NSError errorWithDomain:KATGPushErrorDomain code:KATGApplicationSecretReadFailedError userInfo:nil]];
		}
		return nil;
	}
	[self setBasicAuthHeader:request];
	
	return (NSURLRequest *)request;
}

- (NSString *)deviceUUID
{
	return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (NSString *)bundleIdentifier
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *)bundleVersion
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

#pragma mark - NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if ([connection isEqual:self.tokenConnection])
	{
		self.tokenConnection = nil;
		[self.delegate pushNotificationRegisterFailed:self error:error];
	}
	else if ([connection isEqual:self.tagConnection])
	{
		self.tagConnection = nil;
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagRegisterFailed:)])
		{
			[self.delegate tagRegisterFailed:error];
		}
	}
	else if ([connection isEqual:self.untagConnection])
	{
		self.untagConnection = nil;
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagUnregisterFailed:)])
		{
			[self.delegate tagUnregisterFailed:error];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
	if ([connection isEqual:self.tokenConnection])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		if (statusCode != 200 && statusCode != 201)
		{// 201 token registered, 200 token already registered
			if (self.delegate && [self.delegate respondsToSelector:@selector(pushNotificationRegisterFailed:)])
			{
				[self.delegate pushNotificationRegisterFailed:self error:nil];
			}
			return;
		}
		if (self.delegate && [self.delegate respondsToSelector:@selector(pushNotificationRegisterSucceeded:)])
		{
			[self.delegate pushNotificationRegisterSucceeded:self];
		}
#ifdef DEVELOPMENTBUILD
		[self tag:@"DevelopmentDevice"];
#endif
	}
	else if ([connection isEqual:self.tagConnection])
	{// 201 tag added, 200 tag already associated with token
		if (statusCode != 200 && statusCode != 201)
		{
			if (self.delegate && [self.delegate respondsToSelector:@selector(tagRegisterFailed:)])
			{
				[self.delegate tagRegisterFailed:nil];
			}
			return;
		}
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagRegisterSucceeded:)])
		{
			[self.delegate tagRegisterSucceeded:self];
		}
	}
	else if ([connection isEqual:self.untagConnection])
	{// 204 = tag removed, 404 = tag already not associated with token
		if (statusCode != 204 && statusCode != 404)
		{
			if (self.delegate && [self.delegate respondsToSelector:@selector(tagUnregisterFailed:)])
			{
				[self.delegate tagUnregisterFailed:nil];
			}
			return;
		}
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagUnregisterSucceeded:)])
		{
			[self.delegate tagUnregisterSucceeded:self];
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if ([connection isEqual:self.tokenConnection])
	{
		self.tokenConnection = nil;
	}
	else if ([connection isEqual:self.tagConnection])
	{
		self.tagConnection = nil;
	}
	else if ([connection isEqual:self.untagConnection])
	{
		self.untagConnection = nil;
	}
}

- (void)setBasicAuthHeader:(NSMutableURLRequest *)request
{
    NSString *authString = KATGCreateBase64StringFromData([[NSString stringWithFormat:@"%@:%@", self.applicationKey, self.applicationSecret] dataUsingEncoding: NSUTF8StringEncoding]);
	[request addValue:[NSString stringWithFormat:@"Basic %@", authString] forHTTPHeaderField:@"Authorization"];
}

@end
