//
//  KeepAlive.m
//  BreadCrumb
//
//  Created by apple on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KeepAlive.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "AppDelegate.h"
#import "Toast+UIView.h"

//#define UPDATE_INTERVAL (5 * 60)
#define UPDATE_INTERVAL (60)

@interface KeepAlive(private)

-(void) updateAccessToken;

@end

@implementation KeepAlive

#pragma mark
#pragma mark private method

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( buttonIndex == 1 )
	{
//		[_mutex lock];
//		[_mutex signal];
//		[_mutex unlock];
	}
	else if( buttonIndex == 0 )
	{
//		[[AppDelegate getAppDelegate] switchToSignIn];
	}
}

-(void) userModel:(UserModel*)userModel updateAccessToken:(ReturnParam*)param
{
	if( param.success )
	{
		[_mutex lock];
		[_lastCheckTime release];
		_lastCheckTime = [[NSDate date] retain];
		[_mutex unlock];
	}
	else
	{
        if ([param.failedReason isEqualToString:@"invalid refresh token"]) {
            [[AppDelegate getAppDelegate] reSignIn];
        }
	}
}

-(void) updateAccessToken
{
	[WaitingView popWaiting];
	[_userModel updateAccessToken];
}

#pragma mark
#pragma mark 刷新线程

-(void) refreshThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while( YES )
	{
		[_mutex lock];
		[_mutex waitUntilDate:[NSDate dateWithTimeInterval:UPDATE_INTERVAL sinceDate:_lastCheckTime]];
		[_lastCheckTime release];
		_lastCheckTime = [[NSDate date] retain];
		[_mutex unlock];
		
		if( _stopFlag )
		{
			NSLog(@"keep alive dead");
			break;
		}
		
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"'update access token at:' YYYY-MM-dd HH:mm:ss"];
		NSLog(@"%@", [formatter stringFromDate:[NSDate date]]);
		[formatter release];
		
		if( ([GETMODEL(UserModel) checkRefreshToken]))
		{
            [[AppDelegate getAppDelegate] reSignIn];
		}
		else
		{
            if ([GETMODEL(UserModel) checkAccessToken]) {
                [self performSelectorOnMainThread:@selector(updateAccessToken) withObject:nil waitUntilDone:YES];
            }
		}
		
	}
	
	[pool release];
}

#pragma mark
#pragma mark 成员函数

+(KeepAlive*) getInstance
{
	static KeepAlive* s_gKeepAlive = nil;
	if( s_gKeepAlive == nil )
	{
		s_gKeepAlive = [[KeepAlive alloc] init];
	}
	
	return s_gKeepAlive;
}

-(void) setExpiredTarget:(id)target andAction:(SEL)action
{
	_expiredTarget = target;
	_expiredAction = action;
}

-(void) start
{
	NSLog(@"start keep alive");
	
	if( !_lastCheckTime )
	{
		_lastCheckTime = [[NSDate date] retain];
	}
	
	if( _stopFlag )
	{
		_stopFlag = NO;
		[NSThread detachNewThreadSelector:@selector(refreshThread) toTarget:self withObject:self];
	}
}

-(void) stop
{
	NSLog(@"stop keep alive");
	if( !_stopFlag )
	{
		_stopFlag = YES;
		[_mutex lock];
		[_mutex signal];
		[_mutex unlock];
	}
}

-(void) fire
{
	[_mutex lock];
	[_mutex signal];
	[_mutex unlock];
}

#pragma mark
#pragma mark init & dealloc

-(void) dealloc
{
	_userModel = REMOVEOBSERVER(UserModel, self);
	[self stop];
	[_lastCheckTime release];
	[_mutex release];
	[super dealloc];
}

-(id) init
{
	if( self = [super init] )
	{
		_userModel = ADDOBSERVER(UserModel, self);
		_stopFlag = YES;
		_mutex = [[NSCondition alloc] init];
	}
	return self;
}

@end
