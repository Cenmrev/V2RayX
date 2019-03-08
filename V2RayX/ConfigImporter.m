//
//  ConfigImporter.m
//  V2RayX
//
//

#import "ConfigImporter.h"
#import "utilities.h"

@implementation ConfigImporter

+ (NSString* _Nonnull)decodeBase64String:(NSString*)encoded {
    if (!encoded || ![encoded isKindOfClass:[NSString class]] || encoded.length == 0) {
        return @"";
    }
    NSMutableString* fixed = [encoded mutableCopy];
    NSInteger numAdd = (4 - encoded.length % 4) % 4;
    for (int i = 0; i < numAdd; i += 1) {
        [fixed appendString:@"="];
    }
    @try {
        NSData* decodedData = [[NSData alloc] initWithBase64EncodedString:fixed options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSString* decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        assert(decodedString != nil);
        return decodedString;
    } @catch (NSException *exception) {
        return @"";
    }
}

+ (NSDictionary*)parseLegacySSLink:(NSString*)link {
    //http://shadowsocks.org/en/config/quick-guide.html
    @try {
        NSString* encoded = [[link stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] substringFromIndex:5];
        NSArray* hashTagSeperatedParts = [encoded componentsSeparatedByString:@"#"];
        NSString* encodedRemoveTag = hashTagSeperatedParts[0];
        NSString* decoded = [ConfigImporter decodeBase64String:encodedRemoveTag];
        NSArray* parts = [decoded componentsSeparatedByString:@"@"];
        NSArray* addressAndPort = [parts[1] componentsSeparatedByString:@":"];
        NSMutableArray* methodAndPassword = [[parts[0] componentsSeparatedByString:@":"] mutableCopy];
        NSString* method = methodAndPassword[0];
        [methodAndPassword removeObjectAtIndex:0];
        
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *port = [f numberFromString:addressAndPort[1]];
        
        if (hashTagSeperatedParts.count == 1) {
            return @{
                     @"server":addressAndPort[0],
                     @"server_port":port,
                     @"password": [methodAndPassword componentsJoinedByString:@":"],
                     @"method":method};
        } else {
            return @{
                     @"server":addressAndPort[0],
                     @"server_port":port,
                     @"password": [methodAndPassword componentsJoinedByString:@":"],
                     @"method":method,
                     @"tag":hashTagSeperatedParts[1]
                     };
        }
    } @catch (NSException *exception) {
        return nil;
    }
}


+ (NSDictionary*)parseStandardSSLink:(NSString*)link {
    //https://shadowsocks.org/en/spec/SIP002-URI-Scheme.html
    if (![@"ss://" isEqualToString: [link substringToIndex:5]]) {
        return nil;
    }
    @try {
        NSURL* ssurl = [[NSURL alloc] initWithString:link];
        NSNumber* enableOTA;
        if ([@"ota=false" isEqualToString:[ssurl.query lowercaseString]]) {
            enableOTA = @(NO);
        } else if ([@"ota=true" isEqualToString:[ssurl.query lowercaseString]]) {
            enableOTA = @(YES);
        } else if (ssurl.query.length > 0) {
            return nil; // only support ota
        }
        NSString* userinfoDecoded = [ConfigImporter decodeBase64String:ssurl.user];
        NSArray* userinfo = [userinfoDecoded componentsSeparatedByString:@":"];
        if(enableOTA == nil) {
            return @{
                     @"server":ssurl.host,
                     @"server_port":ssurl.port,
                     @"password": userinfo[1],
                     @"method":userinfo[0],
                     @"tag":ssurl.fragment
                     };
        } else {
            return @{
                     @"server":ssurl.host,
                     @"server_port":ssurl.port,
                     @"password": userinfo[1],
                     @"method":userinfo[0],
                     @"tag":ssurl.fragment,
                     @"ota":enableOTA
                     };
        }
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        return nil;
    }
}

+ (NSMutableDictionary* )ssOutboundFromSSLink:(NSString*)link {
    NSDictionary* parsed = [ConfigImporter parseStandardSSLink:link];
    if (parsed) {
        return [ConfigImporter ssOutboundFromSSConfig:parsed];
    } else {
        parsed = [ConfigImporter parseLegacySSLink:link];
        if (parsed) {
            return [ConfigImporter ssOutboundFromSSConfig:parsed];
        }
    }
    return nil;
}

+ (NSMutableDictionary*)ssOutboundFromSSConfig:(NSDictionary*)jsonObject {
    if (jsonObject && jsonObject[@"server"] && jsonObject[@"server_port"] && jsonObject[@"password"] && jsonObject[@"method"] && [SUPPORTED_SS_SECURITY indexOfObject:jsonObject[@"method"]] != NSNotFound) {
        NSMutableDictionary* ssOutbound =
        [@{
             @"sendThrough": @"0.0.0.0",
             @"protocol": @"shadowsocks",
             @"settings": @{
                     @"servers": @[
                             @{
                                 @"address": jsonObject[@"server"],
                                 @"port": jsonObject[@"server_port"],
                                 @"method": jsonObject[@"method"],
                                 @"password": jsonObject[@"password"],
                                 }
                             ]
                     },
             @"tag": [NSString stringWithFormat:@"%@:%@",jsonObject[@"server"],jsonObject[@"server_port"]],
             @"streamSettings": @{},
             @"mux": @{}
         } mutableDeepCopy];
        if (jsonObject[@"ota"]) {
            ssOutbound[@"settings"][@"servers"][0][@"ota"] = jsonObject[@"ota"];
        }
        if (jsonObject[@"tag"] && [jsonObject[@"tag"] isKindOfClass:[NSString class]] && [jsonObject[@"tag"] length] ) {
            ssOutbound[@"tag"] = jsonObject[@"tag"];
        }
        if ([jsonObject[@"fast_open"] isKindOfClass:[NSNumber class]]) {
            ssOutbound[@"streamSettings"] =[@{ @"sockopt": @{
                                                       @"tcpFastOpen": jsonObject[@"fast_open"]
                                                       }} mutableDeepCopy];
        }
        return ssOutbound;
    }
    return nil;
}

+ (NSMutableDictionary*)validateRuleSet:(NSMutableDictionary*)set {
    if (![set isKindOfClass:[NSMutableDictionary class]]) {
        NSLog(@"not a mutable dictionary class, %@", [set className]);
        return nil;
    }
    if (!set[@"rules"] || ![set[@"rules"] isKindOfClass:[NSMutableArray class]] || ![set count] ) {
        NSLog(@"no rules");
        return  nil;
    }
    if (![@"0-65535" isEqualToString: [set[@"rules"] lastObject][@"port"]]) {
        NSMutableDictionary *lastRule = [@{
                                           @"type" : @"field",
                                           @"outboundTag" : @"main",
                                           @"port" : @"0-65535"
                                           } mutableDeepCopy];
        [set[@"rules"] addObject:lastRule];
    }
    NSMutableArray* ruleToRemove = [[NSMutableArray alloc] init];
    NSArray* notSupported = NOT_SUPPORTED_ROUTING;
    NSArray* supported = SUPPORTED_ROUTING;
    // currently, source/user/inboundTag/protocol are not supported
    for (NSMutableDictionary* aRule in set[@"rules"]) {
        [aRule removeObjectsForKeys:notSupported];
        BOOL shouldRemove = true;
        for (NSString* supportedKey in supported) {
            if (aRule[supportedKey]) {
                shouldRemove = false;
                break;
            }
        }
        if (shouldRemove) {
            [ruleToRemove addObject:aRule];
            continue;
        }
        aRule[@"type"] = @"field";
        if (!aRule[@"outboundTag"] && !aRule[@"balancerTag"]) {
            aRule[@"outboundTag"] = @"main";
        }
        if (aRule[@"outboundTag"] && aRule[@"balancerTag"]) {
            [aRule removeObjectForKey:@"balancerTag"];
        }
    }
    for (NSMutableDictionary* aRule in ruleToRemove) {
        [set[@"rules"] removeObject:aRule];
    }
    if (!set[@"name"]) {
        set[@"name"] = @"some rule set";
    }
    return set;
}

+ (NSMutableDictionary*)importFromStandardConfigFiles:(NSArray*)files {
    NSMutableDictionary* result = [@{@"vmess": @[], @"other": @[], @"rules":@[]} mutableDeepCopy];
    for (NSURL* file in files) {
        NSError* error;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:
                         [NSData dataWithContentsOfURL:file] options:0 error:&error];
        if (error) continue;
        if (![jsonObject isKindOfClass:[NSDictionary class]]) continue;
        NSMutableArray* outboundJSONs = [[NSMutableArray alloc] init];
        NSMutableArray* routingJSONs = [[NSMutableArray alloc] init];
        if ([[jsonObject objectForKey:@"outbound"] isKindOfClass:[NSDictionary class]]) {
            [outboundJSONs addObject:jsonObject[@"outbound"]];
        }
        if ([[jsonObject objectForKey:@"outboundDetour"] isKindOfClass:[NSArray class]]) {
            [outboundJSONs addObjectsFromArray:jsonObject[@"outboundDetour"]];
        }
        if ([[jsonObject objectForKey:@"outbounds"] isKindOfClass:[NSArray class]]) {
            [outboundJSONs addObjectsFromArray:jsonObject[@"outbounds"]];
        }
        for (NSDictionary* outboundJSON in outboundJSONs) {
            NSString* protocol = outboundJSON[@"protocol"];
            if (!protocol) {
                continue;
            }
            if ([@"vmess" isEqualToString:outboundJSON[@"protocol"]]) {
                [result[@"vmess"] addObject:[ServerProfile profilesFromJson:outboundJSON][0]];
            } else {
                [result[@"other"] addObject:outboundJSON];
            }
        }
        if ([[jsonObject objectForKey:@"routing"] isKindOfClass:[NSDictionary class]]) {
            [routingJSONs addObject:[jsonObject objectForKey:@"routing"]];
        }
        if ([[jsonObject objectForKey:@"routings"] isKindOfClass:[NSArray class]]) {
            [routingJSONs addObjectsFromArray:[jsonObject objectForKey:@"routings"]];
        }
        for (NSDictionary* routingSet in routingJSONs) {
            NSMutableDictionary* set = [routingSet mutableDeepCopy];
            if (set[@"settings"]) { // compatibal with previous config file format
                set = set[@"settings"];
            }
            NSMutableDictionary* validatedSet = [ConfigImporter validateRuleSet:set];
            if (validatedSet) {
                [result[@"rules"] addObject:validatedSet];
            }
        }
        if (jsonObject[@"server"] && jsonObject[@"server_port"] && jsonObject[@"password"] && jsonObject[@"method"] && [SUPPORTED_SS_SECURITY indexOfObject:jsonObject[@"method"]] != NSNotFound) {
            NSMutableDictionary* ssOutbound = [@{
                                                 @"sendThrough": @"0.0.0.0",
                                                 @"protocol": @"shadowsocks",
                                                 @"settings": @{
                                                         @"servers": @[
                                                                 @{
                                                                     @"address": jsonObject[@"server"],
                                                                     @"port": jsonObject[@"server_port"],
                                                                     @"method": jsonObject[@"method"],
                                                                     @"password": jsonObject[@"password"],
                                                                     }
                                                                 ]
                                                         },
                                                 @"tag": [NSString stringWithFormat:@"%@:%@",jsonObject[@"server"],jsonObject[@"server_port"]],
                                                 @"streamSettings": @{},
                                                 @"mux": @{}
                                                 } mutableDeepCopy];
            if ([jsonObject[@"fast_open"] isKindOfClass:[NSNumber class]]) {
                ssOutbound[@"streamSettings"] =[@{ @"sockopt": @{
                                                           @"tcpFastOpen": jsonObject[@"fast_open"]
                                                           }} mutableDeepCopy];
            }
            [result[@"other"] addObject:ssOutbound];
        }
    }
    return result;
}

+ (NSMutableDictionary*)importFromHTTPSubscription: (NSString*)httpLink {
    // https://blog.csdn.net/yi_zz32/article/details/48769487
    NSMutableDictionary* result = [@{@"vmess": @[], @"other": @[]} mutableDeepCopy];
    if ([httpLink length] < 4) {
        return nil;
    }
    if (![@"http" isEqualToString:[httpLink substringToIndex:4]]) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:httpLink];
    NSError *urlError = nil;
    NSString *urlStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&urlError];
    if (!urlError) {
        NSString *decodedDataStr = [ConfigImporter decodeBase64String:urlStr];
        if ([decodedDataStr length] == 0) {
            return nil;
        }
        decodedDataStr = [decodedDataStr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSArray *decodedDataArray = [decodedDataStr componentsSeparatedByString:@"\n"];
        for (id linkStr in decodedDataArray) {
            if ([linkStr length] != 0) {
                ServerProfile* p = [ConfigImporter importFromVmessOfV2RayN:linkStr];
                if (p) {
                    [result[@"vmess"] addObject:p];
                    continue;
                }
                NSMutableDictionary* outbound = [ConfigImporter ssOutboundFromSSLink:linkStr];
                if (outbound) {
                    [result[@"other"] addObject:outbound];
                    continue;
                }
                NSMutableDictionary* ssdResults = [ConfigImporter importFromSubscriptionOfSSD:linkStr];
                [result[@"other"] addObjectsFromArray:ssdResults[@"other"]];
            }
        }
        return result;
    }
    return nil;
}

+ (ServerProfile*)importFromVmessOfV2RayN:(NSString*)vmessStr {
    if ([vmessStr length] < 9 || ![[[vmessStr substringToIndex:8] lowercaseString] isEqualToString:@"vmess://"]) {
        return nil;
    }
    NSString* decodedJsonString = [[ConfigImporter decodeBase64String:[vmessStr substringFromIndex:8]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSData* decodedData = [decodedJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* jsonParseError;
    NSDictionary *sharedServer = [NSJSONSerialization JSONObjectWithData:
                                  decodedData options:0 error:&jsonParseError];
    if (jsonParseError) {
        return nil;
    }
    ServerProfile* newProfile = [[ServerProfile alloc] init];
    newProfile.outboundTag = nilCoalescing([sharedServer objectForKey:@"ps"], @"imported From QR");
    newProfile.address = nilCoalescing([sharedServer objectForKey:@"add"], @"");
    newProfile.port = [nilCoalescing([sharedServer objectForKey:@"port"], @0) intValue];
    newProfile.userId = nilCoalescing([sharedServer objectForKey:@"id"], newProfile.userId);
    newProfile.alterId = [nilCoalescing([sharedServer objectForKey:@"aid"], @0) intValue];
    NSDictionary *netWorkDict = @{@"tcp": @0, @"kcp": @1, @"ws":@2, @"h2":@3 };
    if ([sharedServer objectForKey:@"net"] && [netWorkDict objectForKey:[sharedServer objectForKey:@"net"]]) {
        newProfile.network = [netWorkDict[sharedServer[@"net"]] intValue];
    }
    NSMutableDictionary* streamSettings = [newProfile.streamSettings mutableDeepCopy];
    switch (newProfile.network) {
        case tcp:
            if (![sharedServer objectForKey:@"type"] || !([sharedServer[@"type"] isEqualToString:@"none"] || [sharedServer[@"type"] isEqualToString:@"http"])) {
                break;
            }
            streamSettings[@"tcpSettings"][@"header"][@"type"] = sharedServer[@"type"];
            if ([streamSettings[@"tcpSettings"][@"header"][@"type"] isEqualToString:@"http"]) {
                if ([sharedServer objectForKey:@"host"]) {
                    streamSettings[@"tcpSettings"][@"header"][@"host"] = [sharedServer[@"host"] componentsSeparatedByString:@","];
                }
            }
            break;
        case kcp:
            if (![sharedServer objectForKey:@"type"]) {
                break;
            }
            if (![@{@"none": @0, @"srtp": @1, @"utp": @2, @"wechat-video":@3, @"dtls":@4, @"wireguard":@5} objectForKey:sharedServer[@"type"]]) {
                break;
            }
            streamSettings[@"kcpSettings"][@"header"][@"type"] = sharedServer[@"type"];
            break;
        case ws:
            if ([[sharedServer objectForKey:@"host"] containsString:@";"]) {
                NSArray *tempPathHostArray = [[sharedServer objectForKey:@"host"] componentsSeparatedByString:@";"];
                streamSettings[@"wsSettings"][@"path"] = tempPathHostArray[0];
                streamSettings[@"wsSettings"][@"headers"][@"Host"] = tempPathHostArray[1];
            }
            else {
                streamSettings[@"wsSettings"][@"path"] = nilCoalescing([sharedServer objectForKey:@"path"], @"");
                streamSettings[@"wsSettings"][@"headers"][@"Host"] = nilCoalescing([sharedServer objectForKey:@"host"], @"");
            }
            break;
        case http:
            if ([[sharedServer objectForKey:@"host"] containsString:@";"]) {
                NSArray *tempPathHostArray = [[sharedServer objectForKey:@"host"] componentsSeparatedByString:@";"];
                streamSettings[@"wsSettings"][@"path"] = tempPathHostArray[0];
                streamSettings[@"wsSettings"][@"headers"][@"Host"] = [tempPathHostArray[1] componentsSeparatedByString:@","];
            }
            else {
                streamSettings[@"httpSettings"][@"path"] = nilCoalescing([sharedServer objectForKey:@"path"], @"");
                if (![sharedServer objectForKey:@"host"]) {
                    break;
                };
                if ([[sharedServer objectForKey:@"host"] length] > 0) {
                    streamSettings[@"httpSettings"][@"host"] = [[sharedServer objectForKey:@"host"] componentsSeparatedByString:@","];
                }
            }
            break;
        default:
            break;
    }
    if ([sharedServer objectForKey:@"tls"] && [sharedServer[@"tls"] isEqualToString:@"tls"]) {
        streamSettings[@"security"] = @"tls";
        streamSettings[@"tlsSettings"][@"serverName"] = newProfile.address;
    }
    newProfile.streamSettings = streamSettings;
    return newProfile;
}

// https://github.com/CGDF-Github/SSD-Windows/wiki/订阅链接协定
+ (NSMutableDictionary* _Nonnull)importFromSubscriptionOfSSD: (NSString* _Nonnull)ssdLink {
    NSMutableDictionary* result = EMPTY_IMPORT_RESULT;
    @try {
        NSString* encodedPart;
        if (![[ssdLink substringToIndex:6] isEqualToString:@"ssd://"]) {
            return EMPTY_IMPORT_RESULT;
        }
        encodedPart = [ssdLink substringFromIndex:6];
        NSString* decodedJSONStr = [ConfigImporter decodeBase64String:encodedPart];
        NSDictionary* decodedObject = [NSJSONSerialization JSONObjectWithData:[decodedJSONStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        NSString* airportName = decodedObject[@"airport"];
        NSNumber* defaultPort = decodedObject[@"port"];
        NSString* defaultEncryption = decodedObject[@"encryption"];
        NSString* defaultPassword = decodedObject[@"password"];
        NSString* defaultPlutgin = decodedObject[@"plugin"];
        NSInteger count = 0;
        for (NSDictionary* server in decodedObject[@"servers"]) {
            NSString* address = server[@"server"];
            NSNumber* port = nilCoalescing(server[@"port"], defaultPort) ;
            NSString* method = nilCoalescing(server[@"encryption"], defaultEncryption);
            NSString* password = nilCoalescing(server[@"password"], defaultPassword);
            NSString* plugIn = nilCoalescing(server[@"plugin"], defaultPlutgin);
            if (plugIn && plugIn.length > 0) {
                continue; // do not support plug-in yet
            }
            NSString* defaultServerName = [NSString stringWithFormat:@"%lu", count];
            NSString* serverName = nilCoalescing(server[@"remarks"], defaultServerName);
            NSString* tag = [NSString stringWithFormat:@"%@-%@", airportName, serverName];
            NSMutableDictionary* ssOutbound =
            [ConfigImporter ssOutboundFromSSConfig:@{ @"server":address,
                                                      @"server_port":port,
                                                      @"password":password,
                                                      @"method":method,
                                                      @"tag": tag
             }];
            if (ssOutbound) {
                [result[@"other"] addObject:ssOutbound];
                count += 1;
            }
        }
        NSLog(@"%@", result);
        return result;
    } @catch (NSException *exception) {
        return EMPTY_IMPORT_RESULT;
    }
}

@end
