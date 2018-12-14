//
//  ServerProfile.h
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#define OBFU_LIST (@[@"none", @"srtp", @"utp", @"wechat-video", @"dtls", @"wireguard"])
#define VMESS_SECURITY_LIST (@[@"aes-128-gcm", @"chacha20-poly1305", @"auto", @"none"])
#define NETWORK_LIST (@[@"tcp", @"kcp", @"ws", @"http", @"domainsocket", @"quic"])
#define QUIC_SECURITY_LIST (@[@"none", @"aes-128-gcm", @"chacha20-poly1305"])

typedef enum SecurityType : NSUInteger {
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
    quic
} NetWorkType;

@interface ServerProfile : NSObject
- (NSMutableDictionary*)outboundProfile;
+ (ServerProfile* _Nullable )readFromAnOutboundDic:(NSDictionary*)outDict;
+ (NSArray*)profilesFromJson:(NSDictionary*)outboundJson;
+(NSUInteger)searchString:(NSString*)str inArray:(NSArray*)array;
-(ServerProfile*)deepCopy;

@property (nonatomic) NSString* address;
@property (nonatomic) NSUInteger port;
@property (nonatomic) NSString* userId;
@property (nonatomic) NSUInteger alterId;
@property (nonatomic) NSUInteger level;
@property (nonatomic) NSString* remark;
@property (nonatomic) SecurityType security;
@property (nonatomic) NetWorkType network;
@property (nonatomic) NSString* sendThrough;
@property (nonatomic) NSDictionary* streamSettings; // except network type.
@property (nonatomic) NSDictionary* muxSettings;
@end
