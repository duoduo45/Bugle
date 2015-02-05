//
//  KeepAlive.h
//  BreadCrumb
//
//  Created by apple on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserModel.h"

@interface KeepAlive : NSObject <UserModelObserver>{
	NSCondition* _mutex;
	BOOL _stopFlag;
	
	id _expiredTarget;
	SEL _expiredAction;
	
	NSDate* _lastCheckTime;
	UserModel* _userModel;
}

+(KeepAlive*) getInstance;

-(void) setExpiredTarget:(id)target andAction:(SEL)action;

-(void) start;
-(void) stop;
-(void) fire;

@end
