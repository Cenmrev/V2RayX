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
        [self setAddress:@"195.154.64.131"];
        [self setPort:17173];
        [self setUserId:@"1ad52bdc-16d1-41a5-811d-f5c0c76d677b"];
        [self setAlterId:1024];
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
