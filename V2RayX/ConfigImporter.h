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
+ (NSMutableDictionary*)importFromSubscriptionOfV2RayN:(NSString*)httpLink;
+ (NSMutableDictionary*)importFromStandardConfigFiles:(NSArray*)files;
+ (NSMutableDictionary*)validateRuleSet:(NSMutableDictionary*)set;
@end

NS_ASSUME_NONNULL_END
