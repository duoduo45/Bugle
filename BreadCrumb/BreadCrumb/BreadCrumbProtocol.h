//
//  BreadCrumbProtocol.h
//  BreadCrumb
//
//  Created by Hui Jiang on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@protocol BreadCrumbProtocolDelegate;

@interface BreadCrumbProtocol : NSObject <ASIHTTPRequestDelegate>

@property (strong, nonatomic) id<BreadCrumbProtocolDelegate> delegate;


- (void)sendRequest:(NSString*)strURL 
      RequestMethod:(NSString*)method 
      RequestObject:(NSString*)object
           KeyArray:(NSMutableArray*)array 
          PostValue:(NSMutableDictionary*)dictionary;

@end


@protocol BreadCrumbProtocolDelegate

@required

- (void)Successed:(ASIHTTPRequest *)request;
- (void)Failed:(ASIHTTPRequest *)request;

@end
