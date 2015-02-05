//
//  TermsofServiceViewController.m
//  BreadCrumb
//
//  Created by Hui Jiang on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TermsofServiceViewController.h"
#import "AppDelegate.h"
#import "Flurry.h"
#import "Keychain.h"

@implementation TermsofServiceViewController

#pragma mark
#pragma mark Button Action

- (IBAction)cancel:(id)sender 
{
    [[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"isShowTOS"];
    UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle:@"Error"
                          message:@"Please Accept Terms of Service!"
                          delegate:nil 
                          cancelButtonTitle:@"Close"
                          otherButtonTitles:nil,nil];
    [alert show];
    [alert release];
}

- (IBAction)accept:(id)sender 
{
    [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"isShowTOS"];
    

    NSString *firstName = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserFirstName"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserFirstName"] : [Keychain getStringForKey:@"UserFirstName"];
    NSString *lastName = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLastName"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLastName"] : [Keychain getStringForKey:@"UserLastName"];
    NSString *phone = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPhone"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPhone"] : [Keychain getStringForKey:@"UserPhone"];
    NSString *photoURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserProfilePic"] != nil ? [[NSUserDefaults standardUserDefaults] valueForKey:@"UserProfilePic"] : [Keychain getStringForKey:@"UserProfilePic"];
        
    if ([AppDelegate getAppDelegate].isLoginFromFB || (firstName.length > 0 && lastName.length > 0 && phone.length > 0 && photoURL.length > 0))
    {
        [[AppDelegate getAppDelegate] switchToMyAccount];
    }
    else
    {
        [[AppDelegate getAppDelegate] switchToWelcomeAccount];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    self.title = @"Terms Of Service";
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.navigationBarHidden = NO;

    CGRectSet(_ibAcceptBtn, -1, SCREEN_HEIGHT-20-_ibAcceptBtn.frame.size.height-(isiOS7UP?0:20), -1, -1);
    CGRectSet(_ibRejectBtn, -1, SCREEN_HEIGHT-20-_ibRejectBtn.frame.size.height-(isiOS7UP?0:20), -1, -1);
    CGRectSet(_ibWebView, -1, (isiOS7UP?69:49), -1, SCREEN_HEIGHT-_ibAcceptBtn.frame.size.height-40-NAV_AND_STARUS_BAR_HEIGHT);
  
    for (UIView *subView in self.view.subviews)
    {
        if ([subView isKindOfClass:[UIButton class]]) 
        {
            UIButton *btn = (UIButton*)subView;
            btn.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:143.0/255.0 blue:37.0/255.0 alpha:1.0];
            btn.layer.borderColor = [[UIColor colorWithRed:186.0/255.0 green:115.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor];
            btn.titleLabel.textColor = [UIColor whiteColor];
            btn.layer.borderWidth = 1.0f;
        }
    }
    
    [_ibWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"TOM" ofType:@"html"] isDirectory:NO]]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
  
    self.ibWebView = nil;
    self.ibAcceptBtn = nil;
    self.ibRejectBtn = nil;
}

- (void)dealloc
{
  
    [_ibWebView release];
    [_ibAcceptBtn release];
    [_ibRejectBtn release];
    [super dealloc];
}

-(void) viewDidAppear:(BOOL)animated
{
    [Flurry logEvent:@"terms of service view"];
    [Flurry logPageView];
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
