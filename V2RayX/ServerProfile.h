//
//  ServerProfile.h
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerProfile : NSObject
- (NSDictionary*)dictionaryForm;
- (NSDictionary*)v2rayConfigWithRules:(BOOL)rules;
@property (nonatomic) NSString* address;
@property (nonatomic) NSNumber* port;
@property (nonatomic) NSString* userId;
@property (nonatomic) NSNumber* alterId;
@property (nonatomic) NSString* remark;
@property (nonatomic) NSNumber* security; //0:aes-128-cfb, 1:aes-128-gcm, 2:chacha20-poly1305
@property (nonatomic) NSNumber* network; //0:tcp, 1:kcp, 2:ws
@end
