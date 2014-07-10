//
//  Connect.m
//  HutuConnect
//
//  Created by 糊涂 on 14-6-27.
//  Copyright (c) 2014年 糊涂. All rights reserved.
//  单例类，网络请求

#import "Connect.h"
#define TimeOut                 50.0
#define POST                    @"POST"
#define GET                     @"GET"
#define BOUNDARY                @"----------hutuH2ei4cH2Ij5KM7gLKM7H2I3KM7"
#define BOUNDARY_HEAD               @"&"
#define ENDCHAR                 @"\r\n"

@interface Connect()
@property NSMutableArray *urlQueue;
@property NSMutableSet *urlSet;
@property id<ResponseDelegate>delegate;
@end

@implementation Connect

static Connect *mConnect;
+(Connect*)getInstance{
    if (!mConnect) {
        mConnect = [[Connect alloc] init];
    }
    return mConnect;
}

-(id)init{
    self = [super init];
    if (self) {
        self.urlQueue = [[NSMutableArray alloc] initWithCapacity:5];
        self.urlSet = [[NSMutableSet alloc] init];
    }
    return self;
}

//将json解析出的数据使用CoreData保存
-(void)saveJSONDataToCoreData:(NSDictionary*)json{
    
}
//使用JSON解析数据
-(NSDictionary*)jsonData:(NSData*)data{
    //判断是否为json数据格式
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (![str hasPrefix:@"{"]) {
        NSLog(@"resp error %@",str);
        NSRange range = [str rangeOfString:@"{"];
        if (range.length>0) {
            str = [str substringFromIndex:range.location];
        }
    }
    
    //将符合json数据格式的数据转换输出
    NSDictionary *dict = nil;
    NSError *err ;
    dict = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&err];
    if (err) {
        NSLog(@"json 解析出错 %@ \n数据为：%@",err,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    return dict;
}
//同步的get请求
-(NSData*)getSynConnectWithURL:(NSString*)strUrl{
    
    NSURL *url = [[NSURL alloc] initWithString:strUrl];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:TimeOut];
    [req setHTTPMethod:GET];
    NSError *err ;
    NSURLResponse *resp;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    if (err) {
        [self responseError:err];
    }
    return data;
}

//同步的post请求
-(NSData*)postSynConnectWithURL:(NSString*)strUrl body:(NSDictionary*)dict{
    
    NSURL *url = [[NSURL alloc] initWithString:strUrl];
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:TimeOut];
    [req setHTTPShouldHandleCookies:NO];
    
    [req setHTTPMethod:POST];
//    [req addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];//请求类型头
    
    [req addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY] forHTTPHeaderField:@"Content-Type"];//body数据换行分割符
//    [req addValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];//数据采用gzip压缩
    [req addValue:@"UTF-8" forHTTPHeaderField:@"charset"];//编码格式
    NSData *datBody = [self postBodyWithDict:dict];
    NSLog(@"%@",[[NSString alloc] initWithData:datBody encoding:NSUTF8StringEncoding]);
    [req addValue:[NSString stringWithFormat:@"%u",[datBody length]] forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:datBody];//body数据
    
    NSError *err ;
    
    NSURLResponse *resp;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    
    if (err) {
        [self responseError:err];
    }
    
    return data;
}

// 异步get请求，数据返回到主线程中
-(void)getConnectWithURL:(NSString*)strUrl delegate:(id<ResponseDelegate>)delegate type:(NSInteger)type {
    [self connectQueue:strUrl body:nil delegate:delegate type:type];
}
// 异步post请求，数据返回到主线程中
-(void)postConnectWithUR:(NSString*)strUrl body:(NSDictionary*)dict delegate:(id<ResponseDelegate>)delegate type:(NSInteger)type{
    [self connectQueue:strUrl body:dict delegate:delegate type:type];
}

//异步请求队列管理
-(void)connectQueue:(NSString*)strUrl body:(NSDictionary*)body delegate:(id<ResponseDelegate>)delegate type:(NSInteger)type {
    if (![self.urlSet containsObject:strUrl]) {
        [self.urlSet addObject:strUrl];
        [self.urlQueue addObject:strUrl];
    }
    if ([self.urlQueue count] > 0) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSData *respData = nil;
            if (body) {
                //有body数据，发post请求
                respData = [self postSynConnectWithURL:strUrl body:body];
            }else{
                //无body数据，发get请求
                respData = [self getSynConnectWithURL:strUrl];
            }
            if (respData) {
                NSDictionary *json = [self jsonData:respData];
                if (delegate && [delegate respondsToSelector:@selector(responseDate:Type:)]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        //主线程中回调异步请求
                        [delegate responseDate:json Type:type];
                        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(removeURlSetWithTimer:) userInfo:strUrl repeats:NO];
                        [self.urlQueue removeObject:strUrl];
                    });
                }
            }

        });
        
    }
}

//定时清理请求的url
- (void)removeURlSetWithTimer:(NSTimer*)timer{
    NSString *url = [timer userInfo];
    
    NSLog(@"remove itmer %@",url);
    [self.urlSet removeObject:url];
}


//格式化post的内容
-(NSData*)postBodyWithDict:(NSDictionary*)dict{
    NSMutableData *body = [[NSMutableData alloc] init];
//    [body appendData:[self stringToData:ENDCHAR]];
    if ([@"&" isEqualToString:BOUNDARY]) {
        NSString *strBody = @"";
        for (NSString*key in [dict allKeys]) {
            NSString *strNew = [NSString stringWithFormat:@"%@=%@",key,[dict objectForKey:key]];
            strBody = [strBody stringByAppendingString:strNew];
            strBody = [strBody stringByAppendingString:[@"--" stringByAppendingString:BOUNDARY]];
        }
        strBody = [strBody substringToIndex:[strBody length]-1];
        [body appendData:[self stringToData:strBody]];
    }else{
        for (NSString*key in [dict allKeys]) {
            [body appendData:[self stringToData:[@"--" stringByAppendingString:BOUNDARY]]];
            [body appendData:[self stringToData:ENDCHAR]];
            
            NSString *bodyKey = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
            [body appendData:[self stringToData:bodyKey]];
            
            NSString *bodyValue = [dict objectForKey:key];
            [body appendData:[self stringToData:bodyValue]];//body Value
            
            [body appendData:[self stringToData:ENDCHAR]];
        }
//        [body appendData:[self stringToData:[NSString stringWithFormat:@"%@--\r\n",BOUNDARY]]];
    }
    
//    NSLog(@"%@",[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
    
    return body;
}

//文件下载
-(void)fileDownLoadWithURL:(NSString*)strUrl savePath:(NSString*)path saveFileName:(NSString*)fname {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *file = [self downLoadWithURL:strUrl];
        NSString* strLog = nil;
        if (file && path && [path length]>0) {
            NSArray *p = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentPath = [p objectAtIndex:0];
            NSString *docPath = [documentPath stringByAppendingPathComponent:path];
            NSString *filePath = [docPath stringByAppendingPathComponent:fname];
            BOOL isSave = [[NSFileManager defaultManager] createDirectoryAtPath:docPath withIntermediateDirectories:YES attributes:nil error:nil];
            isSave = [file writeToFile:filePath atomically:YES];
            if (isSave) {
                strLog = [NSString stringWithFormat:@"文件下载成功,文件以写入%@",filePath];
            }else{
                strLog = @"文件下载失败";
            }
        }else{
            strLog = @"文件下载失败";
        }
        NSLog(@"%@",strLog);
    });
}

// 数据下载,同步请求
-(NSData *)downLoadWithURL:(NSString *)strUrl{
    return [self getSynConnectWithURL:strUrl];
}

//上传文件,同步上传
-(BOOL)upLodeWithURL:(NSString*)strUrl body:(NSDictionary*)body file:(NSData*)fdata fileName:(NSString*)fname {
    
    if (!fname || [fname length] == 0) {
        fname = @"file.file";
    }
    
    NSURL *url = [[NSURL alloc] initWithString:strUrl];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    [data appendData:[self postBodyWithDict:body]];
//    [data appendData:[self stringToData:ENDCHAR]];
    [data appendData:[self stringToData:[@"--" stringByAppendingString:BOUNDARY]]];
    [data appendData:[self stringToData:ENDCHAR]];
//    [data appendData:[self stringToData:ENDCHAR]];
    NSString *imgName = @"Filedata";
    if ([strUrl hasPrefix:@"https://api.weibo.com"]) {
        imgName = @"pic";
    }
    
    [data appendData:[self stringToData:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", imgName, fname]]];
    [data appendData:[self stringToData:[NSString stringWithFormat:@"Content-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n", [self fileType:fname]]]];
    [data appendData:fdata];
    [data appendData:[self stringToData:ENDCHAR]];
    [data appendData:[self stringToData:[@"--" stringByAppendingString:BOUNDARY]]];
    [data appendData:[self stringToData:[@"--" stringByAppendingString:ENDCHAR]]];
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",str);
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc ]initWithURL:url];
    [req setTimeoutInterval:TimeOut];
    
    [req setHTTPMethod:POST];
    NSString *model = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY] ;
//    , @"Content-Length": [NSString stringWithFormat:@"%lu",(unsigned long)[data length]]
    NSDictionary *dict = @{@"Content-Type": model, @"Charset": @"UTF-8", @"Accept-Language": @"zh-CN,zh"};
    [req setAllHTTPHeaderFields:dict];
//    [req setHTTPShouldHandleCookies:NO];
//    NSInputStream *is = [[NSInputStream alloc] initWithData:data];
//    [req setHTTPBodyStream:is];//body数据
    [req setHTTPBody:data];
    NSError *err ;
    
    NSURLResponse *resp;
    NSData *respData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    
    if (err) {
        [self responseError:err];
    }
    NSDictionary *json = [self jsonData:respData];
    NSLog(@"json %@",json);
    return respData?YES:NO;
}
-(NSString*)fileType:(NSString*)fname{
    NSString*fType = @"application/octet-stream/";
    
    NSRange range = [fname rangeOfString:@"." options:NSBackwardsSearch];
    if (range.length > 0) {
        NSString* type = [fname substringFromIndex:range.location+1];
        type = [type lowercaseString];
        if ([@"png" isEqualToString:type] ||
            [@"jpg" isEqualToString:type] ||
            [@"jpeg" isEqualToString:type] ||
            [@"gif" isEqualToString:type]) {
            fType = [NSString stringWithFormat:@"image/%@",type];
        }else if ([@"mov" isEqualToString:type] ||
                  [@"mp4" isEqualToString:type] ||
                  [@"3gp" isEqualToString:type] ||
                  [@"mpeg4" isEqualToString:type] ||
                  [@"avi" isEqualToString:type] ||
                  [@"wmv" isEqualToString:type]){
            fType = [NSString stringWithFormat:@"video/%@",type];
        }else{
            fType = [NSString stringWithFormat:@"file/%@",type];
        }
    }
    return fType;
}
-(NSData*)stringToData:(NSString*)str{
//    NSString *unicodeStr = [NSString stringWithCString:[str UTF8String] encoding:NSUnicodeStringEncoding];
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

// 对字符串进行urlEncode处理
- (NSString*)urlEncodeWithUTFString:(NSString*)str{
    NSString *encode = [str stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    return encode?encode:str;
}
//请求出错处理
- (void) responseError:(NSError*)err{
    NSLog(@"error");
}
@end
