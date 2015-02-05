//
//  NewContactViewController.m
//  BreadCrumb
//
//  Created by Hui Jiang on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ContactListViewController.h"
#import "WelcomeAccountViewController.h"
#import "UIImage_scale.h"
#import "AppDelegate.h"
#import "GlobalModel.h"
#import "WaitingView.h"
#import "Flurry.h"
#import "Keychain.h"

@interface WelcomeAccountViewController () <UserModelObserver>
{
    UserModel    *_userModel;
}

@end

@implementation WelcomeAccountViewController

@synthesize photoButton = _photoButton;
@synthesize submitButton = _submitButton;
@synthesize toolBar = _toolBar;
@synthesize prevNextButton = _prevNextButton;
@synthesize contactView = _contactView;

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
    if (((UITextField*)sender).tag == 0)
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y += 100;
        self.contactView.frame = newFrame;
    } 
    else if (((UITextField*)sender).tag == 1)
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y += 140;
        self.contactView.frame = newFrame;
    }
    else if (((UITextField*)sender).tag == 2)
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y += 180;
        self.contactView.frame = newFrame;
    }
}

- (void)textFieldDidBeginEditing:(id)sender 
{
    [_prevNextButton setEnabled:(((UITextField*)sender).tag != 0) forSegmentAtIndex:0];
	[_prevNextButton setEnabled:(((UITextField*)sender).tag != 2) forSegmentAtIndex:1];
    
    if (((UITextField*)sender).tag == 0)
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y -= 100;
        self.contactView.frame = newFrame;
    } 
    else if (((UITextField*)sender).tag == 1)
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y -= 140;
        self.contactView.frame = newFrame;
    } 
    else if (((UITextField*)sender).tag == 2)
    {
        CGRect newFrame = self.contactView.frame;
        newFrame.origin.y -= 180;
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
    else if( textField.tag == 2)
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
            [self addContact:nil];
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
            [AppDelegate getAppDelegate].isPresentModel = YES;
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
            [AppDelegate getAppDelegate].isPresentModel = YES;
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

    User *userData = [[User alloc] init];
    
    userData.userID = _userModel.user.userID;
    userData.email = _userModel.user.email;
    userData.firstname = ((UITextField*)[textArray objectAtIndex:0]).text;
    userData.lastname =((UITextField*)[textArray objectAtIndex:1]).text;
    userData.phone = ((UITextField*)[textArray objectAtIndex:2]).text;
    userData.photoData = UIImagePNGRepresentation(self.photoButton.imageView.image);;
        
    [_userModel updateUserProfile:userData];
    [userData release];
}

- (IBAction)addContact:(id)sender 
{
    if (((UITextField*)[textArray objectAtIndex:0]).text.length == 0 || [((UITextField*)[textArray objectAtIndex:0]).text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Error"
							  message:@"Please fill in your first name."
							  delegate:nil 
							  cancelButtonTitle:@"Close" 
							  otherButtonTitles:nil,nil];
		[alert show];
		[alert release];
    }
    else if (((UITextField*)[textArray objectAtIndex:1]).text.length == 0 || [((UITextField*)[textArray objectAtIndex:1]).text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Error"
							  message:@"Please fill in your last name."
							  delegate:nil
							  cancelButtonTitle:@"Close"
							  otherButtonTitles:nil,nil];
		[alert show];
		[alert release];
    }
    else if (self.photoButton.imageView.image == nil)
    {
        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Error"
							  message:@"Please choose your profile image."
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


#pragma mark
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        nameplaceholderArray = [[NSArray alloc] initWithObjects:@"First Name", @"Last Name", @"Phone (U.S. only)", nil];
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
    _userModel = REMOVEOBSERVER(UserModel, self);

    if (textArray != nil) 
    {
        [textArray removeAllObjects];
        [textArray release];
    }
    textArray = nil;
    
    [nameplaceholderArray release];
    
    [self.photoButton release];
    [self.toolBar release];
    [self.contactView release];
    [self.prevNextButton release];
    
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _userModel = ADDOBSERVER(UserModel, self);
    
    nameTable = [[UITableView alloc] initWithFrame:CGRectMake(75, self.photoButton.frame.origin.y+self.photoButton.frame.size.height+10, 170, 200) style:UITableViewStyleGrouped];
    nameTable.backgroundView = nil;
	nameTable.backgroundColor = [UIColor clearColor];
    nameTable.separatorColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
	nameTable.delegate = self;
	nameTable.dataSource = self;
    nameTable.scrollEnabled = NO;
    nameTable.sectionHeaderHeight = 2;
    nameTable.sectionFooterHeight = 2;
    [self.contactView addSubview:nameTable];
    [nameTable release];
    
    self.photoButton.layer.borderColor=[[UIColor colorWithRed:36.0/255.0 green:54.0/255.0 blue:77.0/255.0 alpha:1.0] CGColor];
    self.photoButton.layer.borderWidth= 1.0f;
    self.photoButton.layer.masksToBounds=YES;
    
    self.submitButton.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:143.0/255.0 blue:37.0/255.0 alpha:1.0];
    self.submitButton.layer.borderColor = [[UIColor colorWithRed:186.0/255.0 green:115.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor];
    self.submitButton.titleLabel.textColor = [UIColor whiteColor];
    self.submitButton.layer.borderWidth = 1.0f;
    
    if (textArray != nil)
        [textArray removeAllObjects];
    textArray = nil;
    
    textArray = [[NSMutableArray alloc] init];
    
    InternetImageView *iv = [[InternetImageView alloc] init];
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"UserProfilePic"])
    {
        [iv imageFromURL:[[NSUserDefaults standardUserDefaults] valueForKey:@"UserProfilePic"] Delegate:self];
    }else {
        [iv imageFromURL:[Keychain getStringForKey:@"UserProfilePic"] Delegate:self];
    }
    
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
    
    _userModel = REMOVEOBSERVER(UserModel, self);

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.photoButton = nil;
    self.prevNextButton = nil;
    self.contactView = nil;
    self.toolBar = nil;
}

-(void) viewDidAppear:(BOOL)animated
{
    self.navigationItem.hidesBackButton = YES;
    self.title = @"Welcome to Bugle!";
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    
	[Flurry logEvent:@"first time user account view"];
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
    return 3;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return  40;
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
        if (indexPath.section == 0 || indexPath.section == 1)
        {
            UILabel *starMarkLabel = [[[UILabel alloc] init] autorelease];
            starMarkLabel.backgroundColor = [UIColor clearColor];
            starMarkLabel.font = [UIFont boldSystemFontOfSize:20];
            starMarkLabel.text = @"*";
            starMarkLabel.frame = CGRectMake(135, 5, 15, 15);
            starMarkLabel.textColor = [UIColor colorWithRed:255.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0f];
            [cell.contentView addSubview:starMarkLabel];
        }
        
        UITextField *nameField = [[[UITextField alloc] init] autorelease];
        nameField.backgroundColor = [UIColor clearColor];
        nameField.font = [UIFont boldSystemFontOfSize:15];
        nameField.placeholder = [nameplaceholderArray objectAtIndex:indexPath.section];
        if (indexPath.section == 0 && [[NSUserDefaults standardUserDefaults] valueForKey:@"UserFirstName"])
        {
            nameField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserFirstName"];
        } else {
            nameField.text = [Keychain getStringForKey:@"UserFirstName"];
        }
        
        if (indexPath.section == 1 && [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLastName"])
        {
            nameField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserLastName"];
        } else {
            nameField.text = [Keychain getStringForKey:@"UserLastName"];
        }
        
        if (indexPath.section == 2 && [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPhone"])
        {
            nameField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserPhone"];
        } else {
            nameField.text = [Keychain getStringForKey:@"UserPhone"];
        }
        
        nameField.frame = CGRectMake(10, 8, 130, 22);
        nameField.delegate = self;
        nameField.keyboardType = UIKeyboardTypeDefault;
        nameField.returnKeyType = UIReturnKeyNext;
        nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
        nameField.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
        nameField.tag = indexPath.section;
        [cell.contentView addSubview:nameField];
        [textArray addObject:nameField];
        
    }     
    return cell;
}

- (void)userModel:(UserModel *)userModel updateUserProfile:(ReturnParam *)param
{
    [WaitingView dismissWaiting];
    
    if( param.success )
	{
        [[AppDelegate getAppDelegate] switchToMyAccount];
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

- (void)InternetImageView:(InternetImageView *)imageView Image:(UIImage *)image
{
    [[self.photoButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
    [self.photoButton setImage:[self imageByScalingProportionallyToSize:self.photoButton.frame.size OriginalImage:image] forState:UIControlStateNormal];
}


- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize OriginalImage:(UIImage*)image {
    
    UIImage *sourceImage = image;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (!CGSizeEqualToSize(imageSize, targetSize)) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    
    return newImage ;
}

@end
