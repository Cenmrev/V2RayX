//
//  ServerProfile.h
//  V2RayX
//
//  Copyright © 2016年 Project V2Ray. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerProfile : NSObject
- (NSArray*)toArray;
- (NSDictionary*)dictionaryForm;
- (NSDictionary*)v2rayConfigWithLocalPort:(NSInteger)localPort
                               udpSupport:(BOOL)udp
                               v2rayRules:(BOOL)rules;
@property (nonatomic) NSString* address;
@property (nonatomic) NSInteger port;
@property (nonatomic) NSString* userId;
@property (nonatomic) NSInteger alterId;
@property (nonatomic) NSString* remark;
@property (nonatomic) NSNumber* allowPassive;
@end
