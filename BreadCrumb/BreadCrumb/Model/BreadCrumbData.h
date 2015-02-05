//
//  BreadCrumbData.h
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark
#pragma mark utils

NS_INLINE NSString* SafeCopy(NSString* str)
{
	if( (str == nil)||(str == (NSString*)[NSNull null]) ) return @"";
	else return [NSString stringWithFormat:@"%@",str];
}
NS_INLINE NSString* DateToString(NSDate* date)
{
	if( date == nil ) return nil;
	
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"ccc MMM dd yyyy, hh:mm a"];
	NSString* dateString = [formatter stringFromDate:date];
	[formatter release];
	return dateString;
}
NS_INLINE NSDate* StringToDate(NSString* dateString)
{
	if( dateString == nil ) return nil;
	
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"ccc MMM dd yyyy, hh:mm a"];
	NSDate* date = [formatter dateFromString:dateString];
	[formatter release];
	return date;
}
// "Wed, 11 Apr 2012 06:00:00 +0000" ==> "Wed Apr 11 2012, 06:00:00" (local time zone)
NS_INLINE NSString* LocalDatetime(NSString* systemTime)
{
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:usLocale];
	[formatter setDateFormat:@"ccc, dd MMM yyyy HH:mm:ss Z"];
	NSDate* d = [formatter dateFromString:systemTime];
	[formatter release];
	[usLocale release];
	return DateToString(d);
}
// "Wed Apr 11 2012, 06:00:00" ==> "Wed Apr 11 2012, 06:00:00 +0800" (local time zone)
NS_INLINE NSString* ServerDatetime(NSString* localTime)
{
	NSDate* d = StringToDate(localTime);
	
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:usLocale];
	[formatter setDateFormat:@"ccc, dd MMM yyyy HH:mm:ss Z"];
	NSString* datetime = [formatter stringFromDate:d];
	[formatter release];
	[usLocale release];
	return datetime;
}

NS_INLINE NSDate* LastCheckedInStringToDate(NSString* systemTime)
{
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:usLocale];
	[formatter setDateFormat:@"ccc, dd MMM yyyy HH:mm:ss Z"];
	NSDate* d = [formatter dateFromString:systemTime];
	[formatter release];
	[usLocale release];
	return d;
}

NS_INLINE NSString* LastCheckedInDateToString(NSDate* systemDate)
{
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:usLocale];
	[formatter setDateFormat:@"ccc, dd MMM yyyy HH:mm:ss Z"];
	NSString* datetime = [formatter stringFromDate:systemDate];
	[formatter release];
	[usLocale release];
	return datetime;
}

#pragma mark
#pragma mark user

@interface User : NSObject {
	NSString*		_userID;
    NSString*       _email;
    NSString*       _firstname;
    NSString*       _lastname;
    NSString*       _phone;
    NSString*       _birthYear;
	NSString*		_homeStreet;
    NSString*		_homeCity;
	NSString*		_homeState;
	NSString*		_homeZip;
	NSString*		_homeCountry;
    NSString*       _height;
    NSString*       _weight;
	NSString*		_eyes;
	NSString*		_hair;
	NSString*		_gender;
	NSString*		_ethnicity;
    NSString*       _notes;
    NSString*       _vehicleYear;
    NSString*       _vehicleMake;
    NSString*       _vehicleModel;
    NSString*       _vehicleColor;
    NSString*       _vehicleLP;
    NSString*       _vehicleLS;
	NSString*		_medicalAllergies;
	NSString*		_medicalMedications;
	NSString*		_medicalConditions;
    NSString*       _photoURL;
    NSData*         _photoData;
	BOOL			_sendItinerary;
	BOOL			_sendOverview;
}

@property (nonatomic, strong) NSString*			userID;
@property (nonatomic, strong) NSString*			email;
@property (nonatomic, strong) NSString*			firstname;
@property (nonatomic, strong) NSString*			lastname;
@property (nonatomic, strong) NSString*			phone;
@property (nonatomic, strong) NSString*         birthYear;
@property (nonatomic, strong) NSString*			homeStreet;
@property (nonatomic, strong) NSString*			homeCity;
@property (nonatomic, strong) NSString*			homeState;
@property (nonatomic, strong) NSString*			homeZip;
@property (nonatomic, strong) NSString*			homeCountry;
@property (nonatomic, strong) NSString*			height;
@property (nonatomic, strong) NSString*			weight;
@property (nonatomic, strong) NSString*			eyes;
@property (nonatomic, strong) NSString*			hair;
@property (nonatomic, strong) NSString*			gender;
@property (nonatomic, strong) NSString*			ethnicity;
@property (nonatomic, strong) NSString*			notes;
@property (nonatomic, strong) NSString*			vehicleYear;
@property (nonatomic, strong) NSString*			vehicleMake;
@property (nonatomic, strong) NSString*			vehicleModel;
@property (nonatomic, strong) NSString*			vehicleColor;
@property (nonatomic, strong) NSString*			vehicleLP;
@property (nonatomic, strong) NSString*			vehicleLS;
@property (nonatomic, strong) NSString*			medicalAllergies;
@property (nonatomic, strong) NSString*			medicalMedications;
@property (nonatomic, strong) NSString*			medicalConditions;
@property (nonatomic, strong) NSString*			photoURL;
@property (nonatomic, strong) NSData*			photoData;
@property (nonatomic)		  BOOL				sendItinerary;
@property (nonatomic)		  BOOL				sendOverview;

-(void) set:(User*)other;

@end

#pragma mark
#pragma mark crumb

@interface Crumb : NSObject {
	NSString*		_crumbId;
	NSString*		_name;
	NSString*		_alertMessage;
	NSString*		_deadline;
	NSString*		_status;
	NSString*		_lastCheckedTime;
    NSMutableArray* _contacts;
}

@property (nonatomic, strong) NSString*			crumbId;
@property (nonatomic, strong) NSString*			name;
@property (nonatomic, strong) NSString*			alertMessage;
@property (nonatomic, strong) NSString*			deadline;
@property (nonatomic, strong) NSString*			status;
@property (nonatomic, strong) NSString*			lastCheckedTime;
@property (nonatomic, retain) NSMutableArray*	contacts;

-(void) parseFromDictionary:(NSDictionary*)dic;

-(BOOL) isWarned;
-(BOOL) isOverdue;
-(BOOL) isCheckedOrCanceled;
-(BOOL) isPending;

@end


#pragma mark
#pragma mark contact

@interface Contact : NSObject {
	NSString* _contactId;
	NSString* _email;
    NSString* _firstName;
	NSString* _lastName;
    NSString* _phoneNumber;
    NSString* _notes;
    NSString* _photoURL;
    NSData*   _photoData;

    BOOL isSelected;
}

@property (nonatomic, strong) NSString* contactId;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* firstName;
@property (nonatomic, strong) NSString* lastName;
@property (nonatomic, strong) NSString* phoneNumber;
@property (nonatomic, strong) NSString* notes;
@property (nonatomic, strong) NSString* photoURL;
@property (nonatomic, strong) NSData* photoData;
@property (nonatomic) BOOL isSelected;

@end



//@interface Activity : NSObject {
//	NSString        *description;
//	NSString        *status;
//    
//    NSMutableArray  *crumbs;
//}
//
//@property (readwrite, assign) NSString* description;
//@property (readwrite, assign) NSString* name;
//@property (readwrite, assign) NSMutableArray* crumbs;
//
//- (id)CreatActivity:(NSString *)Name 
//        Description:(NSString*)Description 
//             Crumbs:(NSMutableArray*)Crumbs;
//
//@end

