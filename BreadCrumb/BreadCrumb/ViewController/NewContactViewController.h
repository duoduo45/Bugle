//
//  NewContactViewController.h
//  BreadCrumb
//
//  Created by Hui Jiang on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewContactViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UITableView     *nameTable;
    UITableView     *contactTable;
    
    NSArray         *labelArray;
    NSArray         *nameplaceholderArray;
    NSArray         *infoplaceholderArray;
    
    NSMutableArray  *textArray;
    
    long            editingTextTag;
}

@property(strong, nonatomic) IBOutlet UIButton              *photoButton;
@property(strong, nonatomic) IBOutlet UIView                *contactView;
@property(strong, nonatomic) IBOutlet UIToolbar             *toolBar;
@property(strong, nonatomic) IBOutlet UISegmentedControl    *prevNextButton;

- (IBAction)cancel:(id)sender;
- (IBAction)addContact:(id)sender;
- (IBAction)takeAPicture:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)prevNextButtonClick:(id)sender;
- (IBAction)doneButtonClick:(id)sender;

@end
