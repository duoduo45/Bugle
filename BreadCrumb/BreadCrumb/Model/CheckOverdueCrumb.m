//
//  CheckOverdueCrumb.m
//  BreadCrumb
//
//  Created by apple on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CheckOverdueCrumb.h"
#import "AppDelegate.h"
#import "CrumbListViewController.h"

#define UPDATE_INTERVAL (1 * 60)

@implementation CheckOverdueCrumb

#pragma mark
#pragma mark 刷新线程

-(void) timerFire
{
	[_mutex unlock];
	[_mutex lock];
}

-(void) refreshThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while( YES )
	{
		[_mutex lock];
		[_mutex unlock];
		
		if( _stopFlag )
		{
			NSLog(@"check overdue thread dead");
			break;
		}
		
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"'check overdue at:' YYYY-MM-dd HH:mm:ss"];
		NSLog(@"%@", [formatter stringFromDate:[NSDate date]]);
		[formatter release];
		
		[((AppDelegate*)[UIApplication sharedApplication].delegate) performSelectorOnMainThread:@selector(refreshBadges) withObject:nil waitUntilDone:YES];
		[((AppDelegate*)[UIApplication sharedApplication].delegate) performSelectorOnMainThread:@selector(refreshCrumbs) withObject:nil waitUntilDone:YES];
	}
	
	[pool release];
}

#pragma mark
#pragma mark 成员函数

+(CheckOverdueCrumb*) getInstance
{
	static CheckOverdueCrumb* s_gCheckOverdueCrumb = nil;
	if( s_gCheckOverdueCrumb == nil )
	{
		s_gCheckOverdueCrumb = [[CheckOverdueCrumb alloc] init];
	}
	
	return s_gCheckOverdueCrumb;
}

-(void) setExpiredTarget:(id)target andAction:(SEL)action
{
	_expiredTarget = target;
	_expiredAction = action;
}

-(void) start
{
	_stopFlag = NO;
	
	if( _timer == nil )
	{
//#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
//		BOOL multiTaskingSupported = NO;
//		if( [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] )
//		{
//			multiTaskingSupported = [(id)[UIDevice currentDevice] isMultitaskingSupported];
//		}
//		
//		if( multiTaskingSupported )
//		{
//			backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//				// Synchronize the cleanup call on the main thread in case
//				// the task actually finishes at around the same time.
//				dispatch_async(dispatch_get_main_queue(), ^{
//					if (backgroundTask != UIBackgroundTaskInvalid)
//					{
//						[[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
//						backgroundTask = UIBackgroundTaskInvalid;
//						[self stop];
//					}
//				});
//			}];
//		}
//#endif
		

		[NSThread detachNewThreadSelector:@selector(refreshThread)
								 toTarget:self
							   withObject:nil];
		
		_timer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL
												   target:self
												 selector:@selector(timerFire)
												 userInfo:nil
												  repeats:YES] retain];
	}
	else
	{
		[_timer fire];
	}
}

-(void) stop
{
	if( _timer != nil )
	{
//#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
//		BOOL multiTaskingSupported = NO;
//		if( [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] )
//		{
//			multiTaskingSupported = [(id)[UIDevice currentDevice] isMultitaskingSupported];
//		}
//		if( multiTaskingSupported )
//		{
//			dispatch_async(dispatch_get_main_queue(), ^{
//				if (backgroundTask != UIBackgroundTaskInvalid) {
//					[[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
//					backgroundTask = UIBackgroundTaskInvalid;
//				}
//			});
//		}
//#endif
		
		_stopFlag = YES;
		[_timer fire];
		[_timer invalidate];
		[_timer release];
		_timer = nil;
	}
}

#pragma mark
#pragma mark init & dealloc

-(void) dealloc
{
	[self stop];
	[_mutex unlock];
	[_mutex release];
	[super dealloc];
}

-(id) init
{
	if( self = [super init] )
	{
		_mutex = [[NSCondition alloc] init];
		[_mutex lock];
	}
	return self;
}

@end
