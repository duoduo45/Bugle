//
//  ModelObserver.m
//  KCService
//
//  Created by dongwen on 12-1-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ModelObserver.h"

@interface ObserverAssign : NSObject
@property (assign, nonatomic) id<BaseModelObserver> observer;
@end
@implementation ObserverAssign
@synthesize observer;
@end

#pragma mark
#pragma mark BaseModel

@implementation BaseModel

#pragma mark
#pragma mark observer

-(void) addObserver:(id<BaseModelObserver>)observer
{
	if( observer == nil ) return;
	
	for( ObserverAssign* eachAs in _observers )
	{
		if( eachAs.observer == observer ) return;
	}
	
	ObserverAssign* as = [[ObserverAssign alloc] init];
	as.observer = observer;
	[_observers addObject:as];
	[as release];
}

-(void) removeObserver:(id<BaseModelObserver>)observer
{
	if( observer == nil ) return;
	
	for( NSInteger index = _observers.count-1; index >= 0; index-- )
	{
		ObserverAssign* as = [_observers objectAtIndex:index];
		if( as.observer == observer )
		{
			[_observers removeObject:as];
		}
	}
}

-(void) callObserver:(SEL)action withObject:(id)object
{
	[self callObserver:action withObject:object withObject:nil];
}

-(void) callObserver:(SEL)action withObject:(id)object1 withObject:(id)object2
{
    [_locker lock];
	for( NSInteger i = 0; i < _observers.count; i++ )
	{
		ObserverAssign* eachAs = [_observers objectAtIndex:i];
		if( [eachAs.observer respondsToSelector:action] )
		{
			[eachAs.observer performSelector:action withObject:object1 withObject:object2];
		}
	}
    [_locker unlock];
}


#pragma mark
#pragma mark init & dealloc

-(id) init
{
	if( self = [super init] )
	{
        _locker = [[NSCondition alloc] init];
		_observers = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void) dealloc
{
	[super dealloc];
	
	if( _locker != nil )
	{
		[_locker release];
		_locker = nil;
	}
	if( _observers != nil )
	{
		[_observers removeAllObjects];
		[_observers release];
		_observers = nil;
	}
}

@end

#pragma mark
#pragma mark ReturnParam

@implementation ReturnParam

@synthesize success = _success;
@synthesize failedCode = _failedCode;
@synthesize failedReason = _failedReason;
@synthesize userInfo = _userInfo;

-(id) init
{
	if( self = [super init] )
	{
		self.success = NO;
		self.failedCode = 0;
		self.failedReason = @"";
		_userInfo = [[NSMutableDictionary alloc] init];
	}
	return self;
}
@end
