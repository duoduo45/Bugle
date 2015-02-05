//
//  StackMobProtocol.m
//  BreadCrumb
//
//  Created by Hui Jiang on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StackMobProtocol.h"
#import "StackMob.h"

@implementation StackMobProtocol

@synthesize delegate = _delegate;

- (void)sendRequest:(NSMutableDictionary*)dic APIName:(NSString*)api {

    //schema name "blogentry" must be 3-25 alphanumeric characters, lowercase
    [[StackMob stackmob] post:api
                withArguments:dic andCallback:^(BOOL success, id result){
                    if(success){
                        //action after successful call
                        [self.delegate StackMobSuccessed:result];
                        
                    } else {
                        NSLog(@"%@", result);
                        
                        [self.delegate StackMobFailed:result];
                    }
                }];
}

@end
