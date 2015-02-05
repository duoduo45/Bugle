//
//  TermsofServiceViewController.h
//  BreadCrumb
//
//  Created by Hui Jiang on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TermsofServiceViewController : UIViewController

@property(strong, nonatomic) IBOutlet UIButton                *ibAcceptBtn;
@property(strong, nonatomic) IBOutlet UIButton                *ibRejectBtn;
@property(strong, nonatomic) IBOutlet UIWebView               *ibWebView;

- (IBAction)cancel:(id)sender;
- (IBAction)accept:(id)sender;

@end
