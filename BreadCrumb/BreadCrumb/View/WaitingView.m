//
//  WaitingView.m
//  YAroundMe_Telecom
//
//  Created by Hugh on 10/14/10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WaitingView.h"
#import "AppDelegate.h"

@implementation WaitingView

#pragma mark
#pragma mark switch status

-(void) switchToNetworkWaiting
{
	_instruction.text = @"Connecting...";
	_waitingAnimation.frame = CGRectMake(60, 35, 40, 40);
}

#pragma mark
#pragma mark init & dealloc

-(void) dealloc
{
	[_waitingAnimation release];
	[_instruction release];
	[_foreground release];
	[_background release];
	
	[super dealloc];
}

-(id) initWithFrame:(CGRect)frame
{
    if( self = [super initWithFrame:frame] )
	{
		CGRect newFrame = [AppDelegate getAppDelegate].window.bounds;
		self.frame = newFrame;

		self.backgroundColor = [UIColor clearColor];
		_background = [[UIImageView alloc]initWithFrame:self.bounds];
		_background.userInteractionEnabled = YES;
		_background.image = [[UIImage imageNamed:@"activityViewBG.png"]stretchableImageWithLeftCapWidth:0 topCapHeight:0];
		[self addSubview:_background];
		
		_foreground = [[UIImageView alloc]initWithFrame:CGRectMake(80, (newFrame.size.height-80)/2, 160, 80)];
		_foreground.image = [[UIImage imageNamed:@"activityBG.png"] stretchableImageWithLeftCapWidth:45 topCapHeight:0];
		_foreground.userInteractionEnabled = YES;
		[self addSubview:_foreground];
		
		_instruction = [[UILabel alloc]initWithFrame:CGRectMake(0, 10, 160, 20)];
		_instruction.backgroundColor = [UIColor clearColor];
		_instruction.textColor = [UIColor whiteColor];
		_instruction.font = [UIFont systemFontOfSize:12];
		_instruction.textAlignment = NSTextAlignmentCenter;
		[_foreground addSubview:_instruction];
		
		_waitingAnimation = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[_foreground addSubview:_waitingAnimation];
		[_waitingAnimation startAnimating];
    }
    return self;
}

#pragma mark
#pragma mark singlition waiting view

static WaitingView* g_waitingView = nil;
static NSInteger g_referenceTime = 0;

+(void) popWaiting
{
	if( g_waitingView == nil )
	{
		g_waitingView = [[WaitingView alloc] init];
	}
	if( g_referenceTime == 0 )
	{
		UIView* topmostView = nil;
		if( [[AppDelegate getAppDelegate].window.rootViewController isKindOfClass:[UINavigationController class]] )
		{
			UINavigationController* nav = (UINavigationController*)[AppDelegate getAppDelegate].window.rootViewController;
			topmostView = ((UIViewController*)([nav.viewControllers objectAtIndex:0])).view;
		}
		else
		{
			topmostView = [AppDelegate getAppDelegate].window.rootViewController.view;
		}
		[topmostView addSubview:g_waitingView];
        [topmostView bringSubviewToFront:g_waitingView];
	}
	[g_waitingView switchToNetworkWaiting];
	g_referenceTime++;
}

+(void) dismissWaiting
{
	g_referenceTime--;
	if( g_referenceTime == 0 )
	{
		[g_waitingView removeFromSuperview];
	}
	else if( g_referenceTime < 0 )
	{
		g_referenceTime = 0;
	}
}

+(void) moveToTopMost
{
	if( g_waitingView.superview )
	{
		[g_waitingView.superview bringSubviewToFront:g_waitingView];
	}
}

@end
