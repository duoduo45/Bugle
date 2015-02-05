//
//  NotificationManager.m
//  BreadCrumb
//
//  Created by apple on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NotificationManager.h"
#import "GlobalModel.h"
#import "AppDelegate.h"

@interface AlertViewWithData : UIAlertView

@property(nonatomic, strong) id userData;

@end

@implementation AlertViewWithData

@synthesize userData;

@end

@implementation NotificationManager

#pragma mark
#pragma mark Crumb Notification

-(void) clearAllNotifactions
{
	for( UILocalNotification* notification in [UIApplication sharedApplication].scheduledLocalNotifications )
	{
		[[UIApplication sharedApplication] cancelLocalNotification:notification];
	}
}

-(UILocalNotification*) findLocalNotification:(Crumb*)crumb
{
	for( UILocalNotification* notification in [UIApplication sharedApplication].scheduledLocalNotifications )
	{
		NSString* crumbId = [notification.userInfo objectForKey:@"crumbId"];
		if( [crumb.crumbId isEqualToString:crumbId] ) return notification;
	}
	return nil;
}

-(void) refreshCrumbNotification:(Crumb*)crumb
{
	UILocalNotification* notification = [self findLocalNotification:crumb];
	if( notification != nil )
	{
		[[UIApplication sharedApplication] cancelLocalNotification:notification];
	}
	if( ![crumb.status isEqualToString:@"pending"] ) return;
	
	NSTimeInterval interval = 0;
	
	NSDate* date = StringToDate(crumb.deadline);
	interval = [date timeIntervalSinceDate:[NSDate date]];
	
	if( interval < 0 ) return;
	if( interval > (10 * 60) ) interval = 10 * 60;
	
	notification = [[UILocalNotification alloc] init];
	notification.soundName =UILocalNotificationDefaultSoundName;
	notification.userInfo = [NSDictionary dictionaryWithObject:crumb.crumbId forKey:@"crumbId"];
	notification.timeZone = [NSTimeZone defaultTimeZone];
	notification.alertAction = @"view";
	notification.alertBody = [NSString stringWithFormat:@"Check-in reminder: %@", crumb.name];
	notification.fireDate = [NSDate dateWithTimeInterval:-interval sinceDate:date];
	[[UIApplication sharedApplication] scheduleLocalNotification:notification];
	[notification release];
}

#pragma mark
#pragma mark CrumbModelObserver

-(void) crumbModel:(CrumbModel*)crumbModel downloadCrumbs:(ReturnParam*)param
{
	[self clearAllNotifactions];
	
	for( Crumb* crumb in _crumbModel.crumbs )
	{
		[self refreshCrumbNotification:crumb];
	}
	
	[((AppDelegate*)[UIApplication sharedApplication].delegate) refreshBadges];
}

-(void) crumbModel:(CrumbModel*)crumbModel editCrumbs:(ReturnParam*)param
{
	Crumb* crumb = [param.userInfo objectForKey:@"crumb"];
	for( UILocalNotification* notification in [UIApplication sharedApplication].scheduledLocalNotifications )
	{
		if( [crumb.crumbId isEqualToString:[notification.userInfo objectForKey:@"crumbId"]] )
		{
			[[UIApplication sharedApplication] cancelLocalNotification:notification];
			break;
		}
	}
	
	[self refreshCrumbNotification:crumb];
	
	[((AppDelegate*)[UIApplication sharedApplication].delegate) refreshBadges];
}

#pragma mark
#pragma mark 一个本地通知被触发

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	AlertViewWithData* avd = (AlertViewWithData*)alertView;
	Crumb* crumb = (Crumb*)avd.userData;
	if( buttonIndex == 1 )
	{
		[GETMODEL(CrumbModel) checkInCrumb:crumb];
	}
	else if( buttonIndex == 2 )
	{
		[((AppDelegate*)[UIApplication sharedApplication].delegate) switchToCrumb:crumb];
	}
}

-(void) receive:(UILocalNotification*)notification
{
	
	NSString* crumbId = [notification.userInfo objectForKey:@"crumbId"];
	Crumb* crumb = nil;
	for( Crumb* c in GETMODEL(CrumbModel).crumbs )
	{
		if( [c.crumbId isEqualToString:crumbId] )
		{
			crumb = c;
			break;
		}
	}
	if( crumb == nil ) return;
	
//	NSString* message = [NSString stringWithFormat:@"Are you safe?\n\n"
//						 @"You have not checked in from your Bugle activity \"%@\".\n\n"
//						 @"If you do not check in within 5 minutes, your alert message will be sent automatically.", crumb.name];
//	AlertViewWithData* av = [[AlertViewWithData alloc] initWithTitle:@"Bugle Alert"
//															 message:message
//															delegate:self
//												   cancelButtonTitle:@"Dismiss this message"
//												   otherButtonTitles:@"Check In", @"View Activity Details", nil];
	NSString* message = [NSString stringWithFormat:@"Are you safe?\n\n"
						 @"Your activity '%@' is about to expire. Please check in now.", crumb.name];
	AlertViewWithData* av = [[AlertViewWithData alloc] initWithTitle:@"Bugle Alert"
															 message:message
															delegate:self
												   cancelButtonTitle:@"Dismiss"
												   otherButtonTitles:@"Check In", nil];
	av.userData = crumb;
	[av show];
	[av release];
}

#pragma mark
#pragma mark 成员函数

-(void) start
{
}

-(void) stop
{
}

#pragma mark
#pragma mark init & dealloc

+(NotificationManager*) getInstance
{
	static NotificationManager* g_Instance = nil;
	if( g_Instance == nil )
	{
		g_Instance = [[NotificationManager alloc] init];
	}
	return g_Instance;
}

-(void) dealloc
{
	_crumbModel = REMOVEOBSERVER(CrumbModel, self);
	[super dealloc];
}

-(id) init
{
	if( self = [super init] )
	{
		_crumbModel = ADDOBSERVER(CrumbModel, self);
	}
	return self;
}

@end
