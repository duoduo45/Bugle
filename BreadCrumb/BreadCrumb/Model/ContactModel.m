//
//  ContactModel.m
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContactModel.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "WaitingView.h"
#import "UserModel.h"
#import "Keychain.h"
#import "HttpRequestDefine.h"

@implementation ContactModel

@synthesize contacts;

#pragma mark
#pragma mark download contacts

-(void) downloadContacts
{
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/contacts.json?access_token=%@", KServeiceDomain, accessToken]]];
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@/contacts.json?access_token=%@", KServeiceDomain, accessToken]);
    
    [request setRequestMethod:@"GET"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(successDownloadContacts:)];
    [request setDidFailSelector:@selector(failedDownloadContacts:)];
    
    [request startAsynchronous];
}

-(void) successDownloadContacts:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed download contacts:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
    
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( IsError(request, results, param ) )
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
        
		if( contacts == nil )
		{
			contacts = [[NSMutableArray alloc] init];
		}
		else
		{
			[contacts removeAllObjects];
		}
		
		NSArray* contactsArr = (NSArray*)results;

		for( int index=0; index < [contactsArr count]; index++ )
		{
			NSDictionary* contactDic = [[contactsArr objectAtIndex:index] objectForKey:@"contact"];
			Contact *contact = [[Contact alloc] init];
			contact.contactId = SafeCopy([contactDic objectForKey:@"id"]);
			contact.email = SafeCopy([contactDic objectForKey:@"email"]);
			contact.firstName = SafeCopy([contactDic objectForKey:@"firstname"]);
			contact.lastName = SafeCopy([contactDic objectForKey:@"lastname"]);
			contact.phoneNumber = SafeCopy([contactDic objectForKey:@"phone_number"]);
            contact.notes = SafeCopy([contactDic objectForKey:@"notes"]);
            contact.photoURL = SafeCopy([contactDic objectForKey:@"avatar"]);
                    
			[contacts addObject:contact];
			[contact release];
		}
	}
	
	[self callObserver:@selector(contactModel:downloadContacts:) withObject:self withObject:param];

	[param release];
}

-(void) failedDownloadContacts:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed download contacts: %@",error);
	
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
	
	[self callObserver:@selector(contactModel:downloadContacts:) withObject:self withObject:param];
	
	[param release];
}

#pragma mark
#pragma mark edit contact

-(void) editContact:(Contact *)contact
{
	NSString* requestString = [NSString stringWithFormat:@"%@/contacts/%@.json", KServeiceDomain, contact.contactId];
    NSLog(@"%@", requestString);
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];
    
    [request setPostValue:accessToken forKey:@"access_token"];
    [request setPostValue:contact.firstName forKey:@"contact[firstname]"];
    [request setPostValue:contact.lastName forKey:@"contact[lastname]"];
    [request setPostValue:contact.email forKey:@"contact[email]"];
    [request setPostValue:contact.phoneNumber forKey:@"contact[phone_number]"];
    [request setPostValue:contact.notes forKey:@"contact[notes]"];
    [request setData:contact.photoData withFileName:@"avatar.png" andContentType:@"image/png" forKey:@"contact[avatar]"];

    [request setRequestMethod:@"PUT"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successEditContact:)];
	[request setDidFailSelector:@selector(failedEditContact:)];
	
    [request startAsynchronous];
}

-(void) successEditContact:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed edit contact:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
        param.success = YES;
		
		NSDictionary* contactDic = [results objectForKey:@"contact"];
		
		Contact *contact = nil;
		
		for( Contact* c in contacts )
		{
			if( [c.contactId isEqualToString:SafeCopy([contactDic objectForKey:@"id"])] )
			{
				contact = c;
				break;
			}
		}
		if( contact != nil )
		{
			contact.email = SafeCopy([contactDic objectForKey:@"email"]);
			contact.firstName = SafeCopy([contactDic objectForKey:@"firstname"]);
			contact.lastName = SafeCopy([contactDic objectForKey:@"lastname"]);
			contact.phoneNumber = SafeCopy([contactDic objectForKey:@"phone_number"]);
            contact.notes = SafeCopy([contactDic objectForKey:@"notes"]);
            contact.photoURL = SafeCopy([contactDic objectForKey:@"avatar"]);
			
			[param.userInfo setObject:contact forKey:@"contact"];
		}
	}
	
	[self callObserver:@selector(contactModel:editContacts:) withObject:self withObject:param];
	[param release];
}

-(void) failedEditContact:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed edit contact: %@",error);
	
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
	
	[self callObserver:@selector(contactModel:editContacts:) withObject:self withObject:param];
	
	[param release];
}


#pragma mark
#pragma mark add contact

-(void) addContact:(Contact *)contact
{
	NSString* requestString = [NSString stringWithFormat:@"%@/contacts.json", KServeiceDomain];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];
	
    [request setPostValue:accessToken forKey:@"access_token"];
    [request setPostValue:contact.firstName forKey:@"contact[firstname]"];
    [request setPostValue:contact.lastName forKey:@"contact[lastname]"];
    [request setPostValue:contact.email forKey:@"contact[email]"];
    [request setPostValue:contact.phoneNumber forKey:@"contact[phone_number]"];
    [request setPostValue:contact.notes forKey:@"contact[notes]"];
    [request setData:contact.photoData withFileName:@"avatar.png" andContentType:@"image/png" forKey:@"contact[avatar]"];

    [request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successAddContact:)];
	[request setDidFailSelector:@selector(failedAddContact:)];
	
    [request startAsynchronous];
}

-(void) successAddContact:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed add a new contact:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
        param.success = YES;
		
		if( contacts == nil )
		{
			contacts = [[NSMutableArray alloc] init];
		}
		
		NSDictionary* contactDic = [results objectForKey:@"contact"];
		
		Contact *contact = [[Contact alloc] init];
		contact.contactId = SafeCopy([contactDic objectForKey:@"id"]);
		contact.email = SafeCopy([contactDic objectForKey:@"email"]);
		contact.firstName = SafeCopy([contactDic objectForKey:@"firstname"]);
		contact.lastName = SafeCopy([contactDic objectForKey:@"lastname"]);
		contact.phoneNumber = SafeCopy([contactDic objectForKey:@"phone_number"]);
		contact.notes = SafeCopy([contactDic objectForKey:@"notes"]);
        contact.photoURL = SafeCopy([contactDic objectForKey:@"avatar"]);
        
		[contacts addObject:contact];
		[param.userInfo setObject:contact forKey:@"contact"];
		[contact release];
	}
	
	[self callObserver:@selector(contactModel:addContact:) withObject:self withObject:param];
	[param release];
}

-(void) failedAddContact:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed add a new contact: %@",error);
	
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
	
	[self callObserver:@selector(contactModel:addContact:) withObject:self withObject:param];
	
	[param release];
}


#pragma mark
#pragma mark delete contact

-(void) deleteContact:(Contact *)contact
{
	NSString* requestString = [NSString stringWithFormat:@"%@/contacts/%@.json", KServeiceDomain, contact.contactId];
    NSLog(@"%@", requestString);
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];

    [request setPostValue:accessToken forKey:@"access_token"];
	[request addRequestHeader:@"Accept" value:@"application/json"];
    [request setRequestMethod:@"DELETE"];
    [request setDelegate:self];
	[request setDidFinishSelector:@selector(successDeleteContact:)];
	[request setDidFailSelector:@selector(failedDeleteContact:)];
	
    [request startAsynchronous];
}

-(void) successDeleteContact:(ASIHTTPRequest*)request
{
	NSString *responseString = [request responseString];
	NSLog(@"successed delete a contact:%@",responseString);
	
    NSDictionary *results = [responseString JSONValue];
	
	ReturnParam* param = [[ReturnParam alloc] init];
	
	if( !IsError(request, results, param) )
	{
        param.success = YES;
                				
        NSLog(@"%@", SafeCopy([results objectForKey:@"contact_id"]));
                  
		for( Contact* c in contacts )
		{
			if( [c.contactId isEqualToString:SafeCopy([results objectForKey:@"contact_id"])] )
			{
				[contacts removeObject:c];
				break;
			}
		}
	}
	
	[self callObserver:@selector(contactModel:deleteContact:) withObject:self withObject:param];
	[param release];
}

-(void) failedDeleteContact:(ASIHTTPRequest*)request
{
    NSError *error = [request error];
	NSLog(@"failed delete a contact: %@",error);
	
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
    
	[self callObserver:@selector(contactModel:deleteContact:) withObject:self withObject:param];
	
	[param release];
}

@end
