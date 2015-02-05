//
//  ProfileViewController.m
//  BreadCrumb
//
//  Created by 乔太太 on 13-2-19.
//
//

#import "ProfileViewController.h"
#import "AppDelegate.h"
#import "WaitingView.h"
#import "Flurry.h"
#import "Keychain.h"
#import <FacebookSDK/FacebookSDK.h>
#import "GlobalModel.h"

@interface ProfileViewController () <UserModelObserver>
{
    UserModel* _userModel;
}
@end

@implementation ProfileViewController

#pragma mark
#pragma mark utils

-(void) setButtonTitleByProfileView
{
    if( _profileView.profileChanged )
    {
        [AppDelegate getAppDelegate].mainTabBarController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClicked:)] autorelease];
        [AppDelegate getAppDelegate].mainTabBarController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClicked:)] autorelease];
    }
    else
    {
        [AppDelegate getAppDelegate].mainTabBarController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClicked:)] autorelease];
        [AppDelegate getAppDelegate].mainTabBarController.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark
#pragma mark button events

-(IBAction) leftButtonClicked:(id)sender
{
    if( _profileView.profileChanged )
    {
        [Flurry logEvent:@"my account view"];
        _profileView.profile = _userModel.user;
        [_profileView collectAll];
        [self setButtonTitleByProfileView];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserID"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserID"] : [Keychain deleteStringForKey:@"UserID"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserEmail"] : [Keychain deleteStringForKey:@"UserEmail"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPassword"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserPassword"] : [Keychain deleteStringForKey:@"UserPassword"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"AccessToken"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"AccessToken"] : [Keychain deleteStringForKey:@"AccessToken"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"RefreshToken"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"RefreshToken"] : [Keychain deleteStringForKey:@"RefreshToken"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserFirstName"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserFirstName"] : [Keychain deleteStringForKey:@"UserFirstName"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLastName"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserLastName"] : [Keychain deleteStringForKey:@"UserLastName"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPhone"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserPhone"] : [Keychain deleteStringForKey:@"UserPhone"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserProfilePic"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserProfilePic"] : [Keychain deleteStringForKey:@"UserProfilePic"];
          
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"AccessTokenUpdateDate"];
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"RefreshTokenUpdateDate"];
          
        [[NSUserDefaults standardUserDefaults] synchronize];
      
        FBSession* session = [FBSession activeSession];
        [session closeAndClearTokenInformation];
        [session close];
        [FBSession setActiveSession:nil];
        
        NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray* facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://facebook.com/"]];
        
        for (NSHTTPCookie* cookie in facebookCookies) {
          [cookies deleteCookie:cookie];
        }
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        [AppDelegate getAppDelegate].resignIn = YES;
        [[AppDelegate getAppDelegate] switchToSignIn];
        [AppDelegate getAppDelegate].mainTabBarController = nil;
    }
}

-(IBAction) rightButtonClicked:(id)sender
{
    if( _profileView.profileChanged )
    {
        [WaitingView popWaiting];
        [_userModel updateUserProfile:[_profileView getEditedProfile]];
    }
    else
    {
        [Flurry logEvent:@"edit account view"];
        [self setButtonTitleByProfileView];
    }
}

#pragma mark
#pragma mark ProfileViewDelegate

-(void) profileDidChanged
{
    [self setButtonTitleByProfileView];
}

#pragma mark
#pragma mark UserModelObserver

-(void) userModel:(UserModel*)userModel downloadCrumbsAndContacts:(ReturnParam*)param
{
    [_profileView setProfile:_userModel.user];
}

-(void) userModel:(UserModel*)userModel updateUserProfile:(ReturnParam*)param
{
    [WaitingView dismissWaiting];
    
    if( param.success )
    {
        [Flurry logEvent:@"my account view"];
        [_profileView setProfile:_userModel.user];
        [_profileView collectAll];
        [self setButtonTitleByProfileView];
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
#pragma mark init & dealloc

-(void) dealloc
{
    _userModel = REMOVEOBSERVER(UserModel, self);
    
    [_profileView release];
    
    [super dealloc];
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _userModel = ADDOBSERVER(UserModel, self);
    
    if (!_profileView) {
        _profileView = [[ProfileView alloc] initWithViewController:[AppDelegate getAppDelegate].mainTabBarController
                                 andDelegate:self];
        _profileView.frame = CGRectMake(0, NAV_AND_STARUS_BAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-NAV_AND_STARUS_BAR_HEIGHT-BOTTOM_TAB_HEIGHT);
        _profileView.profile = _userModel.user;
        [self.view addSubview:_profileView];
    }
    
    if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"isShowGettingStarted"] isEqualToString:@"NO"])
    {
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:@"Profile Information"
                message:@"If you’re ever overdue, people looking for you will want to know as much about you as possible.\n\nPlease complete your profile information on the following screen as thoroughly as you feel comfortable."
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil,nil];
        [alert show];
        [alert release];
    }
}

-(void) viewDidAppear:(BOOL)animated
{
    
    if (([AppDelegate getAppDelegate].isPresentModel) || (![[[NSUserDefaults standardUserDefaults] valueForKey:@"isShowGettingStarted"] isEqualToString:@"NO"])) {
        
        _profileView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-BOTTOM_TAB_HEIGHT);
        [AppDelegate getAppDelegate].isPresentModel = NO;
        [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"isShowGettingStarted"];
    }
    
    if( _userModel.user.userID.length == 0 )
    {
        [WaitingView popWaiting];
        [_userModel downloadCrumbsAndContacts];
    }
    
    [super viewDidAppear:animated];
    
    if( [_profileView isPickingImage] )
    {
        [_profileView cleanPickingImage];
        return;
    }
    
    [Flurry logEvent:@"my account view"];
    [Flurry logPageView];
    [_profileView setProfile:_userModel.user];
    _profileView.editMode = YES;
    [_profileView collectAll];
    
    [AppDelegate getAppDelegate].mainTabBarController.navigationController.navigationBarHidden = NO;
    [AppDelegate getAppDelegate].mainTabBarController.title = @"My Account";
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.titleView = nil;

    [self setButtonTitleByProfileView];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}

-(id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    if( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] )
    {
        self.title = @"My Account";
        self.tabBarItem.image = [UIImage imageNamed:@"Button_TabBarIcon_MyAccount.png"];
    }
    return self;
}

@end
