//
//  AppDelegate.h
//  BreadCrumb
//
//  Created by apple on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BreadCrumbData.h"
#import "Macros.h"

@class MainTabBarController;
@class UserModel;
@class CrumbModel;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
    UIImageView *splashView;
	UIImageView*	_activateCrumbHint;
	UILabel*		_activateCrumbCount;
	
	BOOL _autoSignin;
	
	UIBackgroundTaskIdentifier bgTask;
	
	UIView* _topmostView;
}

@property (strong, nonatomic) UIWindow *window;
@property (assign) BOOL resignIn;
@property (strong, nonatomic) UITabBarController *mainTabBarController;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (strong, nonatomic) NSData *token;
@property (assign, readonly) UIView* topmostView;
@property (assign) BOOL isLoginFromFB;
@property (assign) BOOL isPresentModel;

-(void) refreshCrumbs;
-(void) refreshBadges;

-(void) switchToCreateNewCrumb;
-(void) switchToRegist;
-(void) switchToMain;
-(void) switchToSignIn;
-(void) switchToTermsOfService;
-(void) switchToCrumb:(Crumb*)crumb;
-(void) switchToCrumbList;
-(void) switchToContactList;
-(void) switchToMyAccount;
-(void) switchToAbout;
-(void) switchToWelcomeAccount;

-(void) reSignIn;

+ (AppDelegate*) getAppDelegate;

@end
