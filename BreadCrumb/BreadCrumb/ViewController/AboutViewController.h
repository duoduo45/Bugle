//
//  AboutViewController.h
//  BreadCrumb
//
//  Created by dongwen on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController <UIScrollViewDelegate> {
}

@property (strong, nonatomic) IBOutlet UIScrollView* ibScrollView;
@property (strong, nonatomic) IBOutlet UIPageControl* ibPageControl;

@end
