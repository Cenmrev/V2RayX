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
        [self setUseMkcp:[NSNumber numberWithBool:false]];

    }
    return self;
}

- (NSString*)description {
    return [[self dictionaryForm] description];
}

- (NSDictionary*)dictionaryForm {
    return @{@"address": address,
             @"port": [NSNumber numberWithInteger:port],
             @"userId": userId,
             @"alterId": [NSNumber numberWithInteger:alterId],
             @"remark": remark != nil ? remark : @"",
             @"allowPassive": allowPassive,
             @"useMkcp": useMkcp};
}

- (NSDictionary*)v2rayConfigWithLocalPort:(NSInteger)localPort
                               udpSupport:(BOOL)udp
                               v2rayRules:(BOOL)rules
{
    //generate config template
    NSMutableDictionary *config = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:rules?@"config-sample-rules":@"config-sample" ofType:@"plist"]];
    config[@"transport"] = [[NSUserDefaults standardUserDefaults] objectForKey:@"transportSettings"];
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
    if ([self.useMkcp boolValue] == true) {
        config[@"outbound"][@"streamSettings"] = @{@"network": @"kcp"};
    }
    return config;
}

@synthesize address;
@synthesize port;
@synthesize userId;
@synthesize alterId;
@synthesize remark;
@synthesize allowPassive;
@synthesize useMkcp;
@end
