//
//  CrumbListViewController.m
//  BreadCrumb
//
//  Created by dongwen on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CrumbListViewController.h"
#import "CrumbListItem.h"
#import "CrumbDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "BreadCrumbData.h"
#import "AppDelegate.h"
#import "WaitingView.h"
#import "Flurry.h"
#import "GlobalModel.h"

@interface CrumbListViewController () <UserModelObserver, CrumbModelObserver, CrumbListItemDelegate>
{
	CrumbModel* _crumbModel;
    UserModel* _userModel;
    
    BOOL _isDeleteBtnShow;
}

@property (strong, nonatomic) CrumbListItem* cell;


@end

@implementation CrumbListViewController

@synthesize tableView;

#pragma mark
#pragma mark button click event

-(void) checkInButtonClick:(id)sender
{
	Crumb* crumb = nil;
	for( NSInteger row =0; row < arrayOfActive.count; row++ )
	{
		NSIndexPath* index = [NSIndexPath indexPathForRow:row inSection:0];
		CrumbListItem* crumbCell = (CrumbListItem*)[tableView cellForRowAtIndexPath:index];
		if( sender == crumbCell.button )
		{
			crumb = [arrayOfActive objectAtIndex:row];
			break;
		}
	}
	if( crumb == nil ) return;
	
	_selfRequest = YES;
	[WaitingView popWaiting];
	[_crumbModel checkInCrumb:crumb];
}

-(void) reUseButtonClick:(id)sender
{
	Crumb* crumb = nil;
	for( NSInteger row =0; row < arrayOfRecent.count; row++ )
	{
		NSIndexPath* index = [NSIndexPath indexPathForRow:row inSection:1];
		CrumbListItem* crumbCell = (CrumbListItem*)[tableView cellForRowAtIndexPath:index];
		if( sender == crumbCell.button )
		{
			crumb = [arrayOfRecent objectAtIndex:row];
			break;
		}
	}
	if( crumb == nil ) return;
	
	CrumbDetailViewController* newCrumb = [[CrumbDetailViewController alloc] initWithStyle:CrumbDetailStyleReuse andCrumb:crumb];
    [[AppDelegate getAppDelegate].mainTabBarController.navigationController pushViewController:newCrumb animated:YES];
	[newCrumb release];
}

#pragma mark
#pragma mark UITableViewDelegate UITableViewDataSource

-(BOOL) tableView:(UITableView*)l_tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
	return NO;
}


-(void) tableView:(UITableView*)l_tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if( editingStyle == UITableViewCellEditingStyleDelete )
	{
		[WaitingView popWaiting];
		_selfRequest = YES;
		Crumb* crumb = nil;
		if( indexPath.section == 0 )
		{
			crumb = [arrayOfActive objectAtIndex:indexPath.row];
		}
		else if( indexPath.section == 1 )
		{
			crumb = [arrayOfRecent objectAtIndex:indexPath.row];
		}
		else
		{
			[WaitingView dismissWaiting];
			_selfRequest = NO;
			return;
		}
		[_crumbModel deleteCrumb:crumb];
//		[_crumbModel.crumbs removeObject:crumb];
//		[l_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
	}
}

-(NSInteger) numberOfSectionsInTableView:(UITableView*)l_tableView
{
    return 2;
}

-(NSString*) tableView:(UITableView*)l_tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* titleSections[] = {@"Pending Activities",
        @"Recent Activities"};
    
    if( section > sizeof(titleSections)/sizeof(NSString*) ) return @"";
    else return titleSections[section];
}

-(NSInteger) tableView:(UITableView*)l_tableView numberOfRowsInSection:(NSInteger)section
{
	NSMutableArray* arrayOfActiveButExpired = [NSMutableArray array];
	if( section == 0 )
	{
		if( arrayOfActive == nil )
		{
			arrayOfActive = [[NSMutableArray alloc] init];
		}
		[arrayOfActive removeAllObjects];
	}
	else if( section == 1 )
	{
		if(  arrayOfRecent == nil )
		{
			arrayOfRecent = [[NSMutableArray alloc] init];
		}
		[arrayOfRecent removeAllObjects];
	}
	else return 0;
	
	for( Crumb* crumb in _crumbModel.crumbs )
	{
		if( (section == 0) &&
		   (([crumb.status isEqualToString:@"warning"]) || 
			([crumb.status isEqualToString:@"alerted"]) ||
			([crumb.status isEqualToString:@"pending"])) )
		{
			NSDate* crumbDeadTime = StringToDate(crumb.deadline);
			if( [[NSDate date] timeIntervalSinceDate:crumbDeadTime] > 0 )
			{
				NSInteger position = 0;
				for( Crumb* c in arrayOfActiveButExpired )
				{
					NSDate* cDeadTime = StringToDate(c.deadline);
					if( [crumbDeadTime earlierDate:cDeadTime] == cDeadTime ) break;
					position++;
				}
				[arrayOfActiveButExpired insertObject:crumb atIndex:position];
			}
			else
			{
				NSInteger position = 0;
				for( Crumb* c in arrayOfActive )
				{
					NSDate* cDeadTime = StringToDate(c.deadline);
					if( [crumbDeadTime earlierDate:cDeadTime] == crumbDeadTime ) break;
					position++;
				}
				[arrayOfActive insertObject:crumb atIndex:position];
			}
		}
		else if( (section == 1) &&
		   (([crumb.status isEqualToString:@"checked_in"]) || 
			([crumb.status isEqualToString:@"cancelled"])) )
		{
			NSDate* checkedDate = LastCheckedInStringToDate(crumb.lastCheckedTime);
			NSInteger position = 0;
			for( Crumb* c in arrayOfRecent )
			{
				NSDate* cDate = LastCheckedInStringToDate(c.lastCheckedTime);
				if( [checkedDate earlierDate:cDate] == cDate ) break;
				position++;
			}
			[arrayOfRecent insertObject:crumb atIndex:position];
		}
	}
	
	if( section == 0 )
	{
		for( NSInteger i=arrayOfActiveButExpired.count-1; i>=0; i-- )
		{
			[arrayOfActive insertObject:[arrayOfActiveButExpired objectAtIndex:i] atIndex:0];
		}
		[arrayOfActiveButExpired removeAllObjects];
		return arrayOfActive.count;
	}
	else if( section == 1 )
	{
		return arrayOfRecent.count;
	}
	else return 0;
}

-(UITableViewCell*) tableView:(UITableView*)l_tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CrumbListItem *cell = [l_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if( cell != nil ) return cell;
    
    cell = [[[NSBundle mainBundle] loadNibNamed:@"CrumbListItem" owner:self options:nil] lastObject];
    
    if( indexPath.section == 0 )
    {
		[cell.button addTarget:self action:@selector(checkInButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
		[cell.button addTarget:self action:@selector(reUseButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
	Crumb* crumb = nil;
	if( indexPath.section == 0 )
	{
		crumb = [arrayOfActive objectAtIndex:indexPath.row];
	}
	else if( indexPath.section == 1 )
	{
		crumb = [arrayOfRecent objectAtIndex:indexPath.row];
	}
    cell.delegate = self;
	cell.crumb = crumb;
    
	return cell;
}

-(void) tableView:(UITableView*)l_tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [l_tableView deselectRowAtIndexPath:indexPath animated:NO];
	CrumbListItem* cell = (CrumbListItem*)[l_tableView cellForRowAtIndexPath:indexPath];
	if( indexPath.section == 0 )
	{
		CrumbDetailViewController* newCrumb = [[CrumbDetailViewController alloc] initWithStyle:CrumbDetailStyleCheckIn andCrumb:cell.crumb];
		[[AppDelegate getAppDelegate].mainTabBarController.navigationController pushViewController:newCrumb animated:YES];
		[newCrumb release];
	}
	else if( indexPath.section == 1 )
	{
		CrumbDetailViewController* newCrumb = [[CrumbDetailViewController alloc] initWithStyle:CrumbDetailStyleShow andCrumb:cell.crumb];
		[[AppDelegate getAppDelegate].mainTabBarController.navigationController pushViewController:newCrumb animated:YES];
		[newCrumb release];
	}
}

-(void) scrollViewDidScroll:(UIScrollView*)scrollView
{
	if( _refreshHeaderView )
	{
		[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
	}
}

-(void) scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
	if( _refreshHeaderView )
	{
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	}
}

#pragma mark
#pragma mark EGORefreshTableHeaderDelegate

-(void) egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	_reloading = YES;
	[WaitingView popWaiting];
	[_crumbModel downloadCrumbs];
}

-(BOOL) egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return _reloading;
}
-(NSDate*) egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [NSDate date];
}

#pragma mark
#pragma mark CrumbModelObserver

-(void) crumbModel:(CrumbModel*)crumbModel downloadCrumbs:(ReturnParam*)param
{
    [WaitingView dismissWaiting];
	
	_reloading = NO;
    if (tableView) {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:tableView];
    
        
        if( !param.success )
        {
            UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:param.failedReason
                                                        delegate:nil
                                               cancelButtonTitle:@"Close"
                                               otherButtonTitles:nil];
            [av show];
            [av release];
            return;
        }
        
        [tableView reloadData];
        tableView.separatorColor = (_crumbModel.crumbs.count > 0)? _separatorColor : [UIColor clearColor];
        _emptyView.hidden = (_crumbModel.crumbs.count > 0);
    }
}

-(void) crumbModel:(CrumbModel*)crumbModel editCrumbs:(ReturnParam*)param
{
	if( _selfRequest )
	{
		_selfRequest = NO;
		[WaitingView dismissWaiting];
	}
	
	Crumb* crumb = [param.userInfo objectForKey:@"crumb"];
	NSInteger position = [_crumbModel.crumbs indexOfObject:crumb];
	if( crumb != nil )
	{
		if( (position >= 0) && (position < _crumbModel.crumbs.count) )
		{
			[crumb retain];
			[_crumbModel.crumbs removeObject:crumb];
			[_crumbModel.crumbs insertObject:crumb atIndex:0];
			[crumb release];
		}
	}
	
	if( param.success )
	{
		[tableView reloadData];
		tableView.separatorColor = (_crumbModel.crumbs.count > 0)? _separatorColor : [UIColor clearColor];
		_emptyView.hidden = (_crumbModel.crumbs.count > 0);
	}
//	[self.tableView setContentOffset:CGPointZero animated:YES];
}

#pragma mark
#pragma mark 初始化和销毁函数

-(void) dealloc
{
	if( arrayOfActive != nil )
	{
		[arrayOfActive release];
		arrayOfActive = nil;
	}
	else if( arrayOfRecent != nil )
	{
		[arrayOfRecent release];
		arrayOfRecent = nil;
	}
	
	_crumbModel = REMOVEOBSERVER(CrumbModel, self);
    _userModel = REMOVEOBSERVER(UserModel, self);
	[_separatorColor release];
	
	[super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Activities";
        self.tabBarItem.image = [UIImage imageNamed:@"Button_TabBarIcon_Home.png"];
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
	EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 
																								  0.0f - self.tableView.bounds.size.height,
																								  self.tableView.frame.size.width,
																								  self.tableView.frame.size.height)];
	view.delegate = self;
	_separatorColor = [self.tableView.separatorColor retain];
	[self.tableView addSubview:view];
	_refreshHeaderView = view;
	[view release];
	
	_reloading = NO;
	_isDeleteBtnShow = NO;
    
	[_refreshHeaderView refreshLastUpdatedDate];
    
    _crumbModel = ADDOBSERVER(CrumbModel, self);
    _userModel = ADDOBSERVER(UserModel, self);
    

}

-(void) viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];

    [AppDelegate getAppDelegate].mainTabBarController.navigationController.navigationBarHidden = NO;
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BreadCrumbLogoFile_no_tagline.png"]];
    
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.leftBarButtonItem = nil;
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.rightBarButtonItem = nil;

    
	[tableView reloadData];
	tableView.separatorColor = (_crumbModel.crumbs.count > 0)? _separatorColor : [UIColor clearColor];
	_emptyView.hidden = (_crumbModel.crumbs.count > 0);
	
	[Flurry logEvent:@"crumb list view"];
    [Flurry logPageView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void)deleteButtonClickWithCrumb:(Crumb *)crumb {
    if (!crumb) {
        return;
    }
    
    [WaitingView popWaiting];
    _selfRequest = YES;
    [_crumbModel deleteCrumb:crumb];
}

@end
