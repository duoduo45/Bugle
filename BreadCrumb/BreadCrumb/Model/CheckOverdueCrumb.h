//
//  CheckOverdueCrumb.h
//  BreadCrumb
//
//  Created by apple on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckOverdueCrumb : NSObject {
	NSCondition* _mutex;
	NSTimer* _timer;
	BOOL _stopFlag;
	
	id _expiredTarget;
	SEL _expiredAction;
	
	UIBackgroundTaskIdentifier backgroundTask;
}

+(CheckOverdueCrumb*) getInstance;

-(void) setExpiredTarget:(id)target andAction:(SEL)action;

-(void) start;
-(void) stop;


@end
