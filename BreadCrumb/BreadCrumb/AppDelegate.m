//
//  AppDelegate.m
//  BreadCrumb
//
//  Created by apple on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "RegistViewController.h"
#import "SignInViewController.h"
#import "TermsofServiceViewController.h"
#import "WelcomeAccountViewController.h"

#import "CrumbListViewController.h"
#import "CrumbDetailViewController.h"
#import "ContactListViewController.h"
#import "ProfileViewController.h"
#import "AboutViewController.h"
#import "KeepAlive.h"
#import "CheckOverdueCrumb.h"
#import "NotificationManager.h"
#import "WaitingView.h"

#import "SBJSON.h"
#import "Flurry.h"
#import "Toast+UIView.h"

#import "Keychain.h"
#import "HttpRequestDefine.h"

#import "iRate.h"
#import "GlobalModel.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>

static void handleRootException( NSException* exception )
{
    NSString* name = [exception name];
    NSString* reason = [exception reason];
	NSString* message = [NSString stringWithFormat:@"Name: %@   Reason: %@", name, reason];
    NSArray* symbols = [exception callStackSymbols]; // 异常发生时的调用栈
    NSMutableString* strSymbols = [[NSMutableString alloc] init]; // 将调用栈拼成输出日志的字符串
    for( NSString* item in symbols )
    {
        [strSymbols appendString:item];
        [strSymbols appendString:@"\r\n"];
    }
	
	NSLog(@"%@", strSymbols);
    [Flurry logError:@"Uncaught Crash" message:message exception:exception];
}

@interface AppDelegate () <UserModelObserver,CrumbModelObserver>
{
	UserModel* _userModel;
	CrumbModel* _crumbModel;
}
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize mainTabBarController = _mainTabBarController;
@synthesize resignIn;
@synthesize token;
@synthesize topmostView = _topmostView;

#pragma mark
#pragma mark 

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.gobugle.bugle";
    [iRate sharedInstance].verboseLogging = YES;
    [iRate sharedInstance].useAllAvailableLanguages = YES;
    
    [iRate sharedInstance].previewMode = NO;

}

-(void) newCrumbButtonClick:(id)sender
{
	UINavigationController* newCrumb = [[UINavigationController alloc] initWithRootViewController:[[CrumbDetailViewController alloc] initWithStyle:CrumbDetailStyleCreateNew andCrumb:nil]];
    [self.navigationController presentViewController:newCrumb animated:YES completion:nil];
    self.isPresentModel = YES;
	[newCrumb release];
}

#pragma mark
#pragma mark 设置提示图标

-(void) refreshCrumbs
{
	CrumbListViewController* clVC = [((AppDelegate*)[UIApplication sharedApplication].delegate).mainTabBarController.viewControllers objectAtIndex:0];
	[clVC.tableView reloadData];
}

-(void) refreshBadges
{
	NSInteger badgesNumber = 0;
	for( Crumb* c in GETMODEL(CrumbModel).crumbs )
	{
		if( [c isOverdue] )
		{
			badgesNumber++;
		}
	}
	if( badgesNumber <= 0 )
	{
		_activateCrumbHint.hidden = YES;
	}
	else
	{
		_activateCrumbHint.hidden = NO;
		if( badgesNumber >= 100 )
		{
			_activateCrumbCount.text = @"99+";
		}
		else
		{
			_activateCrumbCount.text = [NSString stringWithFormat:@"%ld", (long)badgesNumber];
		}
	}
	[UIApplication sharedApplication].applicationIconBadgeNumber = badgesNumber;
}

#pragma mark
#pragma mark 控制流切换

-(void) switchToRegist
{
    RegistViewController *registViewController = [[[RegistViewController alloc] initWithNibName:@"RegistViewController" bundle:nil] autorelease];
    [self.navigationController pushViewController:registViewController animated:NO];
}

-(void) switchToSignIn
{
	[[KeepAlive getInstance] stop];
	[[CheckOverdueCrumb getInstance] stop];
	[[NotificationManager getInstance] stop];
    
    SignInViewController *signInViewController = [[[SignInViewController alloc] initWithNibName:@"SignInViewController" bundle:nil] autorelease];
    [self.navigationController pushViewController:signInViewController animated:YES];
}

-(void) switchToTermsOfService
{
    TermsofServiceViewController *termsofServiceViewController = [[[TermsofServiceViewController alloc] initWithNibName:@"TermsofServiceViewController" bundle:nil] autorelease];
    [self.navigationController pushViewController:termsofServiceViewController animated:YES];
}

-(void) switchToWelcomeAccount
{
    WelcomeAccountViewController *welcomeAccountViewController = [[[WelcomeAccountViewController alloc] initWithNibName:@"WelcomeAccountViewController" bundle:nil] autorelease];
    [self.navigationController pushViewController:welcomeAccountViewController animated:YES];
}

-(void) switchToMain
{
    if( _mainTabBarController == nil )
    {
        
        _mainTabBarController = [[UITabBarController alloc] init];
        _mainTabBarController.delegate = self;
        _mainTabBarController.navigationItem.hidesBackButton = YES;
        _mainTabBarController.navigationController.navigationBarHidden = NO;

        CrumbListViewController* crumbList = [[CrumbListViewController alloc] initWithNibName:@"CrumbListViewController" bundle:nil];
        ContactListViewController* contactList = [[ContactListViewController alloc] initWithNibName:@"ContactListViewController" bundle:nil];
        UIViewController* placeHolder = [[UIViewController alloc] init];
        ProfileViewController* profile = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil];
        AboutViewController* about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
        
        _mainTabBarController.viewControllers = [NSArray arrayWithObjects:crumbList,
                                                 contactList,
												 placeHolder,
												 profile,
                                                 about, nil];
        [about release];
		[profile release];
		[placeHolder release];
        [contactList release];
        [crumbList release];
		
		UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button addTarget:self action:@selector(newCrumbButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        if (isiOS7UP) {
            button.frame = CGRectMake(128, _mainTabBarController.tabBar.frame.size.height - 49, 64, 49);
            [button setBackgroundImage:[UIImage imageNamed:@"Icon_Tab_Bar_New_Crumb_iOS7.png"] forState:UIControlStateNormal];
        }else {
            button.frame = CGRectMake(128, _mainTabBarController.tabBar.frame.size.height - 64, 64, 64);
            [button setBackgroundImage:[UIImage imageNamed:@"addCrumbIcon.png"] forState:UIControlStateNormal];
        }
		[_mainTabBarController.tabBar addSubview:button];
		
		_activateCrumbHint = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"messageHint.png"]];
		_activateCrumbHint.hidden = YES;
		_activateCrumbHint.frame = CGRectMake(40, _mainTabBarController.tabBar.frame.size.height - 60, 28, 28);
		[_mainTabBarController.tabBar addSubview:_activateCrumbHint];
		[_activateCrumbHint release];
		_activateCrumbCount = [[UILabel alloc] init];
		CGRect newFrame = _activateCrumbHint.bounds;
		newFrame.origin.x += 3;
		newFrame.size.width -= 6;
		newFrame.size.height -= 3;
		_activateCrumbCount.frame = newFrame;
		_activateCrumbCount.textColor = [UIColor whiteColor];
		_activateCrumbCount.backgroundColor = [UIColor clearColor];
		_activateCrumbCount.font = [UIFont boldSystemFontOfSize:14];
		_activateCrumbCount.textAlignment = NSTextAlignmentCenter;
		_activateCrumbCount.adjustsFontSizeToFitWidth = YES;
		[_activateCrumbHint addSubview:_activateCrumbCount];
		[_activateCrumbCount release];
        
        [self.navigationController pushViewController:_mainTabBarController animated:YES];
    }
    
}

-(void) switchToCrumb:(Crumb*)crumb
{
	[self switchToMain];
	self.mainTabBarController.selectedIndex = 0;
	
	CrumbDetailViewController* newCrumb = [[[CrumbDetailViewController alloc] initWithStyle:CrumbDetailStyleCheckIn andCrumb:crumb] autorelease];
    [self.navigationController pushViewController:newCrumb animated:YES];
}

-(void) switchToCrumbList
{
    [self switchToMain];
    self.mainTabBarController.selectedIndex = 0;
}

-(void) switchToCreateNewCrumb
{
	[self newCrumbButtonClick:nil];
}

-(void) switchToContactList
{	
    [self switchToMain];
    self.mainTabBarController.selectedIndex = 1;
}

-(void) switchToMyAccount
{
    [self switchToMain];
    self.mainTabBarController.selectedIndex = 3;
}

-(void) switchToAbout
{
    [self switchToMain];
    self.mainTabBarController.selectedIndex = 4;
}

-(void) fadeSplashView
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStop:finished:context:)];
    splashView.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)animationStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
    [splashView removeFromSuperview];
    [splashView release];
}

#pragma mark
#pragma mark handle automatic sign in

-(void) signined
{
	_autoSignin = NO;
	[WaitingView popWaiting];
	[[KeepAlive getInstance] start];
	[[CheckOverdueCrumb getInstance] start];
	[[NotificationManager getInstance] start];
	[_userModel downloadCrumbsAndContacts];
}

-(void) autoSignIn
{
	_userModel.userID = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserID"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserID"] : [Keychain getStringForKey:@"UserID"];
	_userModel.accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] : [Keychain getStringForKey:@"AccessToken"];
	_userModel.refreshToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"RefreshToken"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"RefreshToken"] : [Keychain getStringForKey:@"RefreshToken"];
	
	if (_userModel.accessToken == nil) 
	{
		[self switchToSignIn];
		return;
	}
	
	BOOL refreshTokenExpired = [_userModel checkRefreshToken];
	BOOL accessTokenExpired = [_userModel checkAccessToken];
	if( refreshTokenExpired )
	{
        [self switchToSignIn];
	}
	
	[self switchToCrumbList];
	
	if( accessTokenExpired )
	{
		_autoSignin = YES;
//		[WaitingView popWaiting];
		[_userModel updateAccessToken];
	}
    else
	{
		[self signined];
    }
}

- (void)reSignIn {
    NSString *email = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"] : [Keychain getStringForKey:@"UserEmail"];
    NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPassword"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPassword"] : [Keychain getStringForKey:@"UserPassword"];
    [_userModel signIn:email password:password];
}

#pragma mark
#pragma mark UserModelObserver

-(void) userModel:(UserModel*)userModel signIn:(ReturnParam*)param
{
	if( param.success )
	{
		[self signined];
	}
}

-(void) userModel:(UserModel *)userModel signInWithFacebookLogin:(ReturnParam *)param {
    if( param.success )
    {
        [self signined];
    }
}

-(void) userModel:(UserModel*)userModel updateAccessToken:(ReturnParam*)param
{
	[WaitingView dismissWaiting];

	if( !param.success )
	{
//		[self switchToSignIn];
	}
	else if( _autoSignin )
	{
		[self signined];
	}
}

-(void) userModel:(UserModel*)userModel downloadCrumbsAndContacts:(ReturnParam*)param
{
    [WaitingView dismissWaiting];
	
	if( param.success )
	{
		if( [self.navigationController topViewController] == _mainTabBarController ) return;
        
		if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"isShowTOS"] isEqualToString:@"NO"]) 
        { 
            [self switchToCrumbList];
		}
        else 
        {
			[self switchToTermsOfService];
		}
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Error"
							  message:param.failedReason
							  delegate:nil 
							  cancelButtonTitle:@"Close"
							  otherButtonTitles:nil,nil];
		[alert show];
		[alert release];
	}
}

#pragma mark
#pragma mark CrumbModelObserver

-(void) crumbModel:(CrumbModel*)crumbModel editCrumbs:(ReturnParam*)param
{
	[self switchToCrumbList];
	[self refreshBadges];
}

-(void) crumbModel:(CrumbModel*)crumbModel downloadCrumbs:(ReturnParam*)param
{
	[self refreshBadges];
}


#pragma mark
#pragma mark 初始化和销毁函数

- (void)dealloc
{
    _userModel = REMOVEOBSERVER(UserModel, self);
    _crumbModel = REMOVEOBSERVER(CrumbModel, self);

	[_window release];
	[_mainTabBarController release];
    [token release];
    
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    GlobalImageBufferToLocal* ibuf = [[GlobalImageBufferToLocal alloc] initWithPathString:@""];
	[InternetImageView setGlobalImageBuffer:ibuf];
	[ibuf release];
    
    // init Flurry
    [Flurry startSession:@"HF9NJNWSWHBTKSYRF7PK"];
    [Flurry setCrashReportingEnabled:YES];
    [Flurry setDebugLogEnabled:YES];
    
    // crash monitor
    NSSetUncaughtExceptionHandler(handleRootException);
    
    // Register for notifications
  
    [Parse setApplicationId:@"AawOxc47JJu3qNACb8gsa7KkMod7h1CT3IuAs1Bi" clientKey:@"jiELCavaePSk0MwBpmWT4cCqQrU5i0i184DRwa22"];
    
    [PFUser enableAutomaticUser];
    
    PFACL *defaultACL = [PFACL ACL];
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
 
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else
#endif
    {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeAlert |
                                                         UIRemoteNotificationTypeSound)];
    }
    
	_userModel = ADDOBSERVER(UserModel, self);
	_crumbModel = ADDOBSERVER(CrumbModel, self);
    
    [UIApplication sharedApplication].statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    resignIn = NO;

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    UIViewController *splashController = [[[UIViewController alloc] init] autorelease];
    splashView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background_faded.png"]];
    splashView.frame = CGRectMake(0, 0, self.window.frame.size.width, self.window.frame.size.height);
    [splashController.view addSubview:splashView];
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:splashController];
    self.navigationController = navi;
    self.window.rootViewController = navi;
    [navi release];
    
    // Override point for customization after application launch.
  
    [FBLoginView class];
  
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"SaveUser"] isEqualToString:@"YES"]) 
    {
		[self autoSignIn];
    } 
    else 
    {
        [self switchToRegist];
    }

    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window makeKeyAndVisible];

    [self fadeSplashView];
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:232.0/255.0 green:143.0/255.0 blue:37.0/255.0 alpha:0.8f]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    return YES;
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	[[NotificationManager getInstance] receive:notification];
	
	for( UIViewController* viewControl in [self.mainTabBarController viewControllers] )
	{
		if( [viewControl class] == [CrumbListViewController class] )
		{
			[((CrumbListViewController*)viewControl).tableView reloadData];
			 break;
		}
	}
	
	// todo: refresh crumb;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken 
{
    // Updates the device token and registers the token with UA
    token = [[NSData alloc] initWithData:deviceToken];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  
  // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
  BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
  
  // You can add your app-specific url handling code here if needed
  
  return wasHandled;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[[KeepAlive getInstance] stop];
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[KeepAlive getInstance] start];
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[WaitingView moveToTopMost];
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */ 	
}

+ (AppDelegate*) getAppDelegate {
	return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

@end
