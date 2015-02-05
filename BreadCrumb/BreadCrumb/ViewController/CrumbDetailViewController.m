//
//  CrumbDetailViewController.m
//  BreadCrumb
//
//  Created by dongwen on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CrumbDetailViewController.h"
#import "BreadcrumbContactViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WaitingView.h"
#import "Flurry.h"
#import "GlobalModel.h"
#import "AppDelegate.h"

@interface CrumbDetailViewController () <CrumbViewDelegate, UserModelObserver, CrumbModelObserver>
{
    CrumbModel* _crumbModel;
	ContactModel* _contactModel;
}
@end

@implementation CrumbDetailViewController

#pragma mark
#pragma mark change control's status & text with style

-(void) resetEditingCrumb
{
	if( _editingCrumb == nil )
	{
		_editingCrumb = [[Crumb alloc] init];
	}
	_editingCrumb.crumbId = SafeCopy(_originCrumb.crumbId);
	_editingCrumb.status = SafeCopy(_originCrumb.status);
	_editingCrumb.name = SafeCopy(_originCrumb.name);
	_editingCrumb.alertMessage = SafeCopy(_originCrumb.alertMessage);
	_editingCrumb.contacts = _originCrumb.contacts;
	_editingCrumb.deadline = _originCrumb.deadline;
}

-(void) updateContent
{
	switch( _style )
	{
		case CrumbDetailStyleCreateNew:
		{
            self.title = @"New Activity";
            self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClick:)] autorelease];
            self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Activate" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick:)] autorelease];

			break;
		}
		case CrumbDetailStyleCheckIn:
		{
            self.title = @"Activity Details";
            self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClick:)] autorelease];
            self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick:)] autorelease];
			break;
		}
		case CrumbDetailStyleEdit:
		{
            self.title = @"Edit Activity";
            self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClick:)] autorelease];
            self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Activate" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick:)] autorelease];

			break;
		}
		case CrumbDetailStyleShow:
		{
            self.title = @"Activity Details";
            self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClick:)] autorelease];
            self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Re-Use" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick:)] autorelease];
			break;
		}
		case CrumbDetailStyleReuse:
		{
            self.title = @"Re-Use Activity";
            self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClick:)] autorelease];
            self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Activate" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick:)] autorelease];
            
			break;
		}
	}
	
	NSMutableArray* crumbContacts = [[NSMutableArray alloc] init];
	for( Contact* contact in _contactModel.contacts )
	{
		for( NSString* contactId in _editingCrumb.contacts )
		{
			if( [contactId isEqualToString:contact.contactId] )
			{
				[crumbContacts addObject:[NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName]];
				break;
			}
		}
	}
	
	[_crumbView changeStyle:_style andCrumb:_editingCrumb andCrumbContact:crumbContacts];
	
	[crumbContacts release];
}

#pragma mark
#pragma mark button click event

-(void) dismiss
{
	if( _style == CrumbDetailStyleCreateNew )
	{
        [self dismissViewControllerAnimated:YES completion:nil];
	}
	else
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
}

-(void) leftButtonClick:(id)sender
{
	if( _lastStyle == CrumbDetailStyleNone )
	{
		[self dismiss];
	}
	else
	{
		_style = _lastStyle;
		_lastStyle = CrumbDetailStyleNone;
		[self resetEditingCrumb];
		[self updateContent];
	}
}

-(void) rightButtonClick:(id)sender
{
	if( _style == CrumbDetailStyleShow )
	{
	   _lastStyle = _style;
	   _style = CrumbDetailStyleReuse;
	   [self updateContent];
		return;
	}
	if( _style == CrumbDetailStyleCheckIn )
	{
	   _lastStyle = _style;
	   _style = CrumbDetailStyleEdit;
	   [self updateContent];
	   return;
	}
	
	_editingCrumb.name = _crumbView.crumbTitle.text;
	_editingCrumb.alertMessage = _crumbView.details.text;
	_editingCrumb.deadline = _crumbView.checkInDatetime.text;
	
	if( _editingCrumb.name.length == 0 )
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Please enter a title for your activity."
													 message:nil
													delegate:nil 
										   cancelButtonTitle:@"Close"
										   otherButtonTitles:nil];
		[av show];
		[av release];
		return;
	}
	else if( _editingCrumb.alertMessage.length <= 0 )
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Please enter a description for your activity."
													 message:nil
													delegate:nil 
										   cancelButtonTitle:@"Close"
										   otherButtonTitles:nil];
		[av show];
		[av release];
		return;
	}
	else if( _editingCrumb.contacts.count == 0 )
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Please choose at least one contact."
													 message:nil
													delegate:nil 
										   cancelButtonTitle:@"Close"
										   otherButtonTitles:nil];
		[av show];
		[av release];
		return;
	}
	else if( (_editingCrumb.deadline.length == 0)||
			([StringToDate(_editingCrumb.deadline) timeIntervalSinceDate:[NSDate date]] < 0) )
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Please enter check-in time."
													 message:nil
													delegate:nil 
										   cancelButtonTitle:@"Close"
										   otherButtonTitles:nil];
		[av show];
		[av release];
		return;
	}

	
	switch( _style )
	{
		case CrumbDetailStyleCreateNew:
		{
			[Flurry logEvent:@"create crumb"];
			[WaitingView popWaiting];
			[_crumbModel addCrumb:_editingCrumb];
			break;
		}
		case CrumbDetailStyleEdit:
		{
			[Flurry logEvent:@"edit crumb"];
			[WaitingView popWaiting];
			[_crumbModel editCrumb:_editingCrumb];
			break;
		}
		case CrumbDetailStyleReuse:
		{
			[Flurry logEvent:@"reuse crumb"];
			[WaitingView popWaiting];
			[_crumbModel reuseCrumb:_editingCrumb];
			break;
		}
	}
}

#pragma mark
#pragma mark CrumbViewDelegate

-(void) cancelButtonClick
{
	[WaitingView popWaiting];
	[_crumbModel cancelCrumb:_editingCrumb];
}

-(void) checkInButtonClick
{
	[WaitingView popWaiting];
	[_crumbModel checkInCrumb:_editingCrumb];
}

-(void) showContactPicker
{
    BreadcrumbContactViewController* BreadcrumbContact = [[BreadcrumbContactViewController alloc] initWithNibName:@"BreadcrumbContactViewController" bundle:nil];
	[BreadcrumbContact addSelectedContacts:_editingCrumb.contacts];
    BreadcrumbContact.target = self;
	BreadcrumbContact.callback = @selector(selectContact:);
	[self.navigationController pushViewController:BreadcrumbContact animated:YES];
	[BreadcrumbContact release];
}

-(void) selectContact:(NSMutableArray*)contactIDArray 
{
	_editingCrumb.name = _crumbView.crumbTitle.text;
	_editingCrumb.alertMessage = _crumbView.details.text;
	_editingCrumb.deadline = _crumbView.checkInDatetime.text;
	
	[_editingCrumb.contacts removeAllObjects];
    for( NSString* contactID in contactIDArray )
    {
		[_editingCrumb.contacts addObject:contactID];
    }
	[self updateContent];
}

#pragma mark
#pragma mark CrumbModelObserver

-(void) crumbModel:(CrumbModel*)crumbModel editCrumbs:(ReturnParam*)param
{
	[WaitingView dismissWaiting];
	
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
	
	Crumb* crumb = [param.userInfo objectForKey:@"crumb"];
	
	if( (_editingCrumb.crumbId.length != 0) &&
	   (![_editingCrumb.crumbId isEqualToString:crumb.crumbId]) ) return;
	
	_editingCrumb.crumbId = crumb.crumbId;
	
	if( [crumb isCheckedOrCanceled] )
	{
		if( _style == CrumbDetailStyleCheckIn )
		{
			[self dismiss];
		}
		return;
	}
	
	if( GETMODEL(UserModel).user.sendItinerary )
	{
		[self retain];
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Share your itinerary now?"
													 message:@"Would you like your activity details to be emailed now to the emergency contacts you have listed?"
													delegate:self
										   cancelButtonTitle:@"Don’t Send"
										   otherButtonTitles:@"Send Itinerary", nil];
		[av show];
		[av release];
	}
	
	[self dismiss];
}

-(void) crumbModel:(CrumbModel*)crumbModel sendItinerary:(ReturnParam*)param
{
	[self release];
	[WaitingView dismissWaiting];
	
	if( !param.success )
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Error"
													 message:param.failedReason
													delegate:nil
										   cancelButtonTitle:@"Close"
										   otherButtonTitles:nil];
		[av show];
		[av release];
	}
	else
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Itinerary sent"
													 message:@"Your itinerary has been emailed to the emergency contacts you have listed for this activity."
													delegate:nil
										   cancelButtonTitle:@"Ok"
										   otherButtonTitles:nil];
		[av show];
		[av release];
	}
}

#pragma mark
#pragma mark UIAlertViewDelegate

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( buttonIndex == 0 )
	{
		[self release];
	}
	else
	{
		[WaitingView popWaiting];
		[_crumbModel sendItinerary:_editingCrumb];
	}
}

#pragma mark
#pragma mark init & uninit functions

-(id) initWithStyle:(NSInteger)style andCrumb:(Crumb*)crumb
{
	self = [self initWithNibName:@"CrumbDetailViewController" bundle:nil];
	if( self != nil )
	{
		_style = style;
		if( crumb != nil ) _originCrumb = [crumb retain];
        self.navigationItem.rightBarButtonItem.enabled = NO;
		[self resetEditingCrumb];
	}
	return self;
}

-(void) dealloc
{
	[_originCrumb release];
	[_editingCrumb release];
	
	_crumbModel = REMOVEOBSERVER(CrumbModel, self);
	_contactModel = REMOVEOBSERVER(ContactModel, self);
	
	[_crumbView removeFromSuperview];
	
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	if( [_editingCrumb.status isEqualToString:@"alerted"] )
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Overdue"
													 message:@"You are overdue from this activity. Check in now if you are safe."
													delegate:nil
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil];
		[av show];
		[av release];
		[self.navigationItem.rightBarButtonItem setEnabled:NO];
	}
	
    _crumbView = (CrumbView*)[[[NSBundle mainBundle] loadNibNamed:@"CrumbView" owner:self options:nil] lastObject];
	_crumbView.delegate = self;
	[self.view addSubview:_crumbView];
    
    _crumbView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	_crumbModel = ADDOBSERVER(CrumbModel, self);
	_contactModel = ADDOBSERVER(ContactModel, self);

	[self updateContent];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.navigationItem.hidesBackButton = YES;

	[Flurry logEvent:@"crumb detail view"];
    [Flurry logPageView];
}


@end
