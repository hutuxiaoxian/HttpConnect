//
//  HttpConnectTests.m
//  HttpConnectTests
//
//  Created by 糊涂 on 14-7-10.
//  Copyright (c) 2014年 hutu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Connect.h"

@interface HttpConnectTests : XCTestCase<ResponseDelegate>

@end

@implementation HttpConnectTests
typedef enum {
    get_asyn,
    post_asyn
}respTypeKey;
- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testExample {
    Connect *conn = [Connect getInstance];// 网络请求单例
    
    // GET方式网络同步请求
    NSString *strUrl = @"https://github.com/";
    NSData *respData = [conn getSynConnectWithURL:strUrl];
    NSLog(@"%@",[[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding]);
}

- (void)responseDate:(id)json Type:(NSInteger)type {
    NSLog(@"%@",json);
}

@end
