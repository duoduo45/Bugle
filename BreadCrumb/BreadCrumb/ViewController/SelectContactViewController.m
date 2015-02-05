//
//  SelectContactViewController.m
//  BreadCrumb
//
//  Created by Hui Jiang on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SelectContactViewController.h"
#import "ContactListViewController.h"
#import "UIImage_scale.h"
#import "AppDelegate.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "Flurry.h"

@interface SelectContactViewController () <ContactModelObserver>
{
    ContactModel            *_contactModel;
}
@end

@implementation SelectContactViewController

#pragma mark
#pragma mark Set Variable from People Picker

- (NSString*)phoneNumberConvert:(NSString*)unformatted
{
    NSArray *stringComponents = [NSArray arrayWithObjects:[unformatted substringWithRange:NSMakeRange(0, 3)], 
                                 [unformatted substringWithRange:NSMakeRange(3, 3)], 
                                 [unformatted substringWithRange:NSMakeRange(6, [unformatted length]-6)], nil];
    
    NSString *formattedString = [NSString stringWithFormat:@"(%@)%@-%@", [stringComponents objectAtIndex:0], [stringComponents objectAtIndex:1], [stringComponents objectAtIndex:2]];
    NSLog(@"Formatted Phone Number: %@", formattedString);
    
    return  formattedString;
}

- (void)setFirstName:(NSString*)firstName
         setLastName:(NSString*)lastName
           setPhones:(ABMutableMultiValueRef)phones
           setEmails:(ABMutableMultiValueRef)emails
             setNote:(NSString*)Note
            setImage:(UIImage*)image
{
    if (nameArray != nil) 
        nameArray = nil;
    nameArray = [[NSArray alloc] initWithObjects:firstName, lastName, nil];
    
    _phones = phones;
    _emails = emails;
    _note = Note;
        
    if (image == nil) 
    {
        [self.photoButton setImage:[UIImage imageNamed:@"Default_Profile_Image.png"] forState:UIControlStateNormal];
    } 
    else 
    {
        image = [image cropImage:image];
        [self.photoButton setImage:image forState:UIControlStateNormal];
    }
}

#pragma mark
#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(id)sender 
{
    if ((int)ABMultiValueGetCount(_emails) == 0 && (int)ABMultiValueGetCount(_phones) == 0)
    {
        if (((UITextField*)sender).tag == 2 || ((UITextField*)sender).tag == 3 )
        {
            CGRect newFrame = self.contactView.frame;
            newFrame.origin.y += 40 * (((UITextField*)sender).tag-1);
            self.contactView.frame = newFrame;
            
            if (((UITextField*)sender).tag == 2)
            {
                _email = ((UITextField*)sender).text;
                NSLog(@"email:%@", _email);
            }
            else if (((UITextField*)sender).tag == 3)
            {
                _phone = ((UITextField*)sender).text;
                NSLog(@"phone:%@", _phone);
            }
        }
    }
    else if ((int)ABMultiValueGetCount(_emails) == 0 || (int)ABMultiValueGetCount(_phones) == 0 )
    {
        if (((UITextField*)sender).tag == 2)
        {
            CGRect newFrame = self.contactView.frame;
            newFrame.origin.y += 40 * (((UITextField*)sender).tag-1);
            self.contactView.frame = newFrame;
            
            if ((int)ABMultiValueGetCount(_emails) == 0)
            {
                _email = ((UITextField*)sender).text;
                NSLog(@"email:%@", _email);
            }
            else if ((int)ABMultiValueGetCount(_phones) == 0)
            {
                _phone = ((UITextField*)sender).text;
                NSLog(@"phone:%@", _phone);
            }
        }
    }
}

- (void)textFieldDidBeginEditing:(id)sender
{
    [_prevNextButton setEnabled:(((UITextField*)sender).tag != 0) forSegmentAtIndex:0];
    [_prevNextButton setEnabled:(((UITextField*)sender).tag != [textArray count]-1) forSegmentAtIndex:1];

    if ((int)ABMultiValueGetCount(_emails) == 0 && (int)ABMultiValueGetCount(_phones) == 0)
    {
        if (((UITextField*)sender).tag == 2 || ((UITextField*)sender).tag == 3)
        {
            CGRect newFrame = self.contactView.frame;
            newFrame.origin.y -= 40 * (((UITextField*)sender).tag-1);
            self.contactView.frame = newFrame;
        }
    }
    else if ((int)ABMultiValueGetCount(_emails) == 0 || (int)ABMultiValueGetCount(_phones) == 0 )
    {
        if (((UITextField*)sender).tag == 2)
        {
            CGRect newFrame = self.contactView.frame;
            newFrame.origin.y -= 40 * (((UITextField*)sender).tag-1);
            self.contactView.frame = newFrame;
        }
    }
    editingTextTag = ((UITextField*)sender).tag;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string 
{
	if( range.length > string.length ) return YES;
	
	NSInteger length = [textField.text substringToIndex:range.location].length + string.length + [textField.text substringFromIndex:range.location+range.length].length;
	
    if ((int)ABMultiValueGetCount(_emails) == 0 && (int)ABMultiValueGetCount(_phones) == 0)
    {
        if( textField.tag == 0 ) return (length <= 50);
        else if( textField.tag == 1 ) return (length <= 50);
        else if( textField.tag == 2) return (length <= 50);
        else if ( textField.tag == 3)
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
    }
    else if ((int)ABMultiValueGetCount(_emails) == 0)
    {
        if( textField.tag == 0 ) return (length <= 50);
        else if( textField.tag == 1 ) return (length <= 50);
        else if( textField.tag == 2) return (length <= 50);
    }
    else if ((int)ABMultiValueGetCount(_phones) == 0)
    {
        if( textField.tag == 0 ) return (length <= 50);
        else if( textField.tag == 1 ) return (length <= 50);
        else if ( textField.tag == 2)
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
    }
    else
    {
        if( textField.tag == 0 ) return (length <= 50);
        else if( textField.tag == 1 ) return (length <= 50);
    }
    
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField 
{
    for( int i=0; i<[textArray count]; i++ ) 
    {
        if( ((UITextField*)[textArray objectAtIndex:i]).tag != textField.tag ) continue;
        
        [(UITextField*)[textArray objectAtIndex:i] resignFirstResponder];
        
        if ((int)ABMultiValueGetCount(_emails) == 0 && (int)ABMultiValueGetCount(_phones) == 0)
        {
            if (i == 3 && textField.text.length == 10)
                textField.text = [self phoneNumberConvert:textField.text];
        }
        else if ((int)ABMultiValueGetCount(_phones) == 0)
        {
            if (i == 2 && textField.text.length == 10)
                textField.text = [self phoneNumberConvert:textField.text];
        }
     
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
    [actionSheet showInView:self.view];
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
    [_prevNextButton setEnabled:(textView.tag != [textArray count]-1) forSegmentAtIndex:1];

    CGRect newFrame = self.contactView.frame;
    newFrame.origin.y -= 200;
    self.contactView.frame = newFrame;
    editingTextTag = textView.tag;
}

- (void)textViewDidEndEditing:(UITextView*)textView 
{
    CGRect newFrame = self.contactView.frame;
    newFrame.origin.y += 200;
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
    newFrame.origin.y = SCREEN_HEIGHT-keyboardSize.height-newFrame.size.height-(isiOS7UP?0:0);
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
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addNewContact
{
    Contact *newContact = [[Contact alloc] init];
    
    newContact.firstName = ((UITextField*)[textArray objectAtIndex:0]).text;
    newContact.lastName = ((UITextField*)[textArray objectAtIndex:1]).text;
    newContact.email = _email;
    newContact.phoneNumber = _phone;
    newContact.notes = ((UITextField*)[textArray objectAtIndex:([textArray count]-1)]).text;
    
    NSLog(@"first name: %@, last name:%@, email:%@, phone:%@, note:%@", newContact.firstName, newContact.lastName, newContact.email, newContact.phoneNumber, newContact.notes);
    
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
    if (_email.length != 0)
    {
        if ([self emailValidate:_email])
        {
            [WaitingView popWaiting];
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
    else if(_email.length == 0 && _phone.length == 0)
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
        [WaitingView popWaiting];
        [self addNewContact];
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

- (void)selectEmailButton:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    
    for (int i = 0; i < [emailCheckBtnArray count]; i++)
    {
        if (i == btn.tag)
        {
            [[emailCheckBtnArray objectAtIndex:i] setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
            ((UIButton*)[emailCheckBtnArray objectAtIndex:i]).selected = YES;
            _email = (NSString*)ABMultiValueCopyValueAtIndex(_emails, i);
            NSLog(@"email:%@", _email);
        }
        else
        {
            [[emailCheckBtnArray objectAtIndex:i] setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
            ((UIButton*)[emailCheckBtnArray objectAtIndex:i]).selected = NO;
        }
    }
}

- (void)selectPhoneButton:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    
    for (int i = 0; i < [phoneCheckBtnArray count]; i++)
    {
        if (i == btn.tag)
        {
            [[phoneCheckBtnArray objectAtIndex:i] setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
            ((UIButton*)[phoneCheckBtnArray objectAtIndex:i]).selected = YES;
            _phone = (NSString*)ABMultiValueCopyValueAtIndex(_phones, i);
            NSLog(@"phone:%@", _phone);
        }
        else
        {
            [[phoneCheckBtnArray objectAtIndex:i] setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
            ((UIButton*)[phoneCheckBtnArray objectAtIndex:i]).selected = NO;
        }
    }
}

#pragma mark
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        labelArray = [[NSArray alloc] initWithObjects:@"Select an email address:", @"Select a phone number for SMS:", @"Notes:", nil];
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
    
    [nameArray release];
    [labelArray release];
    [emailCheckBtnArray release];
    [phoneCheckBtnArray release];
    
    [_photoButton release];
    [_toolBar release];
    [_prevNextButton release];
    [_contactView release];
    
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
    
    contactTable = [[UITableView alloc] initWithFrame:CGRectMake(10, CGRectBottom(self.photoButton.frame)+44, 300, 188) style:UITableViewStylePlain];
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

    CGRectSet(self.ibIntroLbl, -1, SCREEN_HEIGHT-30, -1, -1);
    
    if (textArray != nil) 
        [textArray removeAllObjects];
    textArray = nil;
    
    textArray = [[NSMutableArray alloc] init];
    
    if (emailCheckBtnArray != nil)
        [emailCheckBtnArray removeAllObjects];
    emailCheckBtnArray = nil;
    
    emailCheckBtnArray = [[NSMutableArray alloc] init];
    
    if (phoneCheckBtnArray != nil)
        [phoneCheckBtnArray removeAllObjects];
    phoneCheckBtnArray = nil;
    
    phoneCheckBtnArray = [[NSMutableArray alloc] init];
    
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
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
    self.title = @"Select Contact";
    
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Add Contact" style:UIBarButtonItemStylePlain target:self action:@selector(addContact:)] autorelease];
    
	[Flurry logEvent:@"select contact view"];
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
            rowHeight = 100;
        } 
        else if (indexPath.row == 0)
        {
            if (ABMultiValueGetCount(_emails) > 0)
            {
                rowHeight = 20 + 30 * ABMultiValueGetCount(_emails);
            }
            else
            {
                rowHeight = 44;
            }
        }
        else
        {
            if (ABMultiValueGetCount(_phones) > 0)
            {
                rowHeight = 20 + 30 * ABMultiValueGetCount(_phones);
            }
            else
            {
                rowHeight = 44;
            }
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
        UITextField *nameField = [[[UITextField alloc] init] autorelease];
        nameField.backgroundColor = [UIColor clearColor];
        nameField.font = [UIFont boldSystemFontOfSize:18];
        nameField.text = [nameArray objectAtIndex:indexPath.row];
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
        titleLabel.frame = CGRectMake(5, 3, 200, 15);
        titleLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
        [cell.contentView addSubview:titleLabel];
        
        if (indexPath.row == 2)
        {
            UITextView *infoContent = [[[UITextView alloc] init] autorelease];
            infoContent.text = _note;
            infoContent.frame = CGRectMake(30, 20, 250, 80);
            infoContent.backgroundColor = [UIColor clearColor];
            [infoContent setFont:[UIFont boldSystemFontOfSize:12]];
            infoContent.delegate = self;
            if ((int)ABMultiValueGetCount(_emails) == 0 && (int)ABMultiValueGetCount(_phones) == 0)
            {
                infoContent.tag = 4;
            }
            else if ((int)ABMultiValueGetCount(_emails) == 0 || (int)ABMultiValueGetCount(_phones) == 0)
            {
                infoContent.tag = 3;
            }
            else
            {
                infoContent.tag = 2;
            }

            infoContent.textColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0f];
            [cell.contentView addSubview: infoContent];
            [textArray addObject:infoContent];
        } 
        else
        {
            long count = 0;
            
            if (indexPath.row == 0)
            {
                count = ABMultiValueGetCount(_emails);
            }
            else if (indexPath.row == 1)
            {
                count = ABMultiValueGetCount(_phones);
            }
            
            if (count > 0)
            {
                for (int i = 0 ; i < count; i++)
                {
                    NSString *info = @"";
                    
                    if (indexPath.row == 0)
                    {
                        CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(_emails, i);
                        if (locLabel != NULL)
                        {
                            info =[NSString stringWithFormat:@"%@ (%@)", (NSString*)ABMultiValueCopyValueAtIndex(_emails, i), (NSString*)ABAddressBookCopyLocalizedLabel(locLabel)];
                            CFRelease(locLabel);
                        }
                        else
                        {
                            info =[NSString stringWithFormat:@"%@", (NSString*)ABMultiValueCopyValueAtIndex(_emails, i)];
                        }
                    }
                    else if (indexPath.row == 1)
                    {
                        CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(_phones, i);
                        NSString *phoneNum = (NSString*)ABMultiValueCopyValueAtIndex(_phones, i);
                        if (phoneNum.length == 10)
                        {
                            phoneNum = [self phoneNumberConvert:phoneNum];
                        }

                        if (locLabel != NULL)
                        {
                            info =[NSString stringWithFormat:@"%@ (%@)", phoneNum, (NSString*)ABAddressBookCopyLocalizedLabel(locLabel)];
                            CFRelease(locLabel);
                        }
                        else
                        {
                            info =[NSString stringWithFormat:@"%@", phoneNum];
                        }
                    }
                    
                    UILabel *infoContent = [[[UILabel alloc] init] autorelease];
                    infoContent.text = info;
                    infoContent.frame = CGRectMake(30, 20+25*i, 220, 20);
                    infoContent.backgroundColor = [UIColor clearColor];
                    [infoContent setFont:[UIFont boldSystemFontOfSize:12]];
                    infoContent.tag = [nameArray count] + indexPath.row;
                    infoContent.textColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0f];
                    [cell.contentView addSubview: infoContent];
                    
                    UIButton *checkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                    checkBtn.frame = CGRectMake(infoContent.frame.origin.x+infoContent.frame.size.width, 17+26*i, 20, 21);
                    checkBtn.tag = i;
                    if (indexPath.row == 0)
                    {
                        [emailCheckBtnArray addObject:checkBtn];
                        [checkBtn addTarget:self action:@selector(selectEmailButton:) forControlEvents:UIControlEventTouchUpInside];
                        if ( i == 0)
                        {
                            [checkBtn setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
                            checkBtn.selected = YES;
                            _email = (NSString*)ABMultiValueCopyValueAtIndex(_emails, i);
                            NSLog(@"email:%@", _email);
                        }
                        else
                        {
                            [checkBtn setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
                            checkBtn.selected = NO;
                        }
                    }
                    else if (indexPath.row == 1)
                    {
                        [phoneCheckBtnArray addObject:checkBtn];
                        [checkBtn addTarget:self action:@selector(selectPhoneButton:) forControlEvents:UIControlEventTouchUpInside];
                        if ( i == 0)
                        {
                            [checkBtn setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
                            checkBtn.selected = YES;
                            _phone = (NSString*)ABMultiValueCopyValueAtIndex(_phones, i);
                            NSLog(@"phone:%@", _phone);
                        }
                        else
                        {
                            [checkBtn setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
                            checkBtn.selected = NO;
                        }
                    }
                    [cell.contentView addSubview:checkBtn];
                }
            }
            else
            {
                NSString *info = @"";
                if (indexPath.row == 0)
                {
                    info = @"Please enter an email.";
                }
                else if (indexPath.row == 1)
                {
                    info = @"Please enter a phone number.";
                }
                
                UITextField *infoContent = [[[UITextField alloc] init] autorelease];
                infoContent.placeholder = info;
                infoContent.frame = CGRectMake(30, 20, 220, 20);
                infoContent.backgroundColor = [UIColor clearColor];
                [infoContent setFont:[UIFont boldSystemFontOfSize:12]];
                infoContent.delegate = self;
                
                if ((int)ABMultiValueGetCount(_emails) == 0 && (int)ABMultiValueGetCount(_phones) == 0)
                    infoContent.tag = [nameArray count] + indexPath.row;
                else
                    infoContent.tag = [nameArray count] + 0;

                infoContent.clearButtonMode = UITextFieldViewModeWhileEditing;
                infoContent.textColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0f];
                [cell.contentView addSubview: infoContent];
                [textArray addObject:infoContent];
                
                if (indexPath.row == 0)
                {
                    infoContent.keyboardType = UIKeyboardTypeEmailAddress;
                    infoContent.returnKeyType = UIReturnKeyNext;
                }
                else if (indexPath.row == 1)
                {
                    infoContent.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                    infoContent.returnKeyType = UIReturnKeyNext;
                }
                
                UIButton *checkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                checkBtn.frame = CGRectMake(infoContent.frame.origin.x+infoContent.frame.size.width, 17, 20, 21);
                [checkBtn setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
                checkBtn.selected = YES;
                checkBtn.tag = 0;
                [cell.contentView addSubview:checkBtn];
            }
        }
    }
    
    return cell;
}

- (void)contactModel:(ContactModel *)contactModel addContact:(ReturnParam *)param
{
    [WaitingView dismissWaiting];

    if( param.success )
	{
        [self.navigationController popViewControllerAnimated:YES];
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
