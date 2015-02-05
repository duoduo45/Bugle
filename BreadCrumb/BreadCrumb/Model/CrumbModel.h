//
//  CrumbModel.h
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModelObserver.h"
#import "BreadCrumbData.h"

@interface CrumbModel : BaseModel <UIAlertViewDelegate> {
	NSTimer* _refreshTimer;
    Crumb *_checkInCrumbs;
}

@property (strong, nonatomic) NSMutableArray* crumbs;

-(void) downloadCrumbs;
-(void) addCrumb:(Crumb*)crumb;
-(void) editCrumb:(Crumb*)crumb;
-(void) checkInCrumb:(Crumb*)crumb;
-(void) cancelCrumb:(Crumb*)crumb;
-(void) reuseCrumb:(Crumb*)crumb;
-(void) deleteCrumb:(Crumb*)crumb;

-(void) sendItinerary:(Crumb*)crumb;

@end


@protocol CrumbModelObserver <BaseModelObserver>
@optional
-(void) crumbModel:(CrumbModel*)crumbModel downloadCrumbs:(ReturnParam*)param;
-(void) crumbModel:(CrumbModel*)crumbModel editCrumbs:(ReturnParam*)param;
-(void) crumbModel:(CrumbModel*)crumbModel sendItinerary:(ReturnParam*)param;
@end
