//
//  HttpRequestDefine.m
//  zyfrog
//
//  Created by Zyfrog on 12-8-8.
//  Copyright (c) 2012年 Zyfrog. All rights reserved.
//

#import "HttpRequestDefine.h"
#define FORTEST

#ifdef FORTEST
NSString* const KServeiceDomain = @"http://desolate-falls-7881.herokuapp.com";

#else

NSString* const KServeiceDomain       = @"http://www.gobugle.com";

#endif