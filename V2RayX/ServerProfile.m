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
        [self setPort:@10086];
        [self setUserId:@"23ad6b10-8d1a-40f7-8ad0-e3e35cd38297"];
        [self setAlterId:@64];
        [self setRemark:@"test server"];
        [self setAllowPassive:[NSNumber numberWithBool:false]];//does not allow passive as default
        [self setSecurity:@0]; //use aes-128-cfb as default
        [self setNetwork:@0];
    }
    return self;
}

- (NSString*)description {
    return [[self dictionaryForm] description];
}

- (NSDictionary*)dictionaryForm {
    return @{@"address": address != nil ? address : @"",
             @"port": port != nil ? port : @0,
             @"userId": userId != nil ? userId : @"",
             @"alterId": alterId != nil ? alterId : @0,
             @"remark": remark != nil ? remark : @"",
             @"allowPassive": allowPassive != nil ? allowPassive : [NSNumber numberWithBool:false],
             @"security": security != nil ? security : @0,
             @"network": network != nil ? network : @0};
}

- (NSDictionary*)v2rayConfigWithRules:(BOOL)rules
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //generate config template
    NSMutableDictionary *config = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:rules?@"config-sample-rules":@"config-sample" ofType:@"plist"]];
    config[@"inbound"][@"port"] = [userDefaults objectForKey:@"localPort"];
    config[@"inbound"][@"listen"] = [[userDefaults objectForKey:@"shareOverLan"] boolValue] ? @"0.0.0.0" : @"127.0.0.1";
    config[@"inbound"][@"settings"][@"udp"] = config[@"udpSupport"];
    config[@"inbound"][@"allowPassive"] = [self allowPassive];
    config[@"outbound"][@"settings"][@"vnext"][0][@"address"] = self.address;
    config[@"outbound"][@"settings"][@"vnext"][0][@"port"] = self.port;
    config[@"outbound"][@"settings"][@"vnext"][0][@"users"][0][@"id"] = self.userId;
    config[@"outbound"][@"settings"][@"vnext"][0][@"users"][0][@"alterId"] = self.alterId;
    config[@"outbound"][@"settings"][@"vnext"][0][@"users"][0][@"security"] = @[@"aes-128-cfb", @"aes-128-gcm", @"chacha20-poly1305"][self.security.integerValue % 3];
    NSMutableDictionary* streamSettings = [[userDefaults objectForKey:@"transportSettings"] mutableCopy];
    streamSettings[@"network"] = @[@"tcp", @"kcp", @"ws"][self.network.integerValue % 3];
    streamSettings[@"security"] = [[userDefaults objectForKey:@"useTLS"] boolValue] ? @"tls" : @"none";
    streamSettings[@"tlsSettings"] = [userDefaults objectForKey:@"tlsSettings"];
    config[@"outbound"][@"streamSettings"] = streamSettings;
    NSArray* dnsArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dns"] componentsSeparatedByString:@","];
    if ([dnsArray count] > 0) {
        config[@"dns"][@"servers"] = dnsArray;
    } else {
        config[@"dns"][@"servers"] = @[@"localhost"];
    }
    return config;
}

@synthesize address;
@synthesize port;
@synthesize userId;
@synthesize alterId;
@synthesize remark;
@synthesize security;
@synthesize allowPassive;
@synthesize network;
@end
