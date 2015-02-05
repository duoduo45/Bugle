//
//  ContactEditViewController.h
//  BreadCrumb
//
//  Created by Hui Jiang on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InternetImageView.h"

@interface ContactEditViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, InternetImageViewDelegate>
{
    UITableView     *nameTable;
    UITableView     *contactTable;
    
    NSArray         *labelArray;
    NSArray         *nameArray;
    NSArray         *infoArray;
    
    NSMutableArray  *textArray;
    
    NSString                *userID;

    long            editingTextTag;
    
    UIViewController *rootViewController;
}

@property(strong, nonatomic) IBOutlet UIButton              *photoButton;
@property(strong, nonatomic) IBOutlet UIView                *contactView;
@property(strong, nonatomic) IBOutlet UIToolbar             *toolBar;
@property(strong, nonatomic) IBOutlet UISegmentedControl    *prevNextButton;
@property(strong, nonatomic) UIViewController               *rootViewController;

- (void)setID:(NSString*)userid setFirstName:(NSString*)firstname setLastName:(NSString*)lastname setEmail:(NSString*)email setPhone:(NSString*)phone setNotes:(NSString*)notes setImageURL:(NSString*)imageURL;

- (IBAction)cancel:(id)sender;
- (IBAction)submit:(id)sender;
- (IBAction)takeAPicture:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)prevNextButtonClick:(id)sender;
- (IBAction)doneButtonClick:(id)sender;

@end
