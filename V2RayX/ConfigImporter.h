//
//  ConfigImporter.h
//  V2RayX
//
//

#import <Foundation/Foundation.h>
#import "ServerProfile.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigImporter : NSObject
+ (NSDictionary*)parseStandardSSLink:(NSString*)link;
+ (NSMutableDictionary*)ssOutboundFromSSLink:(NSString*)link;
+ (NSMutableDictionary*)ssOutboundFromSSConfig:(NSDictionary*)jsonObject;
+ (ServerProfile*)importFromVmessOfV2RayN:(NSString*)vmessStr;
+ (NSMutableDictionary*)importFromHTTPSubscription:(NSString*)httpLink;
+ (NSMutableDictionary*)importFromStandardConfigFiles:(NSArray*)files;
+ (NSMutableDictionary*)validateRuleSet:(NSMutableDictionary*)set;
+ (NSMutableDictionary* _Nonnull)importFromSubscriptionOfSSD: (NSString* _Nonnull)ssdLink;
@end

NS_ASSUME_NONNULL_END
