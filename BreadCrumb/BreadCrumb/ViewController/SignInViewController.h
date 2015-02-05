//
//  SignInViewController.h
//  BreadCrumb
//
//  Created by Hui Jiang on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface SignInViewController : UIViewController <UITextFieldDelegate, FBLoginViewDelegate>
{
    long            editingTextTag;
}
@property(strong, nonatomic) IBOutlet UIControl             *ibControlView;

@property(strong, nonatomic) IBOutlet UITextField           *ibEmailField;
@property(strong, nonatomic) IBOutlet UITextField           *ibPasswordField;

@property(strong, nonatomic) IBOutlet UIView                *ibSigninView;
@property(strong, nonatomic) IBOutlet UIView                *ibTouchableView;
@property(strong, nonatomic) IBOutlet UIView                *ibBottomView;

@property(strong, nonatomic) IBOutlet FBLoginView           *ibFBLoginView;

@property(strong, nonatomic) IBOutlet UIToolbar             *ibToolBar;
@property(strong, nonatomic) IBOutlet UISegmentedControl    *ibPrevNextButton;

- (IBAction)signIn:(id)sender;
- (IBAction)forgotYourPassword:(id)sender;
- (IBAction)createNewAccount:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)prevNextButtonClick:(id)sender;
- (IBAction)doneButtonClick:(id)sender;

@end
