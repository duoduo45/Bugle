//
//  ContactModel.h
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModelObserver.h"
#import "BreadCrumbData.h"

#define CLIENT_ID       (@"9a7f80cdfc4ca8e9fb79da65edff6ceb")

@interface ContactModel : BaseModel

@property (strong, nonatomic) NSMutableArray* contacts;

- (void)downloadContacts;
- (void)addContact:(Contact*)contact;
- (void)editContact:(Contact*)contact;
- (void)deleteContact:(Contact*)contact;

@end


@protocol ContactModelObserver <BaseModelObserver>

@optional

-(void) contactModel:(ContactModel*)contactModel downloadContacts:(ReturnParam*)param;
-(void) contactModel:(ContactModel*)contactModel addContact:(ReturnParam*)param;
-(void) contactModel:(ContactModel*)contactModel editContact:(ReturnParam*)param;
-(void) contactModel:(ContactModel*)contactModel deleteContact:(ReturnParam*)param;

@end

