//
//  UserModel.h
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModelObserver.h"
#import "BreadCrumbData.h"
#import "ASIFormDataRequest.h"

#define CLIENT_ID       (@"9a7f80cdfc4ca8e9fb79da65edff6ceb")
#define CLIENT_SECRET   (@"f2c215328fba3ac653fb410d586854cc")
#define CLIENT_FB_ID       (@"18c73c20bf01d57f3fde3bbb8487ecf3")
#define CLIENT_FB_SECRET   (@"a3e24b7b51ba4b0858b59e609d053798")

BOOL IsError(ASIHTTPRequest* request, NSDictionary* response, ReturnParam* param);

@interface UserModel : BaseModel

@property (strong, nonatomic) NSString* userID;
@property (strong, nonatomic) User* user;
@property (strong, nonatomic) NSString* accessToken;
@property (strong, nonatomic) NSString* refreshToken;

-(void) regist:(NSString*)email password:(NSString*)password passwordConfirmation:(NSString*)passwordConfirmation;
-(void) signIn:(NSString*)email password:(NSString*)password;
-(void) signInWithFacebookLogin:(NSString*)fbID accessToken:(NSString*)fbAccessToken;
-(void) forgetPassword:(NSString*)email;
-(void) updateUserProfile:(User*)user;
-(void) downloadCrumbsAndContacts;
-(void) updateAccessToken;
-(BOOL) checkAccessToken;
-(BOOL) checkRefreshToken;

@end


@protocol UserModelObserver <BaseModelObserver>

@optional
-(void) userModel:(UserModel*)userModel registed:(ReturnParam*)param;
-(void) userModel:(UserModel*)userModel signIn:(ReturnParam*)param;
-(void) userModel:(UserModel*)userModel signInWithFacebookLogin:(ReturnParam*)param;
-(void) userModel:(UserModel*)userModel forgetPassword:(ReturnParam*)param;
-(void) userModel:(UserModel*)userModel updateUserProfile:(ReturnParam*)param;
-(void) userModel:(UserModel*)userModel downloadCrumbsAndContacts:(ReturnParam*)param;
-(void) userModel:(UserModel*)userModel updateAccessToken:(ReturnParam*)param;

@end