//
//  CrumbListItem.h
//  BreadCrumb
//
//  Created by dongwen on 12-1-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BreadCrumbData.h"


@protocol CrumbListItemDelegate <NSObject>

-(void) deleteButtonClickWithCrumb:(Crumb*)crumb;

@end

@interface CrumbListItem : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* title;
@property (strong, nonatomic) IBOutlet UILabel* content;
@property (strong, nonatomic) IBOutlet UIButton* button;

@property (strong, nonatomic) UIView* maskView;
@property (strong, nonatomic) UIButton* deleteBtn;

@property (strong, nonatomic) Crumb* crumb;

@property (strong, nonatomic) id<CrumbListItemDelegate> delegate;

@end
