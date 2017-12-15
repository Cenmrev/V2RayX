//
//  ServerProfile.m
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import "ServerProfile.h"


@implementation ServerProfile

- (ServerProfile*)init {
    self = [super init];
    if (self) {
        // use v2ray public server as default
        [self setAddress:@"v2ray.cool"];
        [self setPort:10086];
        [self setUserId:@"23ad6b10-8d1a-40f7-8ad0-e3e35cd38287"];
        [self setAlterId:64];
        [self setLevel:0];
        [self setRemark:@"test server"];
        [self setSecurity:aes_128_cfb];
        [self setNetwork:tcp];
        [self setSendThrough:@"0.0.0.0"];
        [self setStreamSettings:@{
                                  @"security": @"none",
                                  @"tlsSettings": @{
                                          @"serverName": @"v2ray.com",
                                          @"allowInsecure": [NSNumber numberWithBool:NO]
                                          },
                                  @"tcpSettings": @{
                                          @"header": @{
                                                  @"type": @"none"
                                                  }
                                          },
                                  @"kcpSettings": @{
                                          @"mtu": @1350,
                                          @"tti": @20,
                                          @"uplinkCapacity": @5,
                                          @"downlinkCapacity": @20,
                                          @"congestion": [NSNumber numberWithBool:NO],
                                          @"readBufferSize": @1,
                                          @"writeBufferSize": @1,
                                          @"header": @{
                                                  @"type": @"none"
                                                  }
                                          },
                                  @"wsSettings": @{
                                          @"path": @"",
                                          @"headers": @{
                                                  @"Host": @"v2ray.com"
                                                  }
                                          }
                                  }];
        [self setProxySettings:@{}];
        [self setMuxSettings:@{
                               @"enabled": [NSNumber numberWithBool:NO],
                               @"concurrency": @8
                               }];
    }
    return self;
}

- (NSString*)description {
    return [[self outboundProfile] description];
}

+ (ServerProfile*)readFromAnOutboundDic:(NSDictionary*)outDict {
    NSDictionary *netWorkDict = @{@"tcp": @0, @"kcp": @1, @"ws":@2 };
    NSDictionary *securityDict = @{@"aes-128-cfb":@0, @"aes-128-gcm":@1, @"chacha20-poly1305":@2, @"auto":@3};
    
    ServerProfile* profile = [[ServerProfile alloc] init];
    profile.sendThrough = nilCoalescing(outDict[@"sendThrough"], @"0.0.0.0");
    profile.address = nilCoalescing(outDict[@"settings"][@"vnext"][0][@"address"], @"127.0.0.1");
    profile.remark = nilCoalescing(outDict[@"settings"][@"vnext"][0][@"remark"], @"");
    profile.port = [outDict[@"settings"][@"vnext"][0][@"port"] unsignedIntegerValue];
    profile.userId = nilCoalescing(outDict[@"settings"][@"vnext"][0][@"users"][0][@"id"], @"23ad6b10-8d1a-40f7-8ad0-e3e35cd38287");
    
    profile.alterId = [outDict[@"settings"][@"vnext"][0][@"users"][0][@"alterId"] unsignedIntegerValue];
    profile.level = [outDict[@"settings"][@"vnext"][0][@"users"][0][@"level"] unsignedIntegerValue];
    profile.security = [securityDict[outDict[@"settings"][@"vnext"][0][@"users"][0][@"security"]] unsignedIntegerValue];
    profile.network = [netWorkDict[outDict[@"streamSettings"][@"network"]] unsignedIntegerValue];
    profile.streamSettings = nilCoalescing(outDict[@"streamSettings"], @{});
    profile.proxySettings = nilCoalescing(outDict[@"proxySettings"], @{});
    profile.muxSettings = nilCoalescing(outDict[@"setMuxSettings"], @{});
    
    return profile;
}

- (NSDictionary*)outboundProfile {
    NSMutableDictionary* fullStreamSettings = [NSMutableDictionary dictionaryWithDictionary:streamSettings];
    fullStreamSettings[@"network"] = @[@"tcp",@"kcp", @"ws"][network];
    return @{
             @"sendThrough": sendThrough,
             @"protocol": @"vmess",
             @"settings": @{
                     @"vnext": @[
                             @{
                                 @"remark": nilCoalescing(remark, @""),
                                 @"address": nilCoalescing([address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] , @""),
                                 @"port": [NSNumber numberWithUnsignedInteger:port],
                                 @"users": @[
                                         @{
                                             @"id": userId != nil ? [userId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]: @"",
                                             @"alterId": [NSNumber numberWithUnsignedInteger:alterId],
                                             @"security": @[@"aes-128-cfb", @"aes-128-gcm", @"chacha20-poly1305", @"auto"][security],
                                             @"level": [NSNumber numberWithUnsignedInteger:level]
                                             }
                                         ]
                                 }
                             ]
                     },
             @"streamSettings": fullStreamSettings,
             //@"proxySettings": proxySettings, //currently does not support
             @"mux": muxSettings,
             };
}

@synthesize address;
@synthesize port;
@synthesize userId;
@synthesize alterId;
@synthesize level;
@synthesize remark;
@synthesize security;
@synthesize network;
@synthesize sendThrough;
@synthesize muxSettings;
@synthesize streamSettings;
@synthesize proxySettings;
@end
