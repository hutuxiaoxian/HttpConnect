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
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    Connect *conn = [Connect getInstance];// 网络请求单例
    
    // GET方式网络同步请求
    NSString *strUrl = @"http://www.baidu.com";
    NSData *respData = [conn getSynConnectWithURL:strUrl];
//    NSDictionary *dict = [conn jsonData:respData];//将数据转换为JSON格式
    // GET方式异步请求
    [conn getConnectWithURL:strUrl delegate:self type:get_asyn];//type 为请求识别码
    // post方式网络同步请求
    NSDictionary *dict = @{@"key": @"value"};
    respData = [conn postSynConnectWithURL:strUrl body:dict];
    // post方式异步请求
    [conn postConnectWithUR:strUrl body:dict delegate:self type:post_asyn];
}

@end
