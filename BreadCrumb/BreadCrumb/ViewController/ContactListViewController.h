//
//  ContactListViewController.h
//  BreadCrumb
//
//  Created by Hui Jiang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ContactListViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>
{
    UITabBarController  *addContactTabBarController;
    NSMutableArray      *arrayOfContacts;

    BOOL                isDeleteDone;
}

@property (strong, nonatomic) UITableView          *contactTableView;
@property (strong, nonatomic) IBOutlet UIButton             *ibAddContactBtn;

- (IBAction)addMoreContacts:(id)sender;
- (IBAction)deleteButtonClick:(id)sender;
- (void)refreshProfile;

@end
