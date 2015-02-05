//
//  BreadCrumbProtocol.m
//  BreadCrumb
//
//  Created by Hui Jiang on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BreadCrumbProtocol.h"
#import "ASIFormDataRequest.h"

@implementation BreadCrumbProtocol

@synthesize delegate = _delegate;

- (void)sendRequest:(NSString*)strURL 
      RequestMethod:(NSString*)method 
      RequestObject:(NSString*)object
           KeyArray:(NSMutableArray*)array 
          PostValue:(NSMutableDictionary*)dictionary {
    
	strURL = [NSString stringWithFormat:@"http://www.gobreadcrumb.com/%@", strURL];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:strURL]];
    [request setDelegate:self];
    
    [request setRequestMethod:method];
    [request setDelegate:self];
    
    if ([dictionary count] > 0) {
        for (int i=0; i < [dictionary count]; i++) {
            [request setPostValue:[dictionary objectForKey:[array objectAtIndex:i]] forKey:[NSString stringWithFormat:@"%@%@",object, [array objectAtIndex:i]]];
        }
    }
    
    [request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    [self.delegate Successed:request];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    [self.delegate Failed:request];
}

@end
