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
        [self setAddress:@"v2ray.cool"];
        [self setPort:10086];
        [self setUserId:@"23ad6b10-8d1a-40f7-8ad0-e3e35cd38297"];
        [self setAlterId:64];
        [self setRemark:@"test server"];
        [self setUseKCP:false];
    }
    return self;
}

- (NSString*)description {
    return [[self toArray] description];
}

- (NSArray*)toArray {
    return @[address,[NSNumber numberWithInteger:port], userId, [NSNumber numberWithInteger:alterId], remark, [NSNumber numberWithBool:useKCP]];
}

- (NSDictionary*)dictionaryForm {
    return @{@"address": address,
             @"port": [NSNumber numberWithInteger:port],
             @"userId": userId,
             @"alterId": [NSNumber numberWithInteger:alterId],
             @"remark": remark,
             @"useKCP": [NSNumber numberWithBool:useKCP]};
}

- (NSDictionary*)v2rayConfigWithLocalPort:(NSInteger)localPort udpSupport:(BOOL)udp {
    //generate config template
    NSMutableDictionary *config = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"config-sample" ofType:@"plist"]];
    
    config[@"inbound"][@"port"] = [NSNumber numberWithInteger:localPort];
    config[@"inbound"][@"settings"][@"udp"] = [NSNumber numberWithBool:udp];
    config[@"outbound"][@"settings"][@"vnext"][0][@"address"] = self.address;
    config[@"outbound"][@"settings"][@"vnext"][0][@"port"] = [NSNumber numberWithInteger:self.port];
    config[@"outbound"][@"settings"][@"vnext"][0][@"users"][0][@"id"] = self.userId;
    if(self.useKCP){
        config[@"outbound"][@"streamSettings"][@"network"] = @"kcp";
    }else{
        config[@"outbound"][@"streamSettings"][@"network"] = @"tcp";
    }
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
@synthesize useKCP;

@end
