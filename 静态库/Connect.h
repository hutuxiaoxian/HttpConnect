//
//  Connect.h
//  HutuConnect
//
//  Created by 糊涂 on 14-6-27.
//  Copyright (c) 2014年 糊涂. All rights reserved.
//  单例类，网络请求

#import <Foundation/Foundation.h>

// 网络请求回调
@protocol ResponseDelegate <NSObject>
-(void)responseDate:(id) json Type:(NSInteger)type;
@end

@interface Connect : NSObject
+(Connect*)getInstance;

//同步的get请求
-(NSData*)getSynConnectWithURL:(NSString*)strUrl;
//同步的post请求
-(NSData*)postSynConnectWithURL:(NSString*)strUrl body:(NSDictionary*)dict;

// 异步get请求，数据返回到主线程中
-(void)getConnectWithURL:(NSString*)strUrl delegate:(id<ResponseDelegate>)delegate type:(NSInteger)type;
// 异步post请求，数据返回到主线程中
-(void)postConnectWithUR:(NSString*)strUrl body:(NSDictionary*)dict delegate:(id<ResponseDelegate>)delegate type:(NSInteger)type;

//文件下载
-(void)fileDownLoadWithURL:(NSString*)strUrl savePath:(NSString*)path;
//数据下载
-(NSData*)downLoadWithURL:(NSString*)strUrl;
//上传文件,同步上传
-(BOOL)upLodeWithURL:(NSString*)strUrl body:(NSDictionary*)body file:(NSData*)fdata fileName:(NSString*)fname ;

//使用JSON解析数据
-(NSDictionary*)jsonData:(NSData*)data;
@end
