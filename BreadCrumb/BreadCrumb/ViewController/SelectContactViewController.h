//
//  SelectContactViewController.h
//  BreadCrumb
//
//  Created by Hui Jiang on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface SelectContactViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UITableView             *nameTable;
    UITableView             *contactTable;
    
    NSArray                 *nameArray;
    NSArray                 *labelArray;
    
    NSMutableArray          *textArray;
    NSMutableArray          *emailCheckBtnArray;
    NSMutableArray          *phoneCheckBtnArray;
    
    ABMutableMultiValueRef  _phones;
    ABMutableMultiValueRef  _emails;
    
    NSString                *_note;
    NSString                *_email;
    NSString                *_phone;
    
    long                    editingTextTag;
}

@property(strong, nonatomic) IBOutlet UIButton              *photoButton;
@property(strong, nonatomic) IBOutlet UIView                *contactView;
@property(strong, nonatomic) IBOutlet UIToolbar             *toolBar;
@property(strong, nonatomic) IBOutlet UISegmentedControl    *prevNextButton;
@property(strong, nonatomic) IBOutlet UILabel               *ibIntroLbl;

- (IBAction)cancel:(id)sender;
- (IBAction)addContact:(id)sender;
- (IBAction)takeAPicture:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)prevNextButtonClick:(id)sender;
- (IBAction)doneButtonClick:(id)sender;

- (void)setFirstName:(NSString*)firstName 
         setLastName:(NSString*)lastName 
           setPhones:(ABMutableMultiValueRef)phones
           setEmails:(ABMutableMultiValueRef)emails
             setNote:(NSString*)Note
            setImage:(UIImage*)image;

@end
