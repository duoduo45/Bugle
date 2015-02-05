//
//  AboutViewController.m
//  BreadCrumb
//
//  Created by dongwen on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "Flurry.h"
#import "AppDelegate.h"

@implementation AboutViewController

NSString* HelpImages[] = {
    @"HIW_01.png",
    @"HIW_02.png",
    @"HIW_03.png",
    @"HIW_04.png",
    @"HIW_05.png"
};

NSString* HelpImages_568h[] = {
    @"HIW_01-568h@2x.png",
    @"HIW_02-568h@2x.png",
    @"HIW_03-568h@2x.png",
    @"HIW_04-568h@2x.png",
    @"HIW_05-568h@2x.png"
};

#pragma mark
#pragma mark Button Event
- (IBAction)faq:(id)sender 
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gobugle.com/FAQ"]];
}

- (IBAction)moreInfo:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gobugle.com/MoreInfo"]];
}

- (void)goWebsite:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gobugle.com/"]];
}

#pragma mark
#pragma mark UIScrollViewDelegate

-(void) scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    self.ibPageControl.currentPage = self.ibScrollView.contentOffset.x / self.ibScrollView.frame.size.width;
}

-(void) pageTurn:(id)sender
{
    [self.ibScrollView scrollRectToVisible:CGRectMake(self.ibPageControl.currentPage * self.view.frame.size.width,
                                                0, 
                                                self.ibScrollView.frame.size.width,
                                                self.ibScrollView.frame.size.height)
                            animated:YES];
}

#pragma mark
#pragma mark 初始化和销毁函数

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.title = @"More";
        self.tabBarItem.image = [UIImage imageNamed:@"Button_TabBarIcon_More.png"];
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
    
    // Do any additional setup after loading the view from its nib.
    CGRectSet(_ibScrollView, 0, NAV_AND_STARUS_BAR_HEIGHT, -1, SCREEN_HEIGHT-NAV_AND_STARUS_BAR_HEIGHT-BOTTOM_TAB_HEIGHT);
    CGRectSet(self.ibPageControl, -1, iPhone5?(CGRectBottom(self.ibScrollView.frame)-44):(CGRectBottom(self.ibScrollView.frame)-88), -1, -1);
    
    CGSize contentSize = CGSizeMake(self.ibScrollView.frame.size.width, self.ibScrollView.frame.size.height);
    contentSize.width *= sizeof(HelpImages)/sizeof(NSString*);
    self.ibScrollView.contentSize = contentSize;
    
    for( int i=0; i<sizeof(HelpImages)/sizeof(NSString*); i++ )
    {
        UIImageView* imageView;
        if (iPhone5)
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:HelpImages_568h[i]]];
        else
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:HelpImages[i]]];

        imageView.frame = CGRectMake(i*self.ibScrollView.frame.size.width,
                                     0,
                                     self.ibScrollView.frame.size.width,
                                     self.ibScrollView.frame.size.height);;
        [self.ibScrollView addSubview:imageView];
        [imageView release];
        
        if (i == 4)
        {
            UIButton *websiteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            if (isiOS7UP) {
                websiteBtn.frame = CGRectMake(i*self.ibScrollView.frame.size.width+58, CGRectBottom(self.ibScrollView.frame)-(iPhone5?145:160), 200, 20);
            }else {
                websiteBtn.frame = CGRectMake(i*self.ibScrollView.frame.size.width+58, CGRectBottom(self.ibScrollView.frame)-185, 200, 20);
            }
            [websiteBtn addTarget:self action:@selector(goWebsite:) forControlEvents:UIControlEventTouchUpInside];
            websiteBtn.backgroundColor = [UIColor clearColor];
            [self.ibScrollView addSubview:websiteBtn];
        }
    } 
  

    [self.ibPageControl addTarget:self action:@selector(pageTurn:) forControlEvents:UIControlEventValueChanged];
    self.ibPageControl.numberOfPages = sizeof(HelpImages)/sizeof(NSString*);
    
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired=1;
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    CGPoint touchPoint= [sender locationInView:self.view];
    if (touchPoint.x > self.view.frame.size.width/2)
    {
        self.ibPageControl.currentPage += 1;
        [self pageTurn:nil];
    }
    else
    {
        self.ibPageControl.currentPage -= 1;
        [self pageTurn:nil];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
  
    self.ibScrollView = nil;
    self.ibPageControl = nil;
}

- (void)dealloc
{
    [_ibScrollView release];
    [_ibPageControl release];
  
    [super dealloc];
}

-(void) viewDidAppear:(BOOL)animated
{
    if ([AppDelegate getAppDelegate].isPresentModel) {
        CGRectSet(_ibScrollView, 0, 0, -1, SCREEN_HEIGHT-BOTTOM_TAB_HEIGHT);
        [AppDelegate getAppDelegate].isPresentModel = NO;
    }

    [super viewDidAppear:animated];

    [AppDelegate getAppDelegate].mainTabBarController.navigationController.navigationBarHidden = NO;
    [AppDelegate getAppDelegate].mainTabBarController.title = @"How It Works";
    
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"FAQ" style:UIBarButtonItemStylePlain target:self action:@selector(faq:)] autorelease];
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"More Info" style:UIBarButtonItemStylePlain target:self action:@selector(moreInfo:)] autorelease];
    
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.titleView = nil;

    
    [Flurry logEvent:@"about view"];
    [Flurry logAllPageViewsForTarget:self];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
