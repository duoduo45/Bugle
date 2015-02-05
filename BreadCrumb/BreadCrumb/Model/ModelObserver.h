//
//  ModelObserver.h
//  KCService
//
//  Created by dongwen on 12-1-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BaseModelObserver <NSObject>
@end


@interface BaseModel : NSObject {
    // 多线程保护
    NSCondition*	_locker;
	
    // 观察者队列
	NSMutableArray* _observers;
}

-(void) addObserver:(id<BaseModelObserver>)observer;
-(void) removeObserver:(id<BaseModelObserver>)observer;
-(void) callObserver:(SEL)action withObject:(id)object;
-(void) callObserver:(SEL)action withObject:(id)object1 withObject:(id)object2;

@end


@interface ReturnParam : NSObject {
	BOOL _success;
	NSInteger _failedCode;
	NSString* _failedReason;
	NSMutableDictionary* _userInfo;
}
@property (nonatomic)		  BOOL				   success;
@property (nonatomic)		  NSInteger			   failedCode;
@property (strong, nonatomic) NSString*			   failedReason;
@property (strong, nonatomic) NSMutableDictionary* userInfo;
@end