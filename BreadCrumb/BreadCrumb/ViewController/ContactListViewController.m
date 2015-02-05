//
//  ContactListViewController.m
//  BreadCrumb
//
//  Created by Hui Jiang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ContactEditViewController.h"
#import "SelectContactViewController.h"
#import "ContactListViewController.h"
#import "NewContactViewController.h"
#import "BreadCrumbData.h"
#import "AppDelegate.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "Flurry.h"
#import "ContactModel.h"

@interface ContactListViewController () <ContactModelObserver>
{
    ContactModel        *_contactModel;
}
@end

@implementation ContactListViewController

#pragma mark
#pragma mark Button Event

- (IBAction)deleteButtonClick:(id)sender 
{    
    isDeleteDone  = !isDeleteDone;
    
    if( isDeleteDone == NO )
    {
        [AppDelegate getAppDelegate].mainTabBarController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonClick:)] autorelease];
        [self.contactTableView setEditing:YES animated:YES];
    }
    else
    {
        [AppDelegate getAppDelegate].mainTabBarController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonClick:)] autorelease];
        [self.contactTableView setEditing:NO animated:YES];
    }
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

- (IBAction)addMoreContacts:(id)sender 
{
    addContactTabBarController = [[UITabBarController alloc] init];
    
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
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

#pragma mark
#pragma mark UITableViewDelegate UITableViewDataSource

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [WaitingView popWaiting];
        
        [_contactModel deleteContact:(Contact*)[arrayOfContacts objectAtIndex:indexPath.row]];


        [arrayOfContacts removeObjectAtIndex:indexPath.row];

    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [arrayOfContacts count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath 
{
   
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
        cell.opaque = NO;
    }
	
    Contact* contact = ((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]);

    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
    	        
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath 
{

    ContactEditViewController *contactEdit = [[ContactEditViewController alloc] initWithNibName:@"ContactEditViewController" bundle:nil];

    NSString *phone = ((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).phoneNumber.length == 10 ? [self phoneNumberConvert:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).phoneNumber] : ((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).phoneNumber;
    
    [contactEdit setID:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).contactId setFirstName:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).firstName setLastName:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).lastName setEmail:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).email setPhone:phone setNotes:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).notes setImageURL:((Contact*)[arrayOfContacts objectAtIndex:indexPath.row]).photoURL];
    
    [self.navigationController pushViewController:contactEdit animated:YES];
    contactEdit.rootViewController = self;

    [self viewDidDisappear:NO];
}

#pragma mark
#pragma mark ABPeoplePickerNavigationController

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

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

#pragma mark
#pragma mark 初始化和销毁函数
- (void)dealloc
{
    if( arrayOfContacts != nil )
    {
        [arrayOfContacts removeAllObjects];
        [arrayOfContacts release];
    }
    arrayOfContacts = nil;

    _contactModel = REMOVEOBSERVER(ContactModel, self);

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
        self.title = @"Contacts";
        self.tabBarItem.image = [UIImage imageNamed:@"Button_TabBarIcon_Contacts.png"];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark
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

    isDeleteDone = YES;
    
    if (!_contactTableView) {
        _contactTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NAV_AND_STARUS_BAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-NAV_AND_STARUS_BAR_HEIGHT-BOTTOM_TAB_HEIGHT) style:UITableViewStylePlain];
        _contactTableView.delegate = self;
        _contactTableView.dataSource = self;
        [self.view addSubview:_contactTableView];
    }
    
    [self.view bringSubviewToFront:self.ibAddContactBtn];
}

- (void)refreshProfile
{
    if ([arrayOfContacts count] > 0) 
    {
        [arrayOfContacts removeAllObjects];
        arrayOfContacts = nil;
    }
    
    arrayOfContacts = [[NSMutableArray alloc] init];
    
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
                [arrayOfContacts addObject:contact];
                break;
            }
        }
    }
    
    [self.contactTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated 
{
    if ([AppDelegate getAppDelegate].isPresentModel) {
        CGRectSet(self.contactTableView, 0, 0, -1, SCREEN_HEIGHT-BOTTOM_TAB_HEIGHT);
        [AppDelegate getAppDelegate].isPresentModel = NO;
    }
    
    [super viewDidAppear:animated];

    [AppDelegate getAppDelegate].mainTabBarController.navigationController.navigationBarHidden = NO;
    [AppDelegate getAppDelegate].mainTabBarController.title = @"Contacts";
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.titleView = nil;

    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.leftBarButtonItem = nil;
    [AppDelegate getAppDelegate].mainTabBarController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonClick:)] autorelease];

    [Flurry logEvent:@"contact list view"];
    [Flurry logPageView];
    
    [self refreshProfile];
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    [super viewDidDisappear:animated];
    
    [self.contactTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.contactTableView deselectRowAtIndexPath:[self.contactTableView indexPathForSelectedRow] animated:NO];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)contactModel:(ContactModel *)contactModel deleteContact:(ReturnParam *)param
{
    [WaitingView dismissWaiting];
    
    if( param.success )
    {
        [self.contactTableView reloadData];
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
