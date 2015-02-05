//
//  BreadcrumbContactViewController.h
//  BreadCrumb
//
//  Created by Hui Jiang on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface BreadcrumbContactViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate>
{
    UITabBarController      *addContactTabBarController;
    NSMutableArray          *arrayOfContacts;
    NSMutableArray          *selectedArrayOfContacts;
    NSMutableArray          *selectOfContacts;
    
    BOOL                    isSelectAll;
}

@property (strong, nonatomic) IBOutlet UITableView  *contactTableView;
@property (strong, nonatomic) IBOutlet UIButton     *ibAddContactBtn;
@property (assign, nonatomic) id                    target;
@property (nonatomic) SEL                           callback;

- (IBAction)addMoreContacts:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)submit:(id)sender;
- (void)refreshProfile;
- (void)addSelectedContacts:(NSMutableArray*)contacts;

@end
