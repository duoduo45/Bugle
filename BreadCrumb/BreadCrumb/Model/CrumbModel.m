//
//  CrumbModel.m
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CrumbModel.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "Keychain.h"
#import "HttpRequestDefine.h"
#import "iRate.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation CrumbModel

@synthesize crumbs;

#pragma mark
#pragma mark download crumbs

-(void) downloadCrumbs
{
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/crumbs.json?access_token=%@", KServeiceDomain, accessToken]]];
    
    [request setRequestMethod:@"GET"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(successDownloadCrumbs:)];
    [request setDidFailSelector:@selector(failedDownloadCrumbs:)];
    
    [request startAsynchronous];
}

-(void) successDownloadCrumbs:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed download crumbs:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];

	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( IsError(request, results, param) )
	{
	}
	else if( [results class] == [NSDictionary class] )
    {
        param.success = NO;
		param.failedReason = @"format error.";
    }
	else
	{
        param.success = YES;
		if( crumbs == nil )
		{
			crumbs = [[NSMutableArray alloc] init];
		}
		else
		{
			[crumbs removeAllObjects];
		}
		
		NSArray* crumbsArr = (NSArray*)results;
		
		for( int index=0; index < [crumbsArr count]; index++ )
		{
			NSDictionary* crumbDic = [[crumbsArr objectAtIndex:index] objectForKey:@"crumb"];
			
			Crumb *crumb = [[Crumb alloc] init];
			[crumb parseFromDictionary:crumbDic];
			
			[crumbs addObject:crumb];
			[crumb release];
		}
	}
	
	[self callObserver:@selector(crumbModel:downloadCrumbs:) withObject:self withObject:param];
	[param release];
}

-(void) failedDownloadCrumbs:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed download crumbs: %@",error);
	
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
	
	[self callObserver:@selector(crumbModel:downloadCrumbs:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark add crumb

-(void) addCrumb:(Crumb*)crumb
{
	NSString* requestString = [NSString stringWithFormat:@"%@/crumbs.json", KServeiceDomain];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
	NSString* contacts = @"";
	ContactModel* contactModel = GETMODEL(ContactModel);
	for( NSString* contactID in crumb.contacts )
	{
		for( Contact* contact in contactModel.contacts )
		{
			if( [contact.contactId isEqualToString:contactID] )
			{
				contacts = [contacts stringByAppendingFormat:@"%@,", contact.contactId];
				break;
			}
		}
	}
	if( contacts.length > 0 )
	{
		contacts = [contacts substringToIndex:contacts.length-1];
	}
	
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    [request setPostValue:accessToken forKey:@"access_token"];
    [request setPostValue:crumb.name forKey:@"crumb[name]"];
    [request setPostValue:crumb.alertMessage forKey:@"crumb[alert_message]"];
    [request setPostValue:contacts forKey:@"crumb[crumb_contact_ids]"];
    [request setPostValue:ServerDatetime(crumb.deadline) forKey:@"crumb[deadline]"];
    
    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successAddCrumb:)];
	[request setDidFailSelector:@selector(failedAddCrumb:)];
	
    [request startAsynchronous];
}

-(void) successAddCrumb:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed add a new crumb:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
    if( !IsError(request, results, param) )
	{
        param.success = YES;
		
		if( crumbs == nil )
		{
			crumbs = [[NSMutableArray alloc] init];
		}
		
		Crumb *crumb = [[Crumb alloc] init];
		[crumb parseFromDictionary:[results objectForKey:@"crumb"]];
		
		[crumbs addObject:crumb];
		[param.userInfo setObject:crumb forKey:@"crumb"];
		[crumb release];
	}
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	[param release];
}

-(void) failedAddCrumb:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed add a new crumb: %@",error);
	
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
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark edit crumb

-(void) editCrumb:(Crumb*)crumb
{
	NSString* requestString = [NSString stringWithFormat:@"%@/crumbs/%@.json", KServeiceDomain, crumb.crumbId];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
	NSString* contacts = @"";
	ContactModel* contactModel = GETMODEL(ContactModel);
	for( NSString* contactID in crumb.contacts )
	{
		for( Contact* contact in contactModel.contacts )
		{
			if( [contact.contactId isEqualToString:contactID] )
			{
				contacts = [contacts stringByAppendingFormat:@"%@,", contact.contactId];
				break;
			}
		}
	}
	if( contacts.length > 0 )
	{
		contacts = [contacts substringToIndex:contacts.length-1];
	}
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];
	
    [request setPostValue:accessToken forKey:@"access_token"];
    [request setPostValue:crumb.name forKey:@"crumb[name]"];
    [request setPostValue:crumb.alertMessage forKey:@"crumb[alert_message]"];
    [request setPostValue:contacts forKey:@"crumb[crumb_contact_ids]"];
    [request setPostValue:ServerDatetime(crumb.deadline) forKey:@"crumb[deadline]"];
    [request setPostValue:@"pending" forKey:@"crumb[status]"];
    
    [request setRequestMethod:@"PUT"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successEditCrumb:)];
	[request setDidFailSelector:@selector(failedEditCrumb:)];
	
    [request startAsynchronous];
}

-(void) successEditCrumb:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed edit a crumb:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
    if( !IsError(request, results, param) )
	{
        param.success = YES;
		
		NSDictionary* crumbDic = [results objectForKey:@"crumb"];
		
		Crumb *crumb = nil;
		
		for( Crumb* c in crumbs )
		{
			if( [c.crumbId isEqualToString:SafeCopy([crumbDic objectForKey:@"id"])] )
			{
				crumb = c;
				break;
			}
		}
		if( crumb != nil )
		{
			[crumb parseFromDictionary:crumbDic];
			[param.userInfo setObject:crumb forKey:@"crumb"];
		}
	}
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	[param release];
}

-(void) failedEditCrumb:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed edit a crumb: %@",error);
	
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
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark check in a crumb

-(void) checkInCrumb:(Crumb*)crumb
{
	NSString* requestString = [NSString stringWithFormat:@"%@/crumbs/%@/check_ins.json", KServeiceDomain, crumb.crumbId];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
	
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    [request setPostValue:accessToken forKey:@"access_token"];
    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successCheckInCrumb:)];
	[request setDidFailSelector:@selector(failedCheckInCrumb:)];
	
    [request startAsynchronous];
}

-(void) successCheckInCrumb:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed check in a crumb:%@",responseString);
	
    long count = [[iRate sharedInstance] eventCount];
    count++;
    
    [[iRate sharedInstance] setEventCount:count];
    
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
    if( !IsError(request, results, param) )
	{
        param.success = YES;
		NSDictionary* checkinCrumbs = [results objectForKey:@"check_in"];
		
		for( Crumb* crumb in self.crumbs )
		{
			if( [crumb.crumbId isEqualToString:[((NSNumber*)[checkinCrumbs objectForKey:@"crumb_id"]) stringValue]] )
			{
				crumb.lastCheckedTime = LastCheckedInDateToString([NSDate date]);
				crumb.status = @"checked_in";
				[param.userInfo setObject:crumb forKey:@"crumb"];
                _checkInCrumbs = crumb;
				break;
			}
		}
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@""
                              message:@"Check in successful"
                              delegate:self
                              cancelButtonTitle:@"Done"
                              otherButtonTitles:@"Share to Facebook",nil];
        [alert show];
        [alert release];
	}
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	[param release];
}

-(void) failedCheckInCrumb:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed check in a crumb: %@",error); 
	
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
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark cancel a crumb

-(void) cancelCrumb:(Crumb*)crumb
{
	NSString* requestString = [NSString stringWithFormat:@"%@/crumbs/%@.json", KServeiceDomain, crumb.crumbId];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    [request setPostValue:accessToken forKey:@"access_token"];
    [request setPostValue:@"cancelled" forKey:@"crumb[status]"];
    [request setPostValue:ServerDatetime(crumb.deadline) forKey:@"crumb[deadline]"];
    
    [request setRequestMethod:@"PUT"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successCancelCrumb:)];
	[request setDidFailSelector:@selector(failedCancelCrumb:)];
	
    [request startAsynchronous];
}

-(void) successCancelCrumb:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed cancel a crumb:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
    if( !IsError(request, results, param) )
	{
		param.success = YES;
		
		NSDictionary* crumbDic = [results objectForKey:@"crumb"];
		
		Crumb *crumb = nil;
		
		for( Crumb* c in crumbs )
		{
			if( [c.crumbId isEqualToString:SafeCopy([crumbDic objectForKey:@"id"])] )
			{
				crumb = c;
				break;
			}
		}
		if( crumb != nil )
		{
			crumb.status = SafeCopy([crumbDic objectForKey:@"status"]);
			
			[param.userInfo setObject:crumb forKey:@"crumb"];
		}
	}
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	[param release];
}

-(void) failedCancelCrumb:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed cancel a crumb: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
	param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark reuse a crumb

-(void) reuseCrumb:(Crumb*)crumb
{
	NSString* requestString = [NSString stringWithFormat:@"%@/crumbs/%@.json", KServeiceDomain, crumb.crumbId];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
	NSString* contacts = @"";
	ContactModel* contactModel = GETMODEL(ContactModel);
	for( NSString* contactID in crumb.contacts )
	{
		for( Contact* contact in contactModel.contacts )
		{
			if( [contact.contactId isEqualToString:contactID] )
			{
                NSLog(@"%@", contact.contactId);
				contacts = [contacts stringByAppendingFormat:@"%@,", contact.contactId];
				break;
			}
		}
	}
	if( contacts.length > 0 )
	{
		contacts = [contacts substringToIndex:contacts.length-1];
	}
	
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    [request setPostValue:accessToken forKey:@"access_token"];
    [request setPostValue:crumb.crumbId forKey:@"crumb[id]"];
    [request setPostValue:@"pending" forKey:@"crumb[status]"];
    [request setPostValue:crumb.name forKey:@"crumb[name]"];
    [request setPostValue:crumb.alertMessage forKey:@"crumb[alert_message]"];
    [request setPostValue:contacts forKey:@"crumb[crumb_contact_ids]"];
    [request setPostValue:ServerDatetime(crumb.deadline) forKey:@"crumb[deadline]"];
    
    [request setRequestMethod:@"PUT"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successReuseCrumb:)];
	[request setDidFailSelector:@selector(failedReuseCrumb:)];
	
    [request startAsynchronous];
}

-(void) successReuseCrumb:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed reuse a crumb:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
    if( !IsError(request, results, param) )
	{
        param.success = YES;
		
		NSDictionary* crumbDic = [results objectForKey:@"crumb"];
		
		Crumb *crumb = nil;
		
		for( Crumb* c in crumbs )
		{
			if( [c.crumbId isEqualToString:SafeCopy([crumbDic objectForKey:@"id"])] )
			{
				crumb = c;
				break;
			}
		}
		if( crumb != nil )
		{
			[crumb parseFromDictionary:crumbDic];
			[param.userInfo setObject:crumb forKey:@"crumb"];
		}
	}
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	[param release];
}

-(void) failedReuseCrumb:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed reuse a crumb: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
	param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark delete crumb

-(void) deleteCrumb:(Crumb*)crumb
{
	NSString* requestString = [NSString stringWithFormat:@"%@/crumbs/%@.json", KServeiceDomain, crumb.crumbId];
    NSLog(@"%@", requestString);
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
	if( !request.userInfo )
	{
		request.userInfo = [NSMutableDictionary dictionary];
	}
	[request.userInfo setValue:crumb forKey:@"crumb"];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    [request setPostValue:accessToken forKey:@"access_token"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setRequestMethod:@"DELETE"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successDeleteCrumb:)];
	[request setDidFailSelector:@selector(failedDeleteCrumb:)];
	
    [request startAsynchronous];
}

-(void) successDeleteCrumb:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed delete crumb:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	Crumb* crumb = [request.userInfo objectForKey:@"crumb"];
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
        param.success = YES;
		[param.userInfo setValue:crumb forKey:@"crumb"];
		NSNumber* crumbId = [results objectForKey:@"crumb_id"];
		if( [[crumbId stringValue] isEqualToString:crumb.crumbId] )
		{
			[self.crumbs removeObject:crumb];
		}
	}
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	[param release];
}

-(void) failedDeleteCrumb:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed delete crumb: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
	param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
	
	[self callObserver:@selector(crumbModel:editCrumbs:) withObject:self withObject:param];
	
	[param release];
}

-(void) sendItinerary:(Crumb*)crumb
{
	NSString* requestString = [NSString stringWithFormat:@"%@/crumbs/%@/send_itinerary", KServeiceDomain, crumb.crumbId];
    NSLog(@"%@", requestString);
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
	if( !request.userInfo )
	{
		request.userInfo = [NSMutableDictionary dictionary];
	}
	[request.userInfo setValue:crumb forKey:@"crumb"];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    [request setPostValue:accessToken forKey:@"access_token"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setRequestMethod:@"POST"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successSendItinerary:)];
	[request setDidFailSelector:@selector(failedSendItinerary:)];
	
    [request startAsynchronous];
}

-(void) successSendItinerary:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed send itinerary: %@",responseString);
	
	Crumb* crumb = [request.userInfo objectForKey:@"crumb"];
	ReturnParam* param = [[ReturnParam alloc] init];
	
	param.success = YES;
	[param.userInfo setValue:crumb forKey:@"crumb"];
	
	[self callObserver:@selector(crumbModel:sendItinerary:) withObject:self withObject:param];
	[param release];
}

-(void) failedSendItinerary:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed send itinerary: %@",error);
	
	ReturnParam* param = [[ReturnParam alloc] init];
	param.success = NO;
	param.failedReason = [NSString stringWithFormat:@"%@", [error localizedDescription]];
	
	Crumb* crumb = [request.userInfo objectForKey:@"crumb"];
	[param.userInfo setValue:crumb forKey:@"crumb"];
	
	[self callObserver:@selector(crumbModel:sendItinerary:) withObject:self withObject:param];
	
	[param release];
}


#pragma mark
#pragma mark UIAlertViewDelegate

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( buttonIndex != 0 )
	{
        NSLog(@"share to facebook");
        // Post a status update to the user's feed via the Graph API, and display an alert view
        // with the results or an error.
        
        NSString *desc;
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"UserFirstName"])
        {
            desc = [NSString stringWithFormat:@"%@ just checked in from %@ on Bugle. Check out the Bugle app for iPhone today.", [[NSUserDefaults standardUserDefaults] valueForKey:@"UserFirstName"], _checkInCrumbs.name];
        } else {
            desc = [NSString stringWithFormat:@"%@ just checked in from %@ on Bugle. Check out the Bugle app for iPhone today.", [Keychain getStringForKey:@"UserFirstName"], _checkInCrumbs.name];
        }
        
        // Check if the Facebook app is installed and we can present the share dialog
        FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:[NSURL URLWithString:@"http://ad.apps.fm/WeSnUecI49t-24GL89GyovE7og6fuV2oOMeOQdRqrE3GTqtC_GQMMzrlTEXqfB6wh-mxuJ_4mDuH0xTQmzyKT4-0kTrAdOWptGrMXWmEQMxrAYzueNmrQ4LSq1xYJUzS"]
                                                                       name:@"Bugle"
                                                                    caption:@"Notifications when you need them."
                                                                description:desc
                                                                    picture:[NSURL URLWithString:@"http://www.gobugle.com/assets/Icon@2x.png"]];

        // If the Facebook app is installed and we can present the share dialog
        BOOL isSuccessful = NO;
        if ([FBDialogs canPresentShareDialogWithParams:params]) {
            
            // Present share dialog
            FBAppCall *appCall = [FBDialogs presentShareDialogWithParams:params
                                                             clientState:nil
                                                                 handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                              if(error) {
                                                  UIAlertView *alert = [[UIAlertView alloc]
                                                                        initWithTitle:@"Error"
                                                                        message:[NSString stringWithFormat:@"Error publishing story: %@", error.description]
                                                                        delegate:nil
                                                                        cancelButtonTitle:@"Close"
                                                                        otherButtonTitles:nil,nil];
                                                  [alert show];
                                                  [alert release];
                                              } else {
                                                  // Success
                                                  NSLog(@"result %@", results);
                                              }
                                          }];
            isSuccessful = (appCall!= nil);
            

            // If the Facebook app is NOT installed and we can't present the share dialog
        } else {
            // FALLBACK: publish just a link using the Feed dialog
            
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"Bugle", @"name",
                                       @"Notifications when you need them.", @"caption",
                                       desc, @"description",
                                       @"http://ad.apps.fm/WeSnUecI49t-24GL89GyovE7og6fuV2oOMeOQdRqrE3GTqtC_GQMMzrlTEXqfB6wh-mxuJ_4mDuH0xTQmzyKT4-0kTrAdOWptGrMXWmEQMxrAYzueNmrQ4LSq1xYJUzS", @"link",
                                       @"http://www.gobugle.com/assets/Icon@2x.png", @"picture",
                                       nil];
            
            // Show the feed dialog
            [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                                   parameters:params
                                                      handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                          if (error) {
                                                              // An error occurred, we need to handle the error
                                                              // See: https://developers.facebook.com/docs/ios/errors
                                                              NSLog(@"Error publishing story: %@", error.description);
                                                          } else {
                                                              if (result == FBWebDialogResultDialogNotCompleted) {
                                                                  // User canceled.
                                                                  NSLog(@"User cancelled.");
                                                              } else {
                                                                  // Handle the publish feed callback
                                                                  NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                                  
                                                                  if (![urlParams valueForKey:@"post_id"]) {
                                                                      // User canceled.
                                                                      NSLog(@"User cancelled.");
                                                                      
                                                                  } else {
                                                                      // User clicked the Share button
                                                                      NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                                      NSLog(@"result %@", result);
                                                                  }
                                                              }
                                                          }
                                                      }];
        }
	}
}

// A function for parsing URL parameters returned by the Feed Dialog.
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

@end
