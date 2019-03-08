//
//  utilities.h
//  V2RayX
//
//

#ifndef utilities_h
#define utilities_h

#import <Cocoa/Cocoa.h>
#import "MutableDeepCopying.h"

#define DOMAIN_STRATEGY_LIST (@[@"AsIs", @"IPIfNonMatch", @"IPOnDemand"])
#define ROUTING_NETWORK_LIST (@[@"tcp", @"udp", @"tcp,udp"])

#define OBFU_LIST (@[@"none", @"srtp", @"utp", @"wechat-video", @"dtls", @"wireguard"])
#define VMESS_SECURITY_LIST (@[@"auto", @"aes-128-gcm", @"chacha20-poly1305", @"none"])
#define NETWORK_LIST (@[@"tcp", @"kcp", @"ws", @"http", @"quic"])
#define QUIC_SECURITY_LIST (@[@"none", @"aes-128-gcm", @"chacha20-poly1305"])
#define nilCoalescing(a,b) ( (a != nil) ? (a) : (b) ) // equivalent to ?? operator in Swift

#define TCP_NONE_HEADER_OBJECT (@"{\"type\": \"none\"}")

#define ROUTING_DIRECT (@{@"name": @"all_to_direct",@"domainStrategy": @"AsIs",@"rules": @[@{@"type": @"field",@"port": @"0-65535",@"outboundTag": @"direct"}]})
#define ROUTING_GLOBAL (@{@"name": @"all_to_main",@"domainStrategy": @"AsIs",@"rules": @[@{@"type": @"field",@"port": @"0-65535",@"outboundTag": @"main"}]})
#define ROUTING_BYPASSCN_PRIVATE_APPLE (@{@"name": @"bypasscn_private_apple",@"domainStrategy":@"IPIfNonMatch",@"rules":@[@{@"domain":@[@"localhost",@"domain:me.com",@"domain:lookup-api.apple.com",@"domain:icloud-content.com",@"domain:icloud.com",@"domain:cdn-apple.com",@"domain:apple-cloudkit.com",@"domain:apple.com",@"domain:apple.co",@"domain:aaplimg.com",@"domain:guzzoni.apple.com",@"geosite:cn"],@"type":@"field",@"outboundTag":@"direct"},@{@"type":@"field",@"outboundTag":@"direct",@"ip":@[@"geoip:private",@"geoip:cn"]},@{@"type":@"field",@"outboundTag":@"main",@"port":@"0-65535"}]})

#define OUTBOUND_DIRECT (@{@"protocol":@"freedom",@"tag":@"direct",@"settings":@{}})
#define OUTBOUND_DECLINE (@{@"protocol":@"blackhole",@"tag":@"decline",@"settings": @{}})

#define RESERVED_TAGS (@[@"main", @"direct", @"decline", @"balance"])

#define SUPPORTED_SS_SECURITY (@[@"aes-256-cfb",@"aes-128-cfb",@"chacha20",@"chacha20-ietf",@"aes-256-gcm",@"aes-128-gcm",@"chacha20-poly1305", @"chacha20-ietf-poly1305"])

#define EMPTY_DICT ([[NSMutableDictionary alloc] init])
#define EMPTY_IMPORT_RESULT ([@{@"vmess": @[], @"other": @[], @"rules":@[]} mutableDeepCopy])
#define SNIFFING_PROTOCOL (@[@"http", @"tls", @"bittorrent"])


#define NOT_SUPPORTED_ROUTING (@[@"source", @"user"])
#define SUPPORTED_ROUTING (@[@"domain", @"ip", @"network", @"port", @"inboundTag", @"protocol"])

NSUInteger searchInArray(NSString* str, NSArray* array);


#endif /* utilities_h */
