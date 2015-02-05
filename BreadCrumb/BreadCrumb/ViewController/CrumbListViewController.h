//
//  CrumbListViewController.h
//  BreadCrumb
//
//  Created by dongwen on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"

@interface CrumbListViewController : UIViewController <EGORefreshTableHeaderDelegate> {
    
	NSMutableArray* arrayOfActive;
	NSMutableArray* arrayOfRecent;
	IBOutlet UIView* _emptyView;
	
	BOOL _selfRequest;
	
	UIColor* _separatorColor;
	EGORefreshTableHeaderView* _refreshHeaderView;
    BOOL _reloading;
}

@property (strong, nonatomic) IBOutlet UITableView* tableView;

@end
