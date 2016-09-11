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
        [self setAllowPassive:[NSNumber numberWithBool:false]];//does not allow passive as default
    }
    return self;
}

- (NSString*)description {
    return [[self toArray] description];
}

- (NSArray*)toArray {
    return @[address,[NSNumber numberWithInteger:port], userId, [NSNumber numberWithInteger:alterId], remark];
}

- (NSDictionary*)dictionaryForm {
    return @{@"address": address,
             @"port": [NSNumber numberWithInteger:port],
             @"userId": userId,
             @"alterId": [NSNumber numberWithInteger:alterId],
             @"remark": remark,
             @"allowPassive": allowPassive};
}
/*
[newProfile setAddress:aProfile[@"address"]];
[newProfile setPort:[aProfile[@"port"] integerValue]];
[newProfile setUserId:aProfile[@"userId"]];
[newProfile setAlterId:[aProfile[@"alterId"] integerValue]];
[newProfile setRemark:aProfile[@"remark"]];
*/
- (NSDictionary*)v2rayConfigWithLocalPort:(NSInteger)localPort udpSupport:(BOOL)udp {
    //generate config template
    NSMutableDictionary *config = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"config-sample" ofType:@"plist"]];
    
    config[@"inbound"][@"port"] = [NSNumber numberWithInteger:localPort];
    config[@"inbound"][@"settings"][@"udp"] = [NSNumber numberWithBool:udp];
    config[@"inbound"][@"allowPassive"] = [self allowPassive];
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
@synthesize allowPassive;
@end
