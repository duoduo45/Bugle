//
//  SignInViewController.m
//  BreadCrumb
//
//  Created by Hui Jiang on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "RegistViewController.h"
#import "SignInViewController.h"
#import "AppDelegate.h"
#import "WaitingView.h"
#import "SBJSON.h"
#import "Flurry.h"
#import "Keychain.h"
#import "Toast+UIView.h"
#import "GlobalModel.h"

@interface SignInViewController () <UserModelObserver>
{
    UserModel       *_userModel;
}

@end

@implementation SignInViewController

#pragma mark
#pragma mark Keyboard Event

- (void)textFieldDidEndEditing:(id)sender 
{
    CGRect newFrame = self.ibControlView.frame;
    newFrame.origin.y += 120;
    self.ibControlView.frame = newFrame;
}

- (void)textFieldDidBeginEditing:(id)sender 
{
    [_ibPrevNextButton setEnabled:(sender!=_ibEmailField) forSegmentAtIndex:0];
    [_ibPrevNextButton setEnabled:(sender!=_ibPasswordField) forSegmentAtIndex:1];
    
    CGRect newFrame = self.ibControlView.frame;
    newFrame.origin.y -= 120;
    self.ibControlView.frame = newFrame;
    
    editingTextTag = ((UITextField*)sender).tag;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string 
{
	
    if (range.length > string.length) return YES;
	
    NSInteger length = [textField.text substringToIndex:range.location].length + string.length + [textField.text substringFromIndex:range.location+range.length].length;
	
    if (textField == self.ibEmailField) return (length <= 50);
    else if (textField == self.ibPasswordField) return (length <= 25);
	
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField 
{
    UITextField* textFields[] = 
    {
        _ibEmailField,
        _ibPasswordField,
    };
    
    for (int i=0; i<sizeof(textFields)/sizeof(UITextField*); i++) 
    {
        if( textFields[i] != textField ) continue;
        
        [textFields[i] resignFirstResponder];
        if (i+1 < sizeof(textFields)/sizeof(UITextField*))
        {
            [textFields[i+1] becomeFirstResponder];
            editingTextTag = textFields[i+1].tag;
        }
        else
        {
            [self signIn:nil]; 
            ///TODO: trigger sign in event
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
        return NO;
    
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
        return NO;
    
    return YES;
}

- (IBAction)signIn:(id)sender 
{    
    if(![self emailValidate:self.ibEmailField.text])
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
    else
    {        
        [self.ibEmailField resignFirstResponder];
        [self.ibPasswordField resignFirstResponder];

        [WaitingView popWaiting];
        [_userModel signIn:self.ibEmailField.text password:self.ibPasswordField.text];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    
    if (buttonIndex != [alertView cancelButtonIndex] )
    {
          NSString *myNewLineStr = @"\n";
          NSString *string = [NSString stringWithFormat:@"A verification email has been sent to %@", self.ibEmailField.text];
          NSString *myStr = [string stringByReplacingOccurrencesOfString:@"\\n" withString:myNewLineStr];
          
          UIAlertView *alert = [[UIAlertView alloc] 
                                initWithTitle:@"Email sent"
                                message:myStr 
                                delegate:nil 
                                cancelButtonTitle:@"Close" 
                                otherButtonTitles:nil,nil];
          [alert show];
          [alert release];
    }
}

- (IBAction)forgotYourPassword:(id)sender 
{
    if(![self emailValidate:self.ibEmailField.text])
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
        [WaitingView popWaiting];
        [_userModel forgetPassword:self.ibEmailField.text];

    }
}

- (IBAction)createNewAccount:(id)sender
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"SaveUser"] isEqualToString:@"YES"]) 
    { 
        [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"SaveUser"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserEmail"] : [Keychain deleteStringForKey:@"UserEmail"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPassword"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserPassword"] : [Keychain deleteStringForKey:@"UserPassword"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        RegistViewController *registViewController = [[[RegistViewController alloc] initWithNibName:@"RegistViewController" bundle:nil] autorelease];
        [self.navigationController pushViewController:registViewController animated:YES];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"SaveUser"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserEmail"] : [Keychain deleteStringForKey:@"UserEmail"];
        [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPassword"] != nil ? [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserPassword"] : [Keychain deleteStringForKey:@"UserPassword"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if ([AppDelegate getAppDelegate].resignIn == YES)
        {
            RegistViewController *registViewController = [[[RegistViewController alloc] initWithNibName:@"RegistViewController" bundle:nil] autorelease];
            [self.navigationController pushViewController:registViewController animated:YES];
        }
        else 
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


- (IBAction)prevNextButtonClick:(id)sender
{
    UITextField* textFields[] = 
    {
        _ibEmailField,
        _ibPasswordField,
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
	
    [_ibSigninView release];
    [_ibEmailField release];
    [_ibPasswordField release];
    [_ibTouchableView release];
    [_ibBottomView release];
    [_ibToolBar release];
    [_ibFBLoginView release];
    [_ibPrevNextButton release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    // Do any additional setup after loading the view from its nib.

    self.navigationController.navigationBarHidden = YES;

    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"SaveUser"] isEqualToString:@"YES"])
    {
        NSString *email = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"] : [Keychain getStringForKey:@"UserEmail"];
        NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPassword"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPassword"] : [Keychain getStringForKey:@"UserPassword"];
        
        self.ibEmailField.text = email;
        self.ibPasswordField.text = password;
    }
	
    _userModel = ADDOBSERVER(UserModel, self);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
  
    if (SCREEN_HEIGHT <= 480)
    {
      CGRectSet(_ibBottomView, -1, SCREEN_HEIGHT_WITHOUT_STATUS_BAR-_ibBottomView.frame.size.height, -1, -1);
      CGRectSet(_ibSigninView, -1, CGRectTop(_ibBottomView.frame)-10-_ibSigninView.frame.size.height, -1, -1);
      CGRectSet(_ibFBLoginView, -1, CGRectTop(_ibSigninView.frame)-10-_ibFBLoginView.frame.size.height, -1, -1);
    }
    self.ibFBLoginView.readPermissions = @[@"public_profile", @"email", @"user_friends"];
}

- (void)viewDidUnload
{
    _userModel = REMOVEOBSERVER(UserModel, self);
	
    self.ibSigninView = nil;
    self.ibEmailField = nil;
    self.ibPasswordField = nil;
    self.ibTouchableView = nil;
    self.ibBottomView = nil;
    self.ibFBLoginView = nil;
    self.ibToolBar = nil;
    self.ibPrevNextButton = nil;

}

-(void) viewDidAppear:(BOOL)animated
{
    [Flurry logEvent:@"sign in view"];
    [Flurry logPageView];
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)userModel:(UserModel*)userModel signIn:(ReturnParam*)param
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


- (void)userModel:(UserModel *)userModel forgetPassword:(ReturnParam *)param
{
    [WaitingView dismissWaiting];

    if (param.success)
    {
        NSString *myNewLineStr = @"\n";
        NSString *string = [NSString stringWithFormat:@"Forgot your password? Instructions have been sent to your email %@", self.ibEmailField.text];
        NSString *myStr = [string stringByReplacingOccurrencesOfString:@"\\n" withString:myNewLineStr];

        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Email sent"
                              message:myStr
                              delegate:nil
                              cancelButtonTitle:@"Close"
                              otherButtonTitles:nil,nil];
        [alert show];
        [alert release];
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
  
  NSLog(@"%@", user);
  NSLog(@"Access Token %@", [[FBSession.activeSession accessTokenData] accessToken]);
  
  [Keychain saveString:user.objectID forKey:@"FBProfileID"];
  [Keychain saveString:[[FBSession.activeSession accessTokenData] accessToken] forKey:@"FBAccessToken"];

  [_userModel signInWithFacebookLogin:user.objectID accessToken:[[FBSession.activeSession accessTokenData] accessToken]];
  
}

@end
