//
//  NewContactViewController.m
//  BreadCrumb
//
//  Created by Hui Jiang on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ContactListViewController.h"
#import "NewContactViewController.h"
#import "UIImage_scale.h"
#import "AppDelegate.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "Flurry.h"

@interface NewContactViewController () <ContactModelObserver>
{
    ContactModel    *_contactModel;
}
@end

@implementation NewContactViewController

#pragma mark
#pragma mark UITextFieldDelegate

- (NSString*)phoneNumberConvert:(NSString*)unformatted
{
    NSArray *stringComponents = [NSArray arrayWithObjects:[unformatted substringWithRange:NSMakeRange(0, 3)], 
                                 [unformatted substringWithRange:NSMakeRange(3, 3)], 
                                 [unformatted substringWithRange:NSMakeRange(6, [unformatted length]-6)], nil];
    
    NSString *formattedString = [NSString stringWithFormat:@"(%@)%@-%@", [stringComponents objectAtIndex:0], [stringComponents objectAtIndex:1], [stringComponents objectAtIndex:2]];
    NSLog(@"Formatted Phone Number: %@", formattedString);
    
    return  formattedString;
}

- (void)textFieldDidEndEditing:(id)sender 
{
    if (((UITextField*)sender).tag == 2) 
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y += 100;
        self.contactView.frame = newFrame;
    } 
    else if (((UITextField*)sender).tag == 3) 
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y += 140;
        self.contactView.frame = newFrame;
    }
}

- (void)textFieldDidBeginEditing:(id)sender 
{
    [_prevNextButton setEnabled:(((UITextField*)sender).tag != 0) forSegmentAtIndex:0];
    [_prevNextButton setEnabled:(((UITextField*)sender).tag != 4) forSegmentAtIndex:1];

    if (((UITextField*)sender).tag == 2)
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y -= 100;
        self.contactView.frame = newFrame;
    } 
    else if (((UITextField*)sender).tag == 3) 
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y -= 140;
        self.contactView.frame = newFrame;
    } 
    
    editingTextTag = ((UITextField*)sender).tag;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string 
{
	if( range.length > string.length ) return YES;
	
	NSInteger length = [textField.text substringToIndex:range.location].length + string.length + [textField.text substringFromIndex:range.location+range.length].length;
	
	if( textField.tag == 0 ) return (length <= 50);
	else if( textField.tag == 1 ) return (length <= 50);
    else if( textField.tag == 2) return (length <= 50);
    else if( textField.tag == 3) 
    {
        NSCharacterSet *numSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789-()"];
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        long charCount = [newString length];
        
        if ([string isEqualToString:@""]) 
        {
            return YES;
        } 
        
        if ([newString rangeOfCharacterFromSet:[numSet invertedSet]].location != NSNotFound|| [string rangeOfString:@"-"].location != NSNotFound|| charCount > 14) {
            return NO;
        }
        
        if (charCount == 3)
        {
            newString = [NSString stringWithFormat:@"(%@)-", newString];
        }
        else if (charCount == 9) 
        {
            newString = [newString stringByAppendingString:@"-"];
        }
        
        textField.text = newString;
        
        return NO;
    };
    
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField 
{
    for( int i=0; i<[textArray count]; i++ ) 
    {
        if( ((UITextField*)[textArray objectAtIndex:i]).tag != textField.tag ) continue;
        
        [(UITextField*)[textArray objectAtIndex:i] resignFirstResponder];
        
        if( i+1 < [textArray count])
        {
            [(UITextField*)[textArray objectAtIndex:i+1] becomeFirstResponder];
            editingTextTag = ((UITextField*)[textArray objectAtIndex:i+1]).tag;
        }
        else
        {
        }
        break;
    }
    
    return YES;
}

- (IBAction)takeAPicture:(id)sender 
{
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add Picture"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"From Library", @"Take New Photo", nil];
    [actionSheet showFromToolbar:self.toolBar];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 从相册选取
    if( buttonIndex == 0 )
    {
        UIImagePickerController* ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.allowsEditing = YES;
        ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        if( self != nil ) 
        {
            [self presentViewController:ipc animated:YES completion:nil];
        }
        
    }
    // 新照片
    else if( buttonIndex == 1 )
    {
        if( ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] )
        {
            [self imagePickerController:nil didFinishPickingMediaWithInfo:[NSDictionary dictionaryWithObject:[UIImage imageNamed:@"bg_mainmenu.png"] forKey:@"UIImagePickerControllerEditedImage"]];
            return;
        }
        
        UIImagePickerController* ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.allowsEditing = YES;
        ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if( self != nil ) 
        {
            [self presentViewController:ipc animated:YES completion:nil];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    
    [self.photoButton setImage:image forState:UIControlStateNormal];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker 
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark
#pragma mark UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView*)textView 
{
    [_prevNextButton setEnabled:(textView.tag != 4) forSegmentAtIndex:1];

    CGRect newFrame = self.contactView.frame;
    newFrame.origin.y -= 220;
    self.contactView.frame = newFrame;  
    editingTextTag = textView.tag;
}

- (void)textViewDidEndEditing:(UITextView*)textView 
{	
    CGRect newFrame = self.contactView.frame;
    newFrame.origin.y += 220;
    self.contactView.frame = newFrame;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text 
{
    return TRUE;
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGRect newFrame = self.toolBar.frame;
    newFrame.origin.y = SCREEN_HEIGHT-keyboardSize.height-newFrame.size.height-(isiOS7UP?0:20);
    self.toolBar.frame = newFrame;
    
    self.toolBar.hidden = NO;
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    self.toolBar.hidden = YES;
}

#pragma mark
#pragma mark Button Event

- (IBAction)cancel:(id)sender 
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)addNewContact
{
    [WaitingView popWaiting];
    Contact *newContact = [[Contact alloc] init];
    
    newContact.firstName = ((UITextField*)[textArray objectAtIndex:0]).text;
    newContact.lastName = ((UITextField*)[textArray objectAtIndex:1]).text;
    newContact.email = ((UITextField*)[textArray objectAtIndex:2]).text;
    newContact.phoneNumber = ((UITextField*)[textArray objectAtIndex:3]).text;
    newContact.notes = ((UITextView*)[textArray objectAtIndex:4]).text;
    newContact.photoData = UIImagePNGRepresentation(self.photoButton.imageView.image);

    [_contactModel addContact:newContact];
    [newContact release];
}

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

- (IBAction)addContact:(id)sender 
{
    if (((UITextField*)[textArray objectAtIndex:0]).text.length == 0 || [((UITextField*)[textArray objectAtIndex:0]).text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Error"
							  message:@"Please fill in your contact's first name."
							  delegate:nil 
							  cancelButtonTitle:@"Close" 
							  otherButtonTitles:nil,nil];
		[alert show];
		[alert release];
    }
    else if (((UITextField*)[textArray objectAtIndex:2]).text.length == 0 && ((UITextField*)[textArray objectAtIndex:3]).text.length == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Error"
							  message:@"Please enter at least one email or one phone number."
							  delegate:nil 
							  cancelButtonTitle:@"Close"
							  otherButtonTitles:nil,nil];
		[alert show];
		[alert release];
    }
    else
    {        
        if (((UITextField*)[textArray objectAtIndex:2]).text.length != 0)
        {
            if ([self emailValidate:((UITextField*)[textArray objectAtIndex:2]).text])
            {
                [self addNewContact];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Error"
                                      message:@"Invalid email address"
                                      delegate:nil
                                      cancelButtonTitle:@"Close"
                                      otherButtonTitles:nil, nil];
                [alert show];
                [alert release];
            }
        }
        else if (((UITextField*)[textArray objectAtIndex:3]).text.length != 0)
        {
            [self addNewContact];
        }
    }
}

- (IBAction)prevNextButtonClick:(id)sender
{
    for( int i=0; i<[textArray count]; i++ ) 
    {
        if( ((UITextField*)[textArray objectAtIndex:i]).tag == editingTextTag )
        {
            if (((UISegmentedControl*)sender).selectedSegmentIndex == 0)
            {
                if( i-1 >= 0)
                {
                    [(UITextField*)[textArray objectAtIndex:i-1] becomeFirstResponder];
                }
                break;
            } 
            else
            {
                if( i+1 < [textArray count])
                {
                    [(UITextField*)[textArray objectAtIndex:i+1] becomeFirstResponder];
                }
                break;
            }
        }
    }    
}

- (IBAction)doneButtonClick:(id)sender
{
    [[textArray objectAtIndex:editingTextTag] resignFirstResponder];
}

- (IBAction)backgroundTouched:(id)sender 
{
    [[textArray objectAtIndex:editingTextTag] resignFirstResponder];
}


#pragma mark
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        labelArray = [[NSArray alloc] initWithObjects:@"Email:", @"Phone:", @"Notes:", nil];
        nameplaceholderArray = [[NSArray alloc] initWithObjects:@"First Name", @"Last Name", nil];
        infoplaceholderArray = [[NSArray alloc] initWithObjects:@"", @"(U.S. phone number only)", @"", nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    _contactModel = REMOVEOBSERVER(ContactModel, self);

    if (textArray != nil) 
    {
        [textArray removeAllObjects];
        [textArray release];
    }
    textArray = nil;
    
    [nameplaceholderArray release];
    [labelArray release];
    [infoplaceholderArray release];
    
    [_photoButton release];
    [_toolBar release];
    [_contactView release];
    [_prevNextButton release];
    
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _contactModel = ADDOBSERVER(ContactModel, self);
    
    CGRectSet(self.contactView, 0, NAV_AND_STARUS_BAR_HEIGHT, -1, SCREEN_HEIGHT-NAV_AND_STARUS_BAR_HEIGHT-BOTTOM_TAB_HEIGHT);
    [self.view sendSubviewToBack:self.contactView];
    
    
    self.photoButton.layer.borderColor=[[UIColor colorWithRed:36.0/255.0 green:54.0/255.0 blue:77.0/255.0 alpha:1.0] CGColor];
    self.photoButton.layer.borderWidth= 1.0f;
    self.photoButton.layer.masksToBounds=YES;
    
    contactTable = [[UITableView alloc] initWithFrame:CGRectMake(10, CGRectBottom(self.photoButton.frame)+44, 300, 198) style:UITableViewStylePlain];
    contactTable.backgroundView = nil;
    contactTable.backgroundColor = [UIColor clearColor];
    contactTable.separatorColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
    if ([UIApplication respondsToSelector:@selector(setSeparatorInset:)]) {
        contactTable.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    contactTable.delegate = self;
    contactTable.dataSource = self;
    contactTable.scrollEnabled = NO;
    contactTable.layer.borderColor=[[UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f] CGColor];
    contactTable.layer.borderWidth= 1.0f;
    contactTable.layer.masksToBounds=YES;
    [self.contactView addSubview:contactTable];
    
    nameTable = [[UITableView alloc] initWithFrame:CGRectMake(CGRectRight(self.photoButton.frame)+15, CGRectTop(self.photoButton.frame), 200, 88) style:UITableViewStylePlain];
    nameTable.backgroundView = nil;
    nameTable.backgroundColor = [UIColor clearColor];
    nameTable.separatorColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
    if ([UIApplication respondsToSelector:@selector(setSeparatorInset:)]) {
        nameTable.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    nameTable.delegate = self;
    nameTable.dataSource = self;
    nameTable.scrollEnabled = NO;
    nameTable.layer.borderColor=[[UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f] CGColor];
    nameTable.layer.borderWidth= 1.0f;
    nameTable.layer.masksToBounds=YES;
    [self.contactView addSubview:nameTable];

    
    if (textArray != nil) 
        [textArray removeAllObjects];
    textArray = nil;
    
    textArray = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _contactModel = REMOVEOBSERVER(ContactModel, self);

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.photoButton = nil;
    self.prevNextButton = nil;
    self.contactView = nil;
    self.toolBar = nil;
}

-(void) viewDidAppear:(BOOL)animated
{
    self.title = @"New Contact";
    
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Add Contact" style:UIBarButtonItemStylePlain target:self action:@selector(addContact:)] autorelease];
    
	[Flurry logEvent:@"new contact view"];
    [Flurry logPageView];
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section 
{
    int rowCount;
    
    if (tableView == nameTable) 
    {
        rowCount = 2;
    } 
    else
    {
        rowCount = 3;
    }
    return rowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    float rowHeight;
    
    if (tableView == nameTable) 
    {
        rowHeight = 44;
    } 
    else 
    {
        if (indexPath.row == 2) 
        {
            rowHeight = 110;
        } 
        else 
        {
            rowHeight = 44;
        }
    }
    return  rowHeight;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath 
{
	
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) 
    {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
		cell.opaque = NO;
        cell.backgroundColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (tableView == nameTable) 
    {
        if (indexPath.row == 0) 
        {
            UILabel *starMarkLabel = [[[UILabel alloc] init] autorelease];
            starMarkLabel.backgroundColor = [UIColor clearColor];
            starMarkLabel.font = [UIFont boldSystemFontOfSize:20];
            starMarkLabel.text = @"*";
            starMarkLabel.frame = CGRectMake(165, 15, 15, 15);
            starMarkLabel.textColor = [UIColor colorWithRed:255.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0f];
            [cell.contentView addSubview:starMarkLabel];
        }
        
        UITextField *nameField = [[[UITextField alloc] init] autorelease];
        nameField.backgroundColor = [UIColor clearColor];
        nameField.font = [UIFont boldSystemFontOfSize:18];
        nameField.placeholder = [nameplaceholderArray objectAtIndex:indexPath.row];
        nameField.frame = CGRectMake(5, 10, 175, 22);
        nameField.delegate = self;
        nameField.keyboardType = UIKeyboardTypeDefault;
        nameField.returnKeyType = UIReturnKeyNext;
        nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
        nameField.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
        nameField.tag = indexPath.row;
        [cell.contentView addSubview:nameField];
        [textArray addObject:nameField];
        
    } 
    else if (tableView == contactTable) 
    {
        UILabel *titleLabel = [[[UILabel alloc] init] autorelease];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:12];
        titleLabel.text = [labelArray objectAtIndex:indexPath.row];
        titleLabel.frame = CGRectMake(5, 3, 150, 15);
        titleLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
        [cell.contentView addSubview:titleLabel];
        
        if (indexPath.row == 2) 
        {
            UITextView *infoContent = [[[UITextView alloc] init] autorelease];
            infoContent.text = [infoplaceholderArray objectAtIndex:indexPath.row];
            infoContent.frame = CGRectMake(30, 20, 250, 140);
            infoContent.backgroundColor = [UIColor clearColor];
            [infoContent setFont:[UIFont boldSystemFontOfSize:12]];
            infoContent.delegate = self;
            infoContent.tag = [nameplaceholderArray count] + indexPath.row;
            infoContent.textColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0f];
            [cell.contentView addSubview: infoContent];
            [textArray addObject:infoContent];
        }
        else 
        {
            UITextField *infoContent = [[[UITextField alloc] init] autorelease];
            infoContent.backgroundColor = [UIColor clearColor];
            [infoContent setFont:[UIFont boldSystemFontOfSize:12]];
            infoContent.placeholder = [infoplaceholderArray objectAtIndex:indexPath.row];
            infoContent.frame = CGRectMake(30, 20, 250, 20);
            infoContent.delegate = self;
            infoContent.tag = [nameplaceholderArray count] + indexPath.row;
            
            if (indexPath.row == 0) 
            {
                infoContent.keyboardType = UIKeyboardTypeEmailAddress;
                infoContent.returnKeyType = UIReturnKeyNext;
            } 
            else 
            {
                infoContent.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                infoContent.returnKeyType = UIReturnKeyNext;
            }
            infoContent.clearButtonMode = UITextFieldViewModeWhileEditing;
            infoContent.textColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0f];
            [cell.contentView addSubview: infoContent];
            [textArray addObject:infoContent];        
        }
    }
    
    return cell;
}

- (void)contactModel:(ContactModel *)contactModel addContact:(ReturnParam *)param
{
    [WaitingView dismissWaiting];
    
    if( param.success )
	{
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
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
