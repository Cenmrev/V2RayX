//
//  ServerProfile.h
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

typedef enum SecurityType : NSUInteger {
    aes_128_cfb,
    aes_128_gcm,
    chacha20_poly130,
    auto_,
    none
} SecurityType;

typedef enum NetWorkType : NSUInteger {
    tcp,
    kcp,
    ws,
    http,
} NetWorkType;

@interface ServerProfile : NSObject
- (NSMutableDictionary*)outboundProfile;
+ (ServerProfile*)readFromAnOutboundDic:(NSDictionary*)outDict;
@property (nonatomic) NSString* address;
@property (nonatomic) NSUInteger port;
@property (nonatomic) NSString* userId;
@property (nonatomic) NSUInteger alterId;
@property (nonatomic) NSUInteger level;
@property (nonatomic) NSString* remark;
@property (nonatomic) SecurityType security;
@property (nonatomic) NetWorkType network;
@property (nonatomic) NSString* sendThrough;
@property (nonatomic) NSDictionary* streamSettings; // exclude network type.
@property (nonatomic) NSDictionary* proxySettings;
@property (nonatomic) NSDictionary* muxSettings;
@end
