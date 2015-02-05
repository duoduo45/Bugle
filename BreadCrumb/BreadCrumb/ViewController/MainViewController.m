//
//  MainViewController.m
//  BreadCrumb
//
//  Created by 乔太太 on 13-2-19.
//
//

#import "MainViewController.h"
#import "CrumbListViewController.h"
#import "CrumbDetailViewController.h"
#import "ContactListViewController.h"
#import "ProfileViewController.h"
#import "AboutViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

-(void) newCrumbButtonClick:(id)sender
{
    UINavigationController* newCrumb = [[UINavigationController alloc] initWithRootViewController:[[CrumbDetailViewController alloc] initWithStyle:CrumbDetailStyleCreateNew andCrumb:nil]];
    [self presentViewController:newCrumb animated:YES completion:nil];
    [newCrumb release];
}

#pragma mark
#pragma mark init & dealloc

-(void) dealloc
{
    
    [super dealloc];
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}

-(id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    if (self = [super initWithNibName:nil bundle:nil])
    {
        
        CrumbListViewController* crumbList = [[CrumbListViewController alloc] initWithNibName:@"CrumbListViewController" bundle:nil];
        crumbList.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Activities" image:[UIImage imageNamed:@"Button_TabBarIcon_Home.png"] tag:0]autorelease];
        
        
        ContactListViewController* contactList = [[ContactListViewController alloc] initWithNibName:@"ContactListViewController" bundle:nil];
        contactList.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Contacts" image:[UIImage imageNamed:@"Button_TabBarIcon_Contacts.png"] tag:1]autorelease];
        
        UIViewController* placeHolder = [[UIViewController alloc] init];
        
        ProfileViewController* profile = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil];
        profile.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"My Account" image:[UIImage imageNamed:@"Button_TabBarIcon_MyAccount.png"] tag:3]autorelease];
        
        AboutViewController* about = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
        about.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"More" image:[UIImage imageNamed:@"Button_TabBarIcon_More.png"] tag:4]autorelease];
        
        self.viewControllers = [NSArray arrayWithObjects:crumbList,
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
            button.frame = CGRectMake(128, self.tabBar.frame.size.height - 49, 64, 49);
            [button setBackgroundImage:[UIImage imageNamed:@"Icon_Tab_Bar_New_Crumb_iOS7.png"] forState:UIControlStateNormal];
        }else {
            button.frame = CGRectMake(128, self.tabBar.frame.size.height - 64, 64, 64);
            [button setBackgroundImage:[UIImage imageNamed:@"addCrumbIcon.png"] forState:UIControlStateNormal];
        }
        [self.tabBar addSubview:button];
        
//        _activateCrumbHint = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"messageHint.png"]];
//        _activateCrumbHint.hidden = YES;
//        _activateCrumbHint.frame = CGRectMake(40, _mainTabBarController.tabBar.frame.size.height - 60, 28, 28);
//        [_mainTabBarController.tabBar addSubview:_activateCrumbHint];
//        [_activateCrumbHint release];
//        _activateCrumbCount = [[UILabel alloc] init];
//        CGRect newFrame = _activateCrumbHint.bounds;
//        newFrame.origin.x += 3;
//        newFrame.size.width -= 6;
//        newFrame.size.height -= 3;
//        _activateCrumbCount.frame = newFrame;
//        _activateCrumbCount.textColor = [UIColor whiteColor];
//        _activateCrumbCount.backgroundColor = [UIColor clearColor];
//        _activateCrumbCount.font = [UIFont boldSystemFontOfSize:14];
//        _activateCrumbCount.textAlignment = NSTextAlignmentCenter;
//        _activateCrumbCount.adjustsFontSizeToFitWidth = YES;
//        [_activateCrumbHint addSubview:_activateCrumbCount];
//        [_activateCrumbCount release];
    }
    
    return self;
}

@end
