//
//  RegistViewController.m
//  BreadCrumb
//
//  Created by dongwen on 12-1-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "RegistViewController.h"
#import "SignInViewController.h"
#import "AppDelegate.h"
#import "WaitingView.h"
#import "SBJson.h"
#import "Flurry.h"
#import "Keychain.h"
#import "Toast+UIView.h"
#import "GlobalModel.h"

#define PRIVACY_URL					(@"http://gobugle.com/privacy")

@interface RegistViewController () <UserModelObserver>
{
    UserModel *_userModel;
}

@end

@implementation RegistViewController

#pragma mark
#pragma mark Keyboard Event

- (void)textFieldDidEndEditing:(id)sender 
{
    self.ibIntroLbl.hidden = NO;
    CGRect newFrame = self.ibControlView.frame;
    newFrame.origin.y += 160;
    self.ibControlView.frame = newFrame;
}

- (void)textFieldDidBeginEditing:(id)sender 
{
    self.ibIntroLbl.hidden = YES;

    [_ibPrevNextButton setEnabled:(sender!=_ibEmailField) forSegmentAtIndex:0];
    [_ibPrevNextButton setEnabled:(sender!=_ibRepeatPasswordField) forSegmentAtIndex:1];
    
    CGRect newFrame = self.ibControlView.frame;
    newFrame.origin.y -= 160;
    self.ibControlView.frame = newFrame;
    
    editingTextTag = ((UITextField*)sender).tag;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string 
{
    if( range.length > string.length ) return YES;
	
    NSInteger length = [textField.text substringToIndex:range.location].length + string.length + [textField.text substringFromIndex:range.location+range.length].length;
	
    if( textField == self.ibEmailField ) return (length <= 50);
    else if( textField == self.ibPasswordField ) return (length <= 25);
    else if( textField == self.ibRepeatPasswordField) return (length <= 25);
	
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField 
{
    
    UITextField* textFields[] = 
    {
        _ibEmailField,
        _ibPasswordField,
        _ibRepeatPasswordField
    };
    
    for (int i=0; i<sizeof(textFields)/sizeof(UITextField*); i++) 
    {
        if (textFields[i] != textField) continue;
        
        [textFields[i] resignFirstResponder];
        if (i+1 < sizeof(textFields)/sizeof(UITextField*))
        {
            [textFields[i+1] becomeFirstResponder];
            editingTextTag = textFields[i+1].tag;
        }
        else
        {
            [self submit:nil];
            ///TODO: trigger submit event
        }
        break;
    }
    return YES;
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGRect newFrame = self.ibToolBar.frame;
    newFrame.origin.y = SCREEN_HEIGHT-keyboardSize.height-newFrame.size.height-(isiOS7UP?0:20);
    self.ibToolBar.frame = newFrame;
    
    self.ibToolBar.hidden = NO;
    
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    self.ibToolBar.hidden = YES;
}

#pragma mark
#pragma mark Button Action

- (BOOL)emailValidate:(NSString *)email 
{
    
    //Based on the string below
    //NSString *strEmailMatchstring=@"\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,6})\\b";
	
    //Quick return if @ Or . not in the string
    if([email rangeOfString:@"@"].location==NSNotFound || [email rangeOfString:@"."].location==NSNotFound)
    {
        return NO;
    }
	
    //Break email address into its components
    NSString *accountName=[email substringToIndex: [email rangeOfString:@"@"].location];
    email=[email substringFromIndex:[email rangeOfString:@"@"].location+1];
	
    //'.' not present in substring
    if([email rangeOfString:@"."].location==NSNotFound)
        return NO;
    NSString *domainName=[email substringToIndex:[email rangeOfString:@"."].location];
    NSString *subDomain=[email substringFromIndex:[email rangeOfString:@"."].location+1];
    
    if (!([subDomain rangeOfString:@"."].location==NSNotFound))
    {
        subDomain=[subDomain substringFromIndex:[subDomain rangeOfString:@"."].location+1];
    }
	
    //username, domainname and subdomain name should not contain the following charters below
    //filter for user name
    NSString *unWantedInUName = @" ~!@#$^&*()={}[]|;':\"<>,?/`";
    //filter for domain
    NSString *unWantedInDomain = @" ~!@#$%^&*()={}[]|;':\"<>,+?/`";
    //filter for subdomain
    NSString *unWantedInSub = @" `~!@#$%^&*()={}[]:\";'<>,?/1234567890";
	
    //subdomain should not be less that 2 and not greater 6
    if(!(subDomain.length>=2 && subDomain.length<=6)) return NO;
	
    if([accountName isEqualToString:@""] || [accountName rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:unWantedInUName]].location!=NSNotFound || [domainName isEqualToString:@""] || [domainName rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:unWantedInDomain]].location!=NSNotFound || [subDomain isEqualToString:@""] || [subDomain rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:unWantedInSub]].location!=NSNotFound)
    {
        return NO;
    }
    return YES;
}

- (IBAction)submit:(id)sender 
{
    if (self.ibEmailField.text.length == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Error"
                              message:@"please enter your email!"
                              delegate:nil 
                              cancelButtonTitle:@"Close" 
                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    } 
    else if (self.ibPasswordField.text.length == 0 || self.ibRepeatPasswordField.text.length == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Error"
                              message:@"Please enter your password" 
                              delegate:nil 
                              cancelButtonTitle:@"Close" 
                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
    else if (self.ibPasswordField.text.length < 6)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:@"Your password must be a minimum of 6 characters."
                              delegate:nil
                              cancelButtonTitle:@"Close"
                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
    else if (![self.ibPasswordField.text isEqualToString:self.ibRepeatPasswordField.text])
    {
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Error"
                              message:@"Your passwords must match" 
                              delegate:nil 
                              cancelButtonTitle:@"Close" 
                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    } 
    else if(![self emailValidate:self.ibEmailField.text])
    {
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Error"
                              message:@"Please enter a valid email address"
                              delegate:nil 
                              cancelButtonTitle:@"Close"
                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    } 
    else 
    {
        [self.ibEmailField resignFirstResponder];
        [self.ibPasswordField resignFirstResponder];
        [self.ibRepeatPasswordField resignFirstResponder];
        
        [WaitingView popWaiting];
		
        [_userModel regist:self.ibEmailField.text password:self.ibPasswordField.text passwordConfirmation:self.ibRepeatPasswordField.text];
        
    }
}

- (IBAction)alreadyAMemeber:(id)sender 
{
    [self.ibEmailField resignFirstResponder];
    [self.ibPasswordField resignFirstResponder];
    [self.ibRepeatPasswordField resignFirstResponder];
    
    if ([AppDelegate getAppDelegate].resignIn) {
        [self.navigationController popViewControllerAnimated:YES];
    }else {
        [[AppDelegate getAppDelegate] switchToSignIn];
    }
}

- (IBAction)privacyPolicy:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PRIVACY_URL]];
}

- (IBAction)prevNextButtonClick:(id)sender
{
    UITextField* textFields[] = 
    {
        _ibEmailField,
        _ibPasswordField,
        _ibRepeatPasswordField
    };
    
    for( int i=0; i<sizeof(textFields)/sizeof(UITextField*); i++ ) 
    {
        if( textFields[i].tag == editingTextTag )
        {
            if (((UISegmentedControl*)sender).selectedSegmentIndex == 0)
            {
                if( i-1 >= 0)
                {
                    [textFields[i-1] becomeFirstResponder];
                }
                break;
            } 
            else
            {
                if( i+1 < sizeof(textFields)/sizeof(UITextField*))
                {
                    [textFields[i+1] becomeFirstResponder];
                }
                break;
            }
        }
    }    
}

- (IBAction)backgroundTouched:(id)sender 
{
    UITextField* textFields[] = 
    {
      _ibEmailField,
      _ibPasswordField,
      _ibRepeatPasswordField
    };
    
    for (int i=0; i<sizeof(textFields)/sizeof(UITextField*); i++) 
    {
        if (textFields[i].tag == editingTextTag) 
        {
            [textFields[i] resignFirstResponder];
            break;
        }
    }
}

- (IBAction)doneButtonClick:(id)sender
{
    UITextField* textFields[] = 
    {
      _ibEmailField,
      _ibPasswordField,
      _ibRepeatPasswordField
    };
    
    for (int i=0; i<sizeof(textFields)/sizeof(UITextField*); i++) 
    {
        if (textFields[i].tag == editingTextTag) 
        {
            [textFields[i] resignFirstResponder];
            break;
        }
    }
}

#pragma mark
#pragma mark 初始化或销毁事件

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning 
{
   
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)dealloc
{
    _userModel = REMOVEOBSERVER(UserModel, self);
	
    [_ibRegisterView release];
    [_ibTouchableView release];
    [_ibLogoView release];
    [_ibWelcomeLbl release];
    [_ibIntroLbl release];
    [_ibFBLoginView release];
    [_ibBottomView release];
    [_ibEmailField release];
    [_ibPasswordField release];
    [_ibRepeatPasswordField release];
    [_ibToolBar release];
    [_ibPrevNextButton release];
    
    [super dealloc];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
  
    // initialize bc protocol
    _userModel = ADDOBSERVER(UserModel, self);
    
    self.navigationController.navigationBarHidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
  
    if (SCREEN_HEIGHT <= 480) {
      CGRectSet(_ibBottomView, -1, SCREEN_HEIGHT_WITHOUT_STATUS_BAR-_ibBottomView.frame.size.height, -1, -1);
      CGRectSet(_ibRegisterView, -1, CGRectTop(_ibBottomView.frame)-10-_ibRegisterView.frame.size.height, -1, -1);
      CGRectSet(_ibFBLoginView, -1, CGRectTop(_ibRegisterView.frame)-10-_ibFBLoginView.frame.size.height, -1, -1);
      CGRectSet(_ibIntroLbl, -1, CGRectTop(_ibFBLoginView.frame)-5-_ibIntroLbl.frame.size.height, -1, -1);
      CGRectSet(_ibWelcomeLbl, -1, CGRectTop(_ibIntroLbl.frame)-_ibWelcomeLbl.frame.size.height, -1, -1);
      CGRectSet(_ibLogoView, -1, CGRectTop(_ibWelcomeLbl.frame)-_ibLogoView.frame.size.height, -1, -1);
    }
  
    self.ibFBLoginView.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    _userModel = REMOVEOBSERVER(UserModel, self);
	
    self.ibRegisterView = nil;
    self.ibEmailField = nil;
    self.ibPasswordField = nil;
    self.ibRepeatPasswordField = nil;
    self.ibToolBar = nil;
    self.ibPrevNextButton = nil;
    self.ibBottomView = nil;
    self.ibLogoView = nil;
    self.ibFBLoginView = nil;
    self.ibWelcomeLbl = nil;
    self.ibIntroLbl = nil;
    self.ibTouchableView = nil;
}

-(void) viewDidAppear:(BOOL)animated
{
    [Flurry logEvent:@"sign on view"];
    [Flurry logPageView];
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)userModel:(UserModel*)userModel registed:(ReturnParam*)param
{
    
    if( param.success )
    {
        [_userModel signIn:self.ibEmailField.text password:self.ibPasswordField.text];
    }
    else
    {
        [WaitingView dismissWaiting];
        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Error"
							  message:[param failedReason]
							  delegate:nil
							  cancelButtonTitle:@"Close"
							  otherButtonTitles:nil,nil];
      [alert show];
      [alert release];
    }
}


-(void) userModel:(UserModel*)userModel signIn:(ReturnParam*)param
{
    [WaitingView dismissWaiting];
    if( param.success )
    {
        [WaitingView dismissWaiting];
        if( !param.success )
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:param.failedReason
                                  delegate:nil
                                  cancelButtonTitle:@"Close"
                                  otherButtonTitles:nil,nil];
            [alert show];
            [alert release];
            return;
        }
        
        
        [[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"SaveUser"];
        [Keychain saveString:self.ibEmailField.text forKey:@"UserEmail"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserEmail"];
        [Keychain saveString:self.ibPasswordField.text forKey:@"UserPassword"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserPassword"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)userModel:(UserModel*)userModel signInWithFacebookLogin:(ReturnParam*)param
{
    [WaitingView dismissWaiting];
  
    if( !param.success )
    {
      [self.view makeToast:@"bugle server failed with facebook login"];
      
      UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Error"
                          message:param.failedReason
                          delegate:nil
                          cancelButtonTitle:@"Close"
                          otherButtonTitles:nil,nil];
      [alert show];
      [alert release];
      return;
    }
	[AppDelegate getAppDelegate].isLoginFromFB = YES;
    [self.view makeToast:@"suceess get refresh token and access token back with facebook login"];
}

// This method will be called when the user information has been fetched
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
  
  NSLog(@"user profile %@", user);
  NSLog(@"user profile id %@", user.objectID);
  NSLog(@"Access Token %@", [[FBSession.activeSession accessTokenData] accessToken]);

  [Keychain saveString:user.objectID forKey:@"FBProfileID"];
  [Keychain saveString:[[FBSession.activeSession accessTokenData] accessToken] forKey:@"FBAccessToken"];

  [self.view makeToast:[NSString stringWithFormat:@"get back from Facebook, userID: %@, access token:%@", user.objectID, [[FBSession.activeSession accessTokenData] accessToken] ] duration:5.0f position:nil];

  [_userModel signInWithFacebookLogin:user.objectID accessToken:[[FBSession.activeSession accessTokenData] accessToken]];
}

@end
