//
//  BreadcrumbContactViewController.m
//  BreadCrumb
//
//  Created by Hui Jiang on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "BreadcrumbContactViewController.h"
#import "SelectContactViewController.h"
#import "NewContactViewController.h"
#import "ContactEditViewController.h"
#import "BreadCrumbData.h"
#import "AppDelegate.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "Flurry.h"

@interface BreadcrumbContactViewController () <ContactModelObserver>
{
    ContactModel            *_contactModel;
}
@end

@implementation BreadcrumbContactViewController

@synthesize contactTableView = _contactTableView;

@synthesize callback;
@synthesize target;

#pragma mark
#pragma mark Keyboard Event

- (IBAction)cancel:(id)sender 
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString*)phoneNumberConvert:(NSString*)unformatted
{
    NSArray *stringComponents = [NSArray arrayWithObjects:[unformatted substringWithRange:NSMakeRange(0, 3)],
                                 [unformatted substringWithRange:NSMakeRange(3, 3)],
                                 [unformatted substringWithRange:NSMakeRange(6, [unformatted length]-6)], nil];
    
    NSString *formattedString = [NSString stringWithFormat:@"(%@)%@-%@", [stringComponents objectAtIndex:0], [stringComponents objectAtIndex:1], [stringComponents objectAtIndex:2]];
    NSLog(@"Formatted Phone Number: %@", formattedString);
    
    return  formattedString;
}

- (IBAction)submit:(id)sender 
{
    if( (self.target != nil) &&
	   (self.callback != nil) &&
	   ([self.target respondsToSelector:self.callback]) )
	{
		[self.target performSelector:self.callback withObject:selectedArrayOfContacts];
	}
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)addMoreContacts:(id)sender 
{
    addContactTabBarController = [[UITabBarController alloc] init];
    
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
	// place the delegate of the picker to the controll
	picker.peoplePickerDelegate = self;
    picker.title = @"Select From Address Book";
    picker.tabBarItem.image = [UIImage imageNamed:@"Button_TabBarIcon_Add_Contacts_Address_Book.png"];

    UINavigationController *newContact= [[UINavigationController alloc] initWithRootViewController:[[[NewContactViewController alloc] init] autorelease]];
    newContact.title = @"Enter Manually";
    newContact.tabBarItem.image = [UIImage imageNamed:@"Button_TabBarIcon_Add_Contacts_Manual.png"];

    addContactTabBarController.viewControllers = [NSArray arrayWithObjects:picker, newContact, nil];
    
    [self presentViewController:addContactTabBarController animated:YES completion:nil];
    [AppDelegate getAppDelegate].isPresentModel = YES;
    [picker release];
    [newContact release];
}

- (void)selectButton:(id)sender 
{
    UIButton *selectBtn = (UIButton*)sender;
    
    if (selectBtn.tag == 0) 
    {
        if (selectBtn.selected == NO) 
        {
            isSelectAll = YES;
            for (int i = 0; i < [arrayOfContacts count]; i++) 
            {
                ((Contact*)[arrayOfContacts objectAtIndex:i]).isSelected = YES;
                [selectedArrayOfContacts addObject:((Contact*)[arrayOfContacts objectAtIndex:i]).contactId];
            }
        } 
        else 
        {
            isSelectAll = NO;
            for (int i = 0; i < [arrayOfContacts count]; i++) 
            {
                ((Contact*)[arrayOfContacts objectAtIndex:i]).isSelected = NO;
            }
            [selectedArrayOfContacts removeAllObjects];
        }
    } 
    else 
    {
        if (selectBtn.selected == NO) 
        {
            ((Contact*)[arrayOfContacts objectAtIndex:(selectBtn.tag-1)]).isSelected = YES;
            [selectedArrayOfContacts addObject:((Contact*)[arrayOfContacts objectAtIndex:(selectBtn.tag-1)]).contactId];
        } 
        else 
        {
            ((Contact*)[arrayOfContacts objectAtIndex:(selectBtn.tag-1)]).isSelected = NO;
            for (int i = 0; i < [selectedArrayOfContacts count]; i++) 
            {
                NSString *selectedEmail = [selectedArrayOfContacts objectAtIndex:i];
                if ([selectedEmail isEqualToString:((Contact*)[arrayOfContacts objectAtIndex:(selectBtn.tag-1)]).contactId])
                {
                    [selectedArrayOfContacts removeObjectAtIndex:i];
                    break;
                }
            }
        }
    }
    
    //selectBtn.selected  = !selectBtn.selected;
    
    [self.contactTableView reloadData];
}

- (void)addSelectedContacts:(NSMutableArray*)contacts
{
    if ([selectOfContacts count] > 0)
    {
        [selectOfContacts removeAllObjects];
        selectOfContacts = nil;
    }
    
    selectOfContacts = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [contacts count]; i++)
    {
        [selectOfContacts addObject:[contacts objectAtIndex:i]];
    }
    
    [self.contactTableView reloadData];
}

#pragma mark
#pragma mark UITableViewDelegate UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [arrayOfContacts count]+1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath 
{
	static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
		cell.opaque = NO;
    }
    
    UIButton *checkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    checkBtn.frame = CGRectMake(0, 0, 50, 44);
    checkBtn.tag = indexPath.row;
    [checkBtn addTarget:self action:@selector(selectButton:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:checkBtn];
    
    UILabel *cellTitle = [[[UILabel alloc] init] autorelease];
    [cellTitle setFont:[UIFont boldSystemFontOfSize:17]];
    [cellTitle setFrame:CGRectMake(50, 0, 250, 44)];
    [cellTitle setTextColor:[UIColor blackColor]];
    [cellTitle setTextAlignment:NSTextAlignmentLeft];
    [cellTitle setBackgroundColor:[UIColor clearColor]];
    [cell.contentView addSubview:cellTitle];

    if (indexPath.row == 0) 
    {
        cellTitle.text = @"Select all";
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (isSelectAll)
        {
            [checkBtn setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
            checkBtn.selected = YES;
        }
        else
        {
            [checkBtn setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
            checkBtn.selected = NO;
        }
    } 
    else 
    {
        if (((Contact*)[arrayOfContacts objectAtIndex:(indexPath.row-1)]).isSelected == YES)
        {
            [checkBtn setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
            checkBtn.selected = YES;
        }
        else
        {
            [checkBtn setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
            checkBtn.selected = NO;
        }
        
        cellTitle.text = [NSString stringWithFormat:@"%@ %@", ((Contact*)[arrayOfContacts objectAtIndex:indexPath.row-1]).firstName, ((Contact*)[arrayOfContacts objectAtIndex:indexPath.row-1]).lastName]; 
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath 
{
    if (indexPath.row == 0) 
    {
    } 
    else 
    {
        ContactEditViewController *contactEdit = [[ContactEditViewController alloc] initWithNibName:@"ContactEditViewController" bundle:nil];
        
        NSString *phone = ((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).phoneNumber.length == 10 ? [self phoneNumberConvert:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).phoneNumber] : ((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).phoneNumber;
        
        [contactEdit setID:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).contactId setFirstName:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).firstName setLastName:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).lastName setEmail:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).email setPhone:phone setNotes:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).notes setImageURL:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).photoURL];
        
        [[AppDelegate getAppDelegate].mainTabBarController.navigationController pushViewController:contactEdit animated:YES];
        contactEdit.rootViewController = self;
        
        [self viewDidDisappear:NO];
    }
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
    // assigning control back to the main controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person
{
    
    SelectContactViewController *selectContact = [[[SelectContactViewController alloc] initWithNibName:@"SelectContactViewController" bundle:nil] autorelease];
    
    NSString *firstname = (NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty) == nil ? @"":(NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastname = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty) == nil ? @"":(NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString *note = (NSString*)ABRecordCopyValue(person, kABPersonNoteProperty) == nil ? @"":(NSString*)ABRecordCopyValue(person, kABPersonNoteProperty);
    UIImage *photo = (NSData *)ABPersonCopyImageData(person) == nil ? nil : [UIImage imageWithData:(NSData *)ABPersonCopyImageData(person)];
    
    ABMutableMultiValueRef multiPhone = ABRecordCopyValue(person,kABPersonPhoneProperty);
    ABMutableMultiValueRef multiEmail = ABRecordCopyValue(person,kABPersonEmailProperty);
    
    [selectContact setFirstName:firstname setLastName:lastname setPhones:multiPhone setEmails:multiEmail setNote:note setImage:photo];
    
    [self.navigationController pushViewController:selectContact animated:YES];
    
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person 
                                property:(ABPropertyID)property 
                              identifier:(ABMultiValueIdentifier)identifier 
{
    return NO;
}

- (void)dealloc
{
	if( arrayOfContacts != nil )
	{
        [arrayOfContacts removeAllObjects];
		[arrayOfContacts release];
	}
    arrayOfContacts = nil;
        
    if( selectedArrayOfContacts != nil )
	{
        [selectedArrayOfContacts removeAllObjects];
		[selectedArrayOfContacts release];
	}
    selectedArrayOfContacts = nil;
    
    if (selectOfContacts != nil)
    {
        [selectOfContacts removeAllObjects];
        [selectOfContacts release];
    }
    selectOfContacts = nil;
    
	_contactModel = REMOVEOBSERVER(ContactModel, self);
    
    [addContactTabBarController release];
    [_contactTableView release];
    [_ibAddContactBtn release];

	[super dealloc];
}

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
    
    _contactModel = ADDOBSERVER(ContactModel, self);

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
    
    CGRectSet(self.contactTableView, -1, NAV_AND_STARUS_BAR_HEIGHT, -1, SCREEN_HEIGHT-BOTTOM_TAB_HEIGHT-NAV_AND_STARUS_BAR_HEIGHT);
    CGRectSet(self.ibAddContactBtn, -1, CGRectBottom(self.contactTableView.frame), -1, -1);

    // Do any additional setup after loading the view from its nib.
}

- (void)refreshProfile 
{
    if ([arrayOfContacts count] > 0) 
    {
        [arrayOfContacts removeAllObjects];
        arrayOfContacts = nil;
    }
    
    arrayOfContacts = [[NSMutableArray alloc] init];
    
    if ([selectedArrayOfContacts count] > 0) 
    {
        [selectedArrayOfContacts removeAllObjects];
        selectedArrayOfContacts = nil;
    }
    
    selectedArrayOfContacts = [[NSMutableArray alloc] init];
    
    NSMutableArray *temp = [[[NSMutableArray alloc] init] autorelease];
    
    for( Contact* contact in _contactModel.contacts ) 
    {
        [temp addObject:contact.firstName];
    }
    NSArray *sortedTemp = [temp sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    
    for (int i = 0; i < [sortedTemp count]; i++)
    {
        for (Contact* contact in _contactModel.contacts)
        {
            if( ([arrayOfContacts indexOfObject:contact] >= arrayOfContacts.count) &&
               [contact.firstName isEqualToString:[sortedTemp objectAtIndex:i]] )
            {
                contact.isSelected = NO;
                [arrayOfContacts addObject:contact];
            }
        }
    }
    
    for (int k = 0; k < [selectOfContacts count]; k++) 
    {
        for (int j = 0; j < [arrayOfContacts count]; j++)
        {
            if ([[selectOfContacts objectAtIndex:k] isEqualToString:((Contact*)[arrayOfContacts objectAtIndex:j]).contactId])
            {
                ((Contact*)[arrayOfContacts objectAtIndex:j]).isSelected = YES;
                NSLog(@"%@", ((Contact*)[arrayOfContacts objectAtIndex:j]).firstName);
                [selectedArrayOfContacts addObject:((Contact*)[arrayOfContacts objectAtIndex:j]).contactId];
            }
        }
    } 
    
    if ([selectOfContacts count] == [arrayOfContacts count])
    { 
        isSelectAll = YES;
    }
    
    [self.contactTableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated 
{
    
    CGRectSet(self.contactTableView, 0, 0, -1, SCREEN_HEIGHT-BOTTOM_TAB_HEIGHT);
    
    self.title = @"Manage Contacts";
    
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStylePlain target:self action:@selector(submit:)] autorelease];
    
	[Flurry logEvent:@"bugle contact view"];
    [Flurry logPageView];
    [self refreshProfile];
    [super viewDidAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _contactModel = REMOVEOBSERVER(ContactModel, self);
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.contactTableView = nil;
    self.ibAddContactBtn = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.contactTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.contactTableView deselectRowAtIndexPath:[self.contactTableView indexPathForSelectedRow] animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)contactModel:(ContactModel *)contactModel editContacts:(ReturnParam *)param
{
    [WaitingView dismissWaiting];
    
    if( param.success )
	{
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

@end
