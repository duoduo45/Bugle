//
//  NotificationManager.h
//  BreadCrumb
//
//  Created by apple on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CrumbModel.h"

@interface NotificationManager : NSObject<CrumbModelObserver>{
	CrumbModel* _crumbModel;
}

+(NotificationManager*) getInstance;

-(void) start;
-(void) stop;
-(void) receive:(UILocalNotification*)notification;

@end
