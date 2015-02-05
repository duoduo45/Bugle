//
//  GlobalModel.h
//  BreadCrumb
//
//  Created by apple on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"
#import "CrumbModel.h"
#import "ContactModel.h"

#define DEFINE_NEW_GLOBALMODEL(modelName)	\
	modelName* __instance##modelName; \
	static modelName* request##modelName##WithObserver(id<BaseModelObserver> observer) \
	{ \
		if( __instance##modelName == nil ) {__instance##modelName = [[modelName alloc] init];} \
		if( observer != nil ) [__instance##modelName addObserver:observer]; \
		return __instance##modelName; \
	} \
	static modelName* remove##modelName##Observer(id<BaseModelObserver> observer) \
	{ \
		[__instance##modelName removeObserver:observer]; \
		return nil; \
	}

#define ADDOBSERVER(modelName, observer) request##modelName##WithObserver(observer)
#define REMOVEOBSERVER(modelName, observer) remove##modelName##Observer(observer)
#define GETMODEL(modelName) ADDOBSERVER(modelName, nil)


// add your model here.
// DEFINE_NEW_GLOBALMODEL(ModelName);
DEFINE_NEW_GLOBALMODEL(UserModel)
DEFINE_NEW_GLOBALMODEL(CrumbModel)
DEFINE_NEW_GLOBALMODEL(ContactModel)
