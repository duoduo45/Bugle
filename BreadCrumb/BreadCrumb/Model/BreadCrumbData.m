//
//  BreadCrumbData.m
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BreadCrumbData.h"

@implementation User

@synthesize userID = _userID;
@synthesize email = _email;
@synthesize firstname = _firstname;
@synthesize lastname = _lastname;
@synthesize phone = _phone;
@synthesize birthYear = _birthYear;
@synthesize homeStreet = _homeStreet;
@synthesize homeCity = _homeCity;
@synthesize homeState = _homeState;
@synthesize homeZip = _homeZip;
@synthesize homeCountry = _homeCountry;
@synthesize height = _height;
@synthesize weight = _weight;
@synthesize eyes = _eyes;
@synthesize hair = _hair;
@synthesize gender = _gender;
@synthesize ethnicity = _ethnicity;
@synthesize notes = _notes;
@synthesize vehicleYear = _vehicleYear;
@synthesize vehicleModel = _vehicleModel;
@synthesize vehicleMake = _vehicleMake;
@synthesize vehicleColor = _vehicleColor;
@synthesize vehicleLP = _vehicleLP;
@synthesize vehicleLS = _vehicleLS;
@synthesize medicalAllergies = _medicalAllergies;
@synthesize medicalMedications = _medicalMedications;
@synthesize medicalConditions = _medicalConditions;
@synthesize photoURL = _photoRUL;
@synthesize photoData = _photoData;
@synthesize sendItinerary = _sendItinerary;
@synthesize sendOverview = _sendOverview;

-(id) init
{
	if( self = [super init] )
	{
		self.userID = @"";
        self.email = @"";
		self.firstname = @"";
		self.lastname = @"";
		self.phone = @"";
        self.birthYear = @"";
		self.homeStreet = @"";
        self.homeCity = @"";
		self.homeState = @"";
		self.homeZip = @"";
		self.homeCountry = @"";
        self.height = @"";
		self.weight = @"";
		self.eyes = @"";
		self.hair = @"";
		self.gender = @"";
		self.ethnicity = @"";
        self.notes = @"";
        self.vehicleYear = @"";
		self.vehicleModel = @"";
		self.vehicleMake = @"";
		self.vehicleColor = @"";
        self.vehicleLP = @"";
        self.vehicleLS = @"";
		self.medicalAllergies = @"";
		self.medicalMedications = @"";
		self.medicalConditions = @"";
        self.photoURL = @"";
        self.photoData = nil;
		self.sendItinerary = YES;
		self.sendOverview = YES;
	}
	return self;
}

-(void) set:(User*)other
{
	self.userID = other.userID;
	self.email = other.email;
	self.firstname = other.firstname;
	self.lastname = other.lastname;
	self.phone = other.phone;
	self.birthYear = other.birthYear;
	self.homeStreet = other.homeStreet;
	self.homeCity = other.homeCity;
	self.homeState = other.homeState;
	self.homeZip = other.homeZip;
	self.homeCountry = other.homeCountry;
	self.height = other.height;
	self.weight = other.weight;
	self.eyes = other.eyes;
	self.hair = other.hair;
	self.gender = other.gender;
	self.ethnicity = other.ethnicity;
	self.notes = other.notes;
	self.vehicleYear = other.vehicleYear;
	self.vehicleModel = other.vehicleModel;
	self.vehicleMake = other.vehicleMake;
	self.vehicleColor = other.vehicleColor;
	self.vehicleLP = other.vehicleLP;
	self.vehicleLS = other.vehicleLS;
	self.medicalAllergies = other.medicalAllergies;
	self.medicalMedications = other.medicalMedications;
	self.medicalConditions = other.medicalConditions;
	self.photoURL = other.photoURL;
	self.photoData = [other.photoData retain];
	self.sendItinerary = other.sendItinerary;
	self.sendOverview = other.sendOverview;
}

-(void) dealloc
{
	if( _photoData ) [_photoData release];
	
	[super dealloc];
}

-(void) setPhotoData:(NSData*)photoData
{
	if( _photoData == photoData ) return;
	
	if( _photoData != nil )
	{
		[_photoData release];
		_photoData = nil;
	}
	if( photoData != nil )
	{
		_photoData = [photoData retain];
	}
}

@end

@implementation Crumb


@synthesize crumbId = _crumbId;
@synthesize name = _name;
@synthesize alertMessage = _alertMessage;
@synthesize deadline = _deadline;
@synthesize status = _status;
@synthesize lastCheckedTime = _lastCheckedTime;
@synthesize contacts = _contacts;

-(id) init
{
	if( self = [super init] )
	{
		self.crumbId = @"";
		self.name = @"";
		self.alertMessage = @"";
		self.deadline = @"";
		self.status = @"";
		self.lastCheckedTime = @"";
		_contacts = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void) setContacts:(NSMutableArray*)newContacts
{
	if( newContacts == nil )
	{
		[_contacts removeAllObjects];
	}
	else if( (newContacts != nil) && (_contacts != newContacts) )
	{
		[_contacts removeAllObjects];
		for( Contact* contact in newContacts ) [_contacts addObject:contact];
	}
}

-(void) dealloc
{
	[_contacts release];
	
	[super dealloc];
}

-(void) parseFromDictionary:(NSDictionary*)dic
{
	self.crumbId = SafeCopy([dic objectForKey:@"id"]);
	self.name = SafeCopy([dic objectForKey:@"name"]);
	self.alertMessage = SafeCopy([dic objectForKey:@"alert_message"]);
	self.deadline = LocalDatetime(SafeCopy([dic objectForKey:@"deadline"]));
	self.status = SafeCopy([dic objectForKey:@"status"]);
	self.lastCheckedTime = SafeCopy([dic objectForKey:@"last_checked_time"]);
	[_contacts removeAllObjects];
	
	NSArray* contacts = [dic objectForKey:@"contacts"];
	for( NSDictionary* contactDic in contacts )
	{
		contactDic = [contactDic objectForKey:@"contact"];
		NSString* contactId = [NSString stringWithFormat:@"%@", [contactDic objectForKey:@"id"]];
		if( contactId.length == 0 ) continue;
		NSInteger orgIndex = [_contacts indexOfObject:contactId];
		if( (orgIndex >= 0) && (orgIndex < _contacts.count) ) continue;
		[_contacts addObject:contactId];
	}
}

-(BOOL) isWarned
{
	NSDate* deadline = StringToDate(_deadline);
	NSDate* warnline = [NSDate dateWithTimeInterval:-10*60 sinceDate:deadline];
	return ( [[NSDate date] earlierDate:warnline] == warnline );
}

-(BOOL) isOverdue
{
	BOOL overdue = NO;
	BOOL used = NO;
	BOOL pending = NO;
	
	NSDate* deadline = StringToDate(_deadline);
	
	if( [_status isEqualToString:@"cancelled"] || 
	   [_status isEqualToString:@"checked_in"] )
	{
		used = YES;
	}
	else if( ([_status isEqualToString:@"alerted"]) ||
			([[NSDate date] earlierDate:deadline] == deadline) )
	{
		overdue = YES;
	}
	else if( [_status isEqualToString:@"pending"] ||
			([_status isEqualToString:@"warning"]) )
	{
		pending = YES;
	}
	return overdue;
}

-(BOOL) isCheckedOrCanceled
{
	BOOL overdue = NO;
	BOOL used = NO;
	BOOL pending = NO;
	
	NSDate* deadline = StringToDate(_deadline);
	
	if( [_status isEqualToString:@"cancelled"] ||
	   [_status isEqualToString:@"checked_in"] )
	{
		used = YES;
	}
	else if( ([_status isEqualToString:@"alerted"]) ||
			([[NSDate date] earlierDate:deadline] == deadline) )
	{
		overdue = YES;
	}
	else if( [_status isEqualToString:@"pending"] ||
			([_status isEqualToString:@"warning"]) )
	{
		pending = YES;
	}
	return used;
}

-(BOOL) isPending
{
	BOOL overdue = NO;
	BOOL used = NO;
	BOOL pending = NO;
	
	NSDate* deadline = StringToDate(_deadline);
	
	if( [_status isEqualToString:@"cancelled"] ||
	   [_status isEqualToString:@"checked_in"] )
	{
		used = YES;
	}
	else if( ([_status isEqualToString:@"alerted"]) ||
			([[NSDate date] earlierDate:deadline] == deadline) )
	{
		overdue = YES;
	}
	else if( [_status isEqualToString:@"pending"] ||
			([_status isEqualToString:@"warning"]) )
	{
		pending = YES;
	}
	return pending;
}

@end



@implementation Contact

@synthesize contactId = _contactId;
@synthesize email = _email;
@synthesize firstName = _firstName;
@synthesize lastName = _lastName;
@synthesize phoneNumber = _phoneNumber;
@synthesize notes = _notes;
@synthesize photoURL = _photoURL;
@synthesize photoData = _photoData;
@synthesize isSelected = _isSelected;

-(id) init
{
	if( self = [super init] )
	{
		self.contactId = @"";
		self.email = @"";
		self.firstName = @"";
		self.lastName = @"";
		self.phoneNumber = @"";
        self.notes = @"";
        self.photoURL = @"";
        self.photoData = nil;
        self.isSelected = NO;
	}
	return self;
}

@end


//@implementation Activity
//
//@synthesize description;
//@synthesize name;
//@synthesize crumbs;
//
//- (id)CreatActivity:(NSString *)Name 
//        Description:(NSString*)Description 
//             Crumbs:(NSMutableArray*)Crumbs {
//	
//	if( (self = [super init]) ) {
//        name = [[NSString alloc] initWithString:Name];
//        description = [[NSString alloc] initWithString:Description];
//		
//        crumbs = [[NSMutableArray alloc] init];
//        
//        if ([Crumbs count] > 0) {
//            for (int j = 0; j < [Crumbs count]; j++) {
//                NSMutableDictionary *crumbDic = [[Crumbs objectAtIndex:j] objectForKey:@"crumb"];
//                NSLog(@"%@",crumbDic);
//                NSLog(@"%@",[crumbDic objectForKey:@"activity_id"]);
//                NSMutableArray *contactArray = [crumbDic objectForKey:@"crumb_contacts"];
//                Crumb *crumb = [[Crumb alloc] init];
//                [crumb CreatCrumb:([crumbDic objectForKey:@"activity_id"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"activity_id"] 
//					 AlertMessage:([crumbDic objectForKey:@"alert_message"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"alert_message"]  
//						CreatedAt:([crumbDic objectForKey:@"created_at"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"created_at"] 
//						 Deadline:([crumbDic objectForKey:@"deadline"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"deadline"] 
//					  Description:([crumbDic objectForKey:@"description"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"description"] 
//				  LastCheckedTime:([crumbDic objectForKey:@"last_checked_time"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"last_checked_time"] 
//							 Name:([crumbDic objectForKey:@"name"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"name"] 
//						   Status:([crumbDic objectForKey:@"status"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"status"] 
//						UpdatedAt:([crumbDic objectForKey:@"updated_at"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"updated_at"] 
//						   UserID:([crumbDic objectForKey:@"user_id"]== [NSNull null]) ? @"" : [crumbDic objectForKey:@"user_id"]
//					CrumbContacts:contactArray];
//                
//                [crumbs addObject:crumb];
//                [crumb release];
//            }
//        }
//	}
//	return self;
//}
//
//- (void)dealloc {
//	[super dealloc];
//	[description release];
//	[name release];
//    
//    if (crumbs != nil) {
//        [crumbs removeAllObjects];
//    }
//    [crumbs release];
//}
//
//@end
