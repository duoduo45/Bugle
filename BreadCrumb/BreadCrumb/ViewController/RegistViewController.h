//
//  RegistViewController.h
//  BreadCrumb
//
//  Created by dongwen on 12-1-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface RegistViewController : UIViewController <UITextFieldDelegate, FBLoginViewDelegate>
{
    int             editingTextTag;
}

@property(strong, nonatomic) IBOutlet UIControl             *ibControlView;

@property(strong, nonatomic) IBOutlet UITextField           *ibEmailField;
@property(strong, nonatomic) IBOutlet UITextField           *ibPasswordField;
@property(strong, nonatomic) IBOutlet UITextField           *ibRepeatPasswordField;

@property(strong, nonatomic) IBOutlet UIView                *ibRegisterView;
@property(strong, nonatomic) IBOutlet UIView                *ibTouchableView;
@property(strong, nonatomic) IBOutlet UIView                *ibBottomView;

@property(strong, nonatomic) IBOutlet FBLoginView           *ibFBLoginView;

@property(strong, nonatomic) IBOutlet UILabel               *ibWelcomeLbl;
@property(strong, nonatomic) IBOutlet UILabel               *ibIntroLbl;
@property(strong, nonatomic) IBOutlet UIImageView           *ibLogoView;

@property(strong, nonatomic) IBOutlet UIToolbar             *ibToolBar;
@property(strong, nonatomic) IBOutlet UISegmentedControl    *ibPrevNextButton;

- (IBAction)submit:(id)sender;
- (IBAction)alreadyAMemeber:(id)sender;
- (IBAction)privacyPolicy:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)prevNextButtonClick:(id)sender;
- (IBAction)doneButtonClick:(id)sender;

@end
