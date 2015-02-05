//
//  CrumbDetailViewController.h
//  BreadCrumb
//
//  Created by dongwen on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BreadCrumbData.h"
#import "CrumbView.h"

@interface CrumbDetailViewController : UIViewController <CrumbViewDelegate>
{
	NSInteger _lastStyle;
	NSInteger _style;
	
	CrumbView* _crumbView;
	Crumb* _originCrumb;
	Crumb* _editingCrumb;
}

-(IBAction) leftButtonClick:(id)sender;
-(IBAction) rightButtonClick:(id)sender;

-(id) initWithStyle:(NSInteger)style andCrumb:(Crumb*)crumb;

@end
