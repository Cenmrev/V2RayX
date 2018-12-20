//
//  utilities.h
//  V2RayX
//
//

#ifndef utilities_h
#define utilities_h

#import <Cocoa/Cocoa.h>

#define OBFU_LIST (@[@"none", @"srtp", @"utp", @"wechat-video", @"dtls", @"wireguard"])
#define VMESS_SECURITY_LIST (@[@"auto", @"aes-128-gcm", @"chacha20-poly1305", @"none"])
#define NETWORK_LIST (@[@"tcp", @"kcp", @"ws", @"http", @"quic"])
#define QUIC_SECURITY_LIST (@[@"none", @"aes-128-gcm", @"chacha20-poly1305"])
#define nilCoalescing(a,b) ( (a != nil) ? (a) : (b) ) // equivalent to ?? operator in Swift

#define TCP_NONE_HEADER_OBJECT (@"{\"type\": \"none\"}")

NSUInteger searchInArray(NSString* str, NSArray* array);


#endif /* utilities_h */
