//
//  StackMobProtocol.h
//  BreadCrumb
//
//  Created by Hui Jiang on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StackMobProtocolDelegate;

@interface StackMobProtocol : NSObject

@property (strong, nonatomic) id<StackMobProtocolDelegate> delegate;


- (void)sendRequest:(NSMutableDictionary*)dic APIName:(NSString*)api;

@end


@protocol StackMobProtocolDelegate

@required

- (void)StackMobSuccessed:(id)result;
- (void)StackMobFailed:(id)result;

@end