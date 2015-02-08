//
//  UserModel.m
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserModel.h"
#import "SBJson.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "AppDelegate.h"
#import "KeepAlive.h"
#import "Keychain.h"
#import "HttpRequestDefine.h"

#import <Parse/Parse.h>

BOOL IsError(ASIHTTPRequest* request, NSDictionary* response, ReturnParam* param)
{
	if( !response || (request.responseStatusCode > 400) )
	{
		param.success = NO;
		param.failedReason = @"Unable to connect. Please try again.";
		if( request.responseStatusCode == 500 )
		{
			[[KeepAlive getInstance] fire];
		}
		return YES;
	}
    
    if( ![response isKindOfClass:[NSDictionary class]] ) return NO;
	
	NSDictionary* errorInfo;
	errorInfo = [response objectForKey:@"error"];
	if( errorInfo != nil )
	{
		param.success = NO;
		param.failedReason = [NSString stringWithFormat:@"%@", [response objectForKey:@"error_description"]];
        
        if ([param.failedReason isEqualToString:@"Access Denied"])
        {
            [[KeepAlive getInstance] fire];
        }
		return YES;
	}
    
	errorInfo = [response objectForKey:@"errors"];
	if( errorInfo != nil )
	{
		param.success = NO;
		param.failedReason = [NSString stringWithFormat:@"%@", errorInfo];
		return YES;
	}

	return NO;
}

//static float AccessTokenExpiredTime = 5 * 60;
//static float RefreshTokenExpiredTime = 60 * 60 * 24 * 30;

static float AccessTokenExpiredTime =  60;
static float RefreshTokenExpiredTime = 60 * 5;

@interface NSString (NSStringAdditions)

+ (NSString *) base64StringFromData:(NSData *)data length:(int)length;

@end

static char base64EncodingTable[64] = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

@implementation NSString (NSStringAdditions)

+ (NSString *) base64StringFromData: (NSData *)data length: (int)length {
	unsigned long ixtext, lentext;
	long ctremaining;
	unsigned char input[3], output[4];
	short i, charsonline = 0, ctcopy;
	const unsigned char *raw;
	NSMutableString *result;
	
	lentext = [data length]; 
	if (lentext < 1)
		return @"";
	result = [NSMutableString stringWithCapacity: lentext];
	raw = [data bytes];
	ixtext = 0; 
	
	while (true) {
		ctremaining = lentext - ixtext;
		if (ctremaining <= 0) 
			break;        
		for (i = 0; i < 3; i++) { 
			unsigned long ix = ixtext + i;
			if (ix < lentext)
				input[i] = raw[ix];
			else
				input[i] = 0;
		}
		output[0] = (input[0] & 0xFC) >> 2;
		output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
		output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
		output[3] = input[2] & 0x3F;
		ctcopy = 4;
		switch (ctremaining) {
			case 1: 
				ctcopy = 2; 
				break;
			case 2: 
				ctcopy = 3; 
				break;
		}
		
		for (i = 0; i < ctcopy; i++)
			[result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
		
		for (i = ctcopy; i < 4; i++)
			[result appendString: @"="];
		
		ixtext += 3;
		charsonline += 4;
		
		if ((length > 0) && (charsonline >= length))
			charsonline = 0;
	}     
	return result;
}

@end


@implementation UserModel

@synthesize userID;
@synthesize accessToken;
@synthesize refreshToken;
@synthesize user;

- (BOOL)checkAccessToken {
    BOOL isExpired;
    
    NSDate *previousDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"AccessTokenUpdateDate"];
    NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:previousDate];
    
    NSLog(@"%f", timeDifference);
    
    if (timeDifference > AccessTokenExpiredTime) {
        isExpired = YES;
    } else {
        isExpired = NO;
    }
    
    return isExpired;
}

- (BOOL)checkRefreshToken {
    BOOL isExpired;
    
    NSDate *previousDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"RefreshTokenUpdateDate"];
    NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:previousDate];
    
    NSLog(@"%f", timeDifference);
    
    if (timeDifference > RefreshTokenExpiredTime) {
        isExpired = YES;
    } else {
        isExpired = NO;
    }
    
    return isExpired;
}

- (void)updateAccessToken {

    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth2/token", KServeiceDomain]]];
    
    [request setPostValue:CLIENT_FB_ID forKey:@"client_id"];
    [request setPostValue:CLIENT_FB_SECRET forKey:@"client_secret"];
    [request setPostValue:@"refresh_token" forKey:@"grant_type"];
    [request setPostValue:self.refreshToken forKey:@"refresh_token"];
    
	[request setRequestCookies:nil];
    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(successUpdateAccessToken:)];
    [request setDidFailSelector:@selector(failedUpdateAccessToken:)];
    
    [request startAsynchronous];
}

-(void) successUpdateAccessToken:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed sign in:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
    
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
		param.success = YES;
		self.userID = SafeCopy([results objectForKey:@"user_id"]);
		self.accessToken = SafeCopy([results objectForKey:@"access_token"]);
        
        [Keychain saveString:self.accessToken forKey:@"AccessToken"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AccessToken"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"AccessTokenUpdateDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[self callObserver:@selector(userModel:updateAccessToken:) withObject:self withObject:param];
	[param release];
}

-(void) failedUpdateAccessToken:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed sign in: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
    
    if ([error code] == 1 || [error code] == 2)
    {
        param.failedReason = @"Unable to connect. Please try again.";
    }
    else
    {
        param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
    }
	
	[self callObserver:@selector(userModel:updateAccessToken:) withObject:self withObject:param];
	
	[param release];
}


#pragma mark
#pragma mark signin

-(void) signIn:(NSString*)email password:(NSString*)password
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth2/token", KServeiceDomain]]];
  
    [request setPostValue:CLIENT_FB_ID forKey:@"client_id"];
    [request setPostValue:CLIENT_FB_SECRET forKey:@"client_secret"];
    [request setPostValue:@"password" forKey:@"grant_type"];
    [request setPostValue:email forKey:@"username"];
    [request setPostValue:password forKey:@"password"];
  
	[request setRequestCookies:nil];
    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successSignIn:)];
	[request setDidFailSelector:@selector(failedSignIn:)];
	
    [request startAsynchronous];
}

-(void) successSignIn:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed sign in:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
  
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
		param.success = YES;
		self.userID = SafeCopy([results objectForKey:@"user_id"]);
		self.accessToken = SafeCopy([results objectForKey:@"access_token"]);
		self.refreshToken = SafeCopy([results objectForKey:@"refresh_token"]);
    
        [Keychain saveString:self.userID forKey:@"UserID"];
        [Keychain saveString:self.accessToken forKey:@"AccessToken"];
        [Keychain saveString:self.refreshToken forKey:@"RefreshToken"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"AccessTokenUpdateDate"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"RefreshTokenUpdateDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
	}
	
    [PFPush storeDeviceToken:[AppDelegate getAppDelegate].token];
    [PFPush subscribeToChannelInBackground:[NSString stringWithFormat:@"user_%@", self.userID] target:self selector:@selector(subscribeFinished:error:)];
  
	[self callObserver:@selector(userModel:signIn:) withObject:self withObject:param];
	[param release];
}

-(void) failedSignIn:(ASIHTTPRequest*)request
{
  NSError *error = [request error];
	NSLog(@"failed sign in: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
  
  if ([error code] == 1 || [error code] == 2)
  {
    param.failedReason = @"Unable to connect. Please try again.";
  }
  else
  {
    param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
  }
	
	[self callObserver:@selector(userModel:signIn:) withObject:self withObject:param];
	
	[param release];
}


#pragma mark
#pragma mark regist

- (void)regist:(NSString*)email password:(NSString*)password passwordConfirmation:(NSString*)passwordConfirmation
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users.json", KServeiceDomain]]];
    
    [request setPostValue:email forKey:@"user[email]"];
    [request setPostValue:password forKey:@"user[password]"];
    [request setPostValue:passwordConfirmation forKey:@"user[password_confirmation]"];
    
    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successRegist:)];
	[request setDidFailSelector:@selector(failedRegist:)];
	
    [request startAsynchronous];
}

- (void)successRegist:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed regist:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
    
	ReturnParam* param = [[ReturnParam alloc] init];
	
    
    NSDictionary* errorInfo = [results objectForKey:@"errors"];
	if( errorInfo != nil )
	{
		param.success = NO;
		param.failedReason =  [[errorInfo objectForKey:@"email"] objectAtIndex:0];
	}
	else
	{
		param.success = YES;
		NSDictionary* dicUser = [results objectForKey:@"user"];
		if( dicUser != nil )
		{
			self.userID = SafeCopy([dicUser objectForKey:@"id"]);
		}
	}
	
    [PFPush storeDeviceToken:[AppDelegate getAppDelegate].token];
    [PFPush subscribeToChannelInBackground:[NSString stringWithFormat:@"user_%@", self.userID] target:self selector:@selector(subscribeFinished:error:)];

	[self callObserver:@selector(userModel:registed:) withObject:self withObject:param];
	[param release];
}

-(void) failedRegist:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed regist: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
    
    if ([error code] == 1 || [error code] == 2)
    {
        param.failedReason = @"Unable to connect. Please try again.";
    }
    else
    {
        param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
    }
	
	[self callObserver:@selector(userModel:registed:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark signin

-(void) signInWithFacebookLogin:(NSString*)fbID accessToken:(NSString*)fbAccessToken
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth2/token", KServeiceDomain]]];
    
    [request setPostValue:CLIENT_FB_ID forKey:@"client_id"];
    [request setPostValue:CLIENT_FB_SECRET forKey:@"client_secret"];
    [request setPostValue:fbID forKey:@"facebook_identifier"];
    [request setPostValue:fbAccessToken forKey:@"facebook_access_token"];
    [request setPostValue:@"facebook" forKey:@"grant_type"];

    
	[request setRequestCookies:nil];
    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successSignInWithFacebookLogin:)];
	[request setDidFailSelector:@selector(failedSignInWithFacebookLogin:)];
	
    [request startAsynchronous];
}

-(void) successSignInWithFacebookLogin:(ASIHTTPRequest*)request
{
  NSString *responseString = [request responseString];
  NSLog(@"successed sign in:%@",responseString);
  
  NSDictionary *results = [responseString JSONValue];
    
  ReturnParam* param = [[ReturnParam alloc] init];
  
  if( !IsError(request, results, param) ) {
    param.success = YES;
    self.userID = SafeCopy([results objectForKey:@"user_id"]);
    self.accessToken = SafeCopy([results objectForKey:@"access_token"]);
    self.refreshToken = SafeCopy([results objectForKey:@"refresh_token"]);
        
    [Keychain saveString:self.userID forKey:@"UserID"];
    [Keychain saveString:self.accessToken forKey:@"AccessToken"];
    [Keychain saveString:self.refreshToken forKey:@"RefreshToken"];
    [Keychain saveString:@"YES" forKey:@"FacebookLogin"];
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"AccessTokenUpdateDate"];
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"RefreshTokenUpdateDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  [PFPush storeDeviceToken:[AppDelegate getAppDelegate].token];
  [PFPush subscribeToChannelInBackground:[NSString stringWithFormat:@"user_%@", self.userID] target:self selector:@selector(subscribeFinished:error:)];
    
  [self callObserver:@selector(userModel:signInWithFacebookLogin:) withObject:self withObject:param];
  [param release];
}

-(void) failedSignInWithFacebookLogin:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed sign in: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
    
    if ([error code] == 1 || [error code] == 2)
    {
        param.failedReason = @"Unable to connect. Please try again.";
    }
    else
    {
        param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
    }
	
	[self callObserver:@selector(userModel:signInWithFacebookLogin:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark download crumbs & contacts

-(void) downloadCrumbsAndContacts
{
    NSLog(@"%@",[NSString stringWithFormat:@"%@/users/%@.json?%@&%@", KServeiceDomain, self.userID, self.accessToken, CLIENT_ID]);
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@.json?access_token=%@", KServeiceDomain, self.userID, self.accessToken]]];
    
    [request setRequestMethod:@"GET"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(successDownloadCrumbsAndContacts:)];
    [request setDidFailSelector:@selector(failedDownloadCrumbsAndContacts:)];
    
    [request startAsynchronous];

}

-(void) successDownloadCrumbsAndContacts:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed download crumbs & contacts:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
    
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
		param.success = YES;
        
        NSDictionary* userDic = [results objectForKey:@"user"];

        user = [[User alloc] init];
        
        user.userID = SafeCopy([userDic objectForKey:@"id"]);
        user.firstname = SafeCopy([userDic objectForKey:@"firstname"]);
        user.lastname = SafeCopy([userDic objectForKey:@"lastname"]);
        user.email = SafeCopy([userDic objectForKey:@"email"]);
        user.phone = SafeCopy([userDic objectForKey:@"phone_number"]);
        user.birthYear = SafeCopy([userDic objectForKey:@"birth_year"]);
        user.homeStreet =  SafeCopy([userDic objectForKey:@"home_street"]);
        user.homeCity =  SafeCopy([userDic objectForKey:@"home_city"]);
        user.homeState =  SafeCopy([userDic objectForKey:@"home_state"]);
        user.homeZip =  SafeCopy([userDic objectForKey:@"home_zip"]);
        user.homeCountry =  SafeCopy([userDic objectForKey:@"country"]);
        user.height = SafeCopy([userDic objectForKey:@"height"]);
        user.weight = SafeCopy([userDic objectForKey:@"weight"]);
        user.eyes = SafeCopy([userDic objectForKey:@"eyes"]);
        user.hair = SafeCopy([userDic objectForKey:@"hair"]);
        user.gender = SafeCopy([userDic objectForKey:@"gender"]);
		user.ethnicity = SafeCopy([userDic objectForKey:@"ethnicity"]);
        user.notes = SafeCopy([userDic objectForKey:@"notes"]);
        user.vehicleYear = SafeCopy([userDic objectForKey:@"vehicle_year"]);
        user.vehicleMake = SafeCopy([userDic objectForKey:@"vehicle_make"]);
        user.vehicleModel = SafeCopy([userDic objectForKey:@"vehicle_model"]);
        user.vehicleColor = SafeCopy([userDic objectForKey:@"vehicle_color"]);
        user.vehicleLP = SafeCopy([userDic objectForKey:@"license_plate"]);
        user.vehicleLS = SafeCopy([userDic objectForKey:@"license_state"]);
		user.medicalAllergies = SafeCopy([userDic objectForKey:@"medical_allergies"]);
		user.medicalMedications = SafeCopy([userDic objectForKey:@"medical_medications"]);
		user.medicalConditions = SafeCopy([userDic objectForKey:@"medical_other_conditions"]);
		user.sendItinerary = [[userDic objectForKey:@"send_itinerary"] boolValue];
		user.sendOverview = [[userDic objectForKey:@"send_to_new_contacts"] boolValue];
        user.photoURL = SafeCopy([userDic objectForKey:@"avatar"]);

        if (user.firstname.length > 0)
        {
            [Keychain saveString:user.firstname forKey:@"UserFirstName"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserFirstName"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if (user.lastname.length > 0)
        {
            [Keychain saveString:user.lastname forKey:@"UserLastName"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserLastName"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    
        if (user.photoURL.length > 0)
        {
            [Keychain saveString:user.photoURL forKey:@"UserProfilePic"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserProfilePic"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if (user.phone.length > 0)
        {
            [Keychain saveString:user.phone forKey:@"UserPhone"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserPhone"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
		CrumbModel* crumbModel = GETMODEL(CrumbModel);
		[crumbModel downloadCrumbs];
		ContactModel* contactModel = GETMODEL(ContactModel);
		[contactModel downloadContacts];
	}
	
    [PFPush storeDeviceToken:[AppDelegate getAppDelegate].token];
    [PFPush subscribeToChannelInBackground:[NSString stringWithFormat:@"user_%@", self.userID] target:self selector:@selector(subscribeFinished:error:)];
    
	[self callObserver:@selector(userModel:downloadCrumbsAndContacts:) withObject:self withObject:param];
	[param release];
}

-(void) failedDownloadCrumbsAndContacts:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed download crumbs & contacts: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
    
    if ([error code] == 1 || [error code] == 2)
    {
        param.failedReason = @"Unable to connect. Please try again.";
    }
    else
    {
        param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
    }
	
	[self callObserver:@selector(userModel:downloadCrumbsAndContacts:) withObject:self withObject:param];
	
	[param release];
}


#pragma mark
#pragma mark update user profile

-(void) updateUserProfile:(User *)userData
{
	NSString* requestString = [NSString stringWithFormat:@"%@/users/%@.json", KServeiceDomain, userData.userID];
    NSLog(@"%@", requestString);
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"]) {
        [request setPostValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] forKey:@"access_token"];
    }else {
        [request setPostValue:[Keychain getStringForKey:@"AccessToken"] forKey:@"access_token"];
    }
    [request setPostValue:userData.firstname forKey:@"user[firstname]"];
    [request setPostValue:userData.lastname forKey:@"user[lastname]"];
    [request setPostValue:userData.phone forKey:@"user[phone_number]"];
    [request setPostValue:userData.email forKey:@"user[email]"];
    [request setPostValue:userData.birthYear forKey:@"user[birth_year]"];
    [request setPostValue:userData.homeStreet forKey:@"user[home_street]"];
    [request setPostValue:userData.homeCity forKey:@"user[home_city]"];
    [request setPostValue:userData.homeState forKey:@"user[home_state]"];
    [request setPostValue:userData.homeZip forKey:@"user[home_zip]"];
    [request setPostValue:userData.homeCountry forKey:@"user[country]"];
    [request setPostValue:userData.height forKey:@"user[height]"];
    [request setPostValue:userData.weight forKey:@"user[weight]"];
    [request setPostValue:userData.eyes forKey:@"user[eyes]"];
    [request setPostValue:userData.hair forKey:@"user[hair]"];
    [request setPostValue:userData.gender forKey:@"user[gender]"];
    [request setPostValue:userData.ethnicity forKey:@"user[ethnicity]"];
    [request setPostValue:userData.notes forKey:@"user[notes]"];
    [request setPostValue:userData.vehicleYear forKey:@"user[vehicle_year]"];
    [request setPostValue:userData.vehicleMake forKey:@"user[vehicle_make]"];
    [request setPostValue:userData.vehicleModel forKey:@"user[vehicle_model]"];
    [request setPostValue:userData.vehicleColor forKey:@"user[vehicle_color]"];
    [request setPostValue:userData.vehicleLP forKey:@"user[license_plate]"];
    [request setPostValue:userData.vehicleLS forKey:@"user[license_state]"];
    [request setPostValue:userData.medicalAllergies forKey:@"user[medical_allergies]"];
    [request setPostValue:userData.medicalMedications forKey:@"user[medical_medications]"];
    [request setPostValue:userData.medicalConditions forKey:@"user[medical_other_conditions]"];
    [request setPostValue:userData.sendItinerary?@"true":@"false" forKey:@"user[send_itinerary]"];
    [request setPostValue:userData.sendOverview?@"true":@"false" forKey:@"user[send_to_new_contacts]"];
	[request setData:userData.photoData withFileName:@"avatar.png" andContentType:@"image/png" forKey:@"user[avatar]"];
    
    [request setRequestMethod:@"PUT"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successUpdateUserProfile:)];
	[request setDidFailSelector:@selector(failedUpdateUserProfile:)];
	
    [request startAsynchronous];
}

-(void) successUpdateUserProfile:(ASIHTTPRequest*)request
{
    
	NSString *responseString = [request responseString];
	NSLog(@"successed update:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
    
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
		param.success = YES;
        
        NSDictionary* userDic = [results objectForKey:@"user"];
        
        user = [[User alloc] init];
        
        user.userID = SafeCopy([userDic objectForKey:@"id"]);
        user.firstname = SafeCopy([userDic objectForKey:@"firstname"]);
        user.lastname = SafeCopy([userDic objectForKey:@"lastname"]);
        user.email = SafeCopy([userDic objectForKey:@"email"]);
        user.phone = SafeCopy([userDic objectForKey:@"phone_number"]);
        user.birthYear = SafeCopy([userDic objectForKey:@"birth_year"]);
        user.homeStreet =  SafeCopy([userDic objectForKey:@"home_street"]);
        user.homeCity =  SafeCopy([userDic objectForKey:@"home_city"]);
        user.homeState =  SafeCopy([userDic objectForKey:@"home_state"]);
        user.homeZip =  SafeCopy([userDic objectForKey:@"home_zip"]);
        user.homeCountry =  SafeCopy([userDic objectForKey:@"country"]);
        user.height = SafeCopy([userDic objectForKey:@"height"]);
        user.weight = SafeCopy([userDic objectForKey:@"weight"]);
        user.eyes = SafeCopy([userDic objectForKey:@"eyes"]);
        user.hair = SafeCopy([userDic objectForKey:@"hair"]);
        user.gender = SafeCopy([userDic objectForKey:@"gender"]);
		user.ethnicity = SafeCopy([userDic objectForKey:@"ethnicity"]);
        user.notes = SafeCopy([userDic objectForKey:@"notes"]);
        user.vehicleYear = SafeCopy([userDic objectForKey:@"vehicle_year"]);
        user.vehicleMake = SafeCopy([userDic objectForKey:@"vehicle_make"]);
        user.vehicleModel = SafeCopy([userDic objectForKey:@"vehicle_model"]);
        user.vehicleColor = SafeCopy([userDic objectForKey:@"vehicle_color"]);
        user.vehicleLP = SafeCopy([userDic objectForKey:@"license_plate"]);
        user.vehicleLS = SafeCopy([userDic objectForKey:@"license_state"]);
		user.medicalAllergies = SafeCopy([userDic objectForKey:@"medical_allergies"]);
		user.medicalMedications = SafeCopy([userDic objectForKey:@"medical_medications"]);
		user.medicalConditions = SafeCopy([userDic objectForKey:@"medical_other_conditions"]);
		user.sendItinerary = [[userDic objectForKey:@"send_itinerary"] boolValue];
		user.sendOverview = [[userDic objectForKey:@"send_to_new_contacts"] boolValue];
        user.photoURL = SafeCopy([userDic objectForKey:@"avatar"]);
	}
	
	[self callObserver:@selector(userModel:updateUserProfile:) withObject:self withObject:param];
	[param release];
}

-(void) failedUpdateUserProfile:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed sign in: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
    
    if ([error code] == 1 || [error code] == 2)
    {
        param.failedReason = @"Unable to connect. Please try again.";
    }
    else
    {
        param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
    }
	
	[self callObserver:@selector(userModel:updateUserProfile:) withObject:self withObject:param];
	
	[param release];
}



#pragma mark
#pragma mark signin

-(void) forgetPassword:(NSString *)email
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/users/password", KServeiceDomain]]];
    
    [request setPostValue:email forKey:@"user[email]"];
    
	[request setRequestCookies:nil];
    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successForgetPassword:)];
	[request setDidFailSelector:@selector(failedForgetPassword:)];
	
    [request startAsynchronous];
}

-(void) successForgetPassword:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
    
	NSLog(@"successed sign in:%@",responseString);
	    
	ReturnParam* param = [[ReturnParam alloc] init];
    param.success = YES;
    
	[self callObserver:@selector(userModel:forgetPassword:) withObject:self withObject:param];
	[param release];
}

-(void) failedForgetPassword:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed sign in: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
    
    if ([error code] == 1 || [error code] == 2)
    {
        param.failedReason = @"Unable to connect. Please try again.";
    }
    else
    {
        param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
    }
	
	[self callObserver:@selector(userModel:forgetPassword:) withObject:self withObject:param];
	
	[param release];
}


#pragma mark - ()

- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error {
    if ([result boolValue]) {
        NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
    } else {
        NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
    }
}

@end
