//
//  ServerProfile.m
//  V2RayX
//
//  Copyright © 2016年 Project V2Ray. All rights reserved.
//

#import "ServerProfile.h"

@implementation ServerProfile

- (ServerProfile*)init {
    self = [super init];
    if (self) {
        // use v2ray public server as default
        [self setAddress:@"45.32.24.103"];
        [self setPort:38291];
        [self setUserId:@"8833948b-5861-4a0f-a1d6-83c5606881ff"];
        [self setAlterId:64];
        [self setRemark:@""];
    }
    return self;
}

- (NSString*)description {
    return [[self toArray] description];
}

- (NSArray*)toArray {
    return @[address,[NSNumber numberWithInteger:port], userId, [NSNumber numberWithInteger:alterId], remark];
}

- (NSDictionary*)v2rayConfigWithLocalPort:(NSInteger)localPort udpSupport:(BOOL)udp {
    //generate config template
    NSMutableDictionary *config = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"config-sample" ofType:@"plist"]];
    
    config[@"port"] = [NSNumber numberWithInteger:localPort];
    config[@"inbound"][@"settings"][@"udp"] = [NSNumber numberWithBool:udp];
    config[@"outbound"][@"settings"][@"vnext"][0][@"address"] = self.address;
    config[@"outbound"][@"settings"][@"vnext"][0][@"port"] = [NSNumber numberWithInteger:self.port];
    config[@"outbound"][@"settings"][@"vnext"][0][@"users"][0][@"id"] = self.userId;
    if (self.alterId > 0) {
        config[@"outbound"][@"settings"][@"vnext"][0][@"users"][0][@"alterId"] = [NSNumber numberWithInteger:alterId];
    } else {
        [config[@"outbound"][@"settings"][@"vnext"][0][@"users"][0] removeObjectForKey:@"alterId"];
    }
    return config;
}

@synthesize address;
@synthesize port;
@synthesize userId;
@synthesize alterId;
@synthesize remark;

@end
