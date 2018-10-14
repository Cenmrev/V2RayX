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
        [self setAddress:@"server.cc"];
        [self setPort:10086];
        [self setUserId:@"00000000-0000-0000-0000-000000000000"];
        [self setAlterId:64];
        [self setLevel:0];
        [self setRemark:@"test server"];
        [self setSecurity:auto_];
        [self setNetwork:tcp];
        [self setSendThrough:@"0.0.0.0"];
        [self setStreamSettings:@{
                                  @"security": @"none",
                                  @"tlsSettings": @{
                                          @"serverName": @"server.cc",
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
                                                  @"Host": @"server.cc"
                                                  }
                                          },
                                  @"httpSettings": @{
                                          @"host": @[@"server.cc"],
                                          @"path": @""
                                        }
                                  }];
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

+ (NSArray*)profilesFromJson:(NSDictionary*)outboundJson {
    if (![outboundJson[@"protocol"] isKindOfClass:[NSString class]]
        || ![outboundJson[@"protocol"] isEqualToString:@"vmess"] ) {
        return @[];
    }
    NSMutableArray* profiles = [[NSMutableArray alloc] init];
    NSDictionary *netWorkDict = @{@"tcp": @0, @"kcp": @1, @"ws":@2, @"http":@3 };
    NSDictionary *securityDict = @{@"aes-128-cfb":@0, @"aes-128-gcm":@1, @"chacha20-poly1305":@2, @"auto":@3, @"none":@4};
    NSString* sendThrough = nilCoalescing(outboundJson[@"sendThrough"], @"0.0.0.0");
    if (![[outboundJson valueForKeyPath:@"settings.vnext"] isKindOfClass:[NSArray class]]) {
        return @[];
    }
    for (NSDictionary* vnext in [outboundJson valueForKeyPath:@"settings.vnext"]) {
        ServerProfile* profile = [[ServerProfile alloc] init];
        profile.address = nilCoalescing(vnext[@"address"], @"127.0.0.1");
        profile.remark = nilCoalescing(vnext[@"remark"], @"");
        profile.port = [vnext[@"port"] unsignedIntegerValue];
        if (![vnext[@"users"] isKindOfClass:[NSArray class]] || [vnext[@"users"] count] == 0) {
            continue;
        }
        profile.userId = nilCoalescing(vnext[@"users"][0][@"id"], @"23ad6b10-8d1a-40f7-8ad0-e3e35cd38287");
        profile.alterId = [vnext[@"users"][0][@"alterId"] unsignedIntegerValue];
        profile.level = [vnext[@"users"][0][@"level"] unsignedIntegerValue];
        profile.security = [securityDict[vnext[@"users"][0][@"security"]] unsignedIntegerValue];
        if (outboundJson[@"streamSettings"] != nil) {
            profile.streamSettings = outboundJson[@"streamSettings"];
            profile.network = [netWorkDict[outboundJson[@"streamSettings"][@"network"]] unsignedIntegerValue];
        }
        if (outboundJson[@"mux"] != nil) {
            profile.muxSettings = outboundJson[@"mux"];
        }
        profile.sendThrough = sendThrough;
        [profiles addObject:profile];
    }
    return profiles;
}

+ (ServerProfile* _Nullable )readFromAnOutboundDic:(NSDictionary*)outDict {
    NSArray *allProfiles = [self profilesFromJson:outDict];
    if ([allProfiles count] > 0) {
        return allProfiles[0];
    } else {
        return NULL;
    }
}

-(ServerProfile*)deepCopy {
    ServerProfile* aCopy = [[ServerProfile alloc] init];
    aCopy.address = [NSString stringWithString:nilCoalescing(self.address, @"")];
    aCopy.port = self.port;
    aCopy.userId = [NSString stringWithString:nilCoalescing(self.userId, @"")];
    aCopy.alterId = self.alterId;
    aCopy.level = self.level;
    aCopy.remark = [NSString stringWithString:nilCoalescing(self.remark, @"")];
    aCopy.security = self.security;
    aCopy.network = self.network;
    aCopy.sendThrough = [NSString stringWithString:nilCoalescing(self.sendThrough, @"")];
    aCopy.streamSettings = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.streamSettings]];
    aCopy.muxSettings = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.muxSettings]];
    return aCopy;
}

- (NSMutableDictionary*)outboundProfile {
    NSMutableDictionary* fullStreamSettings = [NSMutableDictionary dictionaryWithDictionary:streamSettings];
    fullStreamSettings[@"network"] = @[@"tcp",@"kcp", @"ws", @"http"][network];
    NSDictionary* result =
    @{
      @"sendThrough": sendThrough,
      @"protocol": @"vmess",
      @"settings": [@{
              @"vnext": @[
                      @{
                          @"remark": nilCoalescing(remark, @""),
                          @"address": nilCoalescing([address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] , @""),
                          @"port": [NSNumber numberWithUnsignedInteger:port],
                          @"users": @[
                                  @{
                                      @"id": userId != nil ? [userId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]: @"",
                                      @"alterId": [NSNumber numberWithUnsignedInteger:alterId],
                                      @"security": @[@"aes-128-cfb", @"aes-128-gcm", @"chacha20-poly1305", @"auto", @"none"][security],
                                      @"level": [NSNumber numberWithUnsignedInteger:level]
                                      }
                                  ]
                          }
                      ]
              } mutableCopy],
      @"streamSettings": fullStreamSettings,
      @"mux": muxSettings,
      };
    return [result mutableCopy];
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
@end
