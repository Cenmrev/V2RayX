//
//  TransportWindowController.m
//  V2RayX
//
//

#import "TransportWindowController.h"

@interface TransportWindowController () {
    ConfigWindowController* configWindowController;
}

@end

@implementation TransportWindowController

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName parentController:(ConfigWindowController*)parent {
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        configWindowController = parent;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    //add UI items
    [_kcpHeaderTypeButton removeAllItems];
    [_quicHeaderButton removeAllItems];
    for (NSString* header in OBFU_LIST) {
        [_kcpHeaderTypeButton addItemWithTitle:header];
        [_quicHeaderButton addItemWithTitle:header];
    }
    [_quicSecurityButton removeAllItems];
    for (NSString* security in QUIC_SECURITY_LIST) {
        [_quicSecurityButton addItemWithTitle:security];
    }
    
    //set display
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    [_kcpMtuField setFormatter:formatter];
    [_kcpTtiField setFormatter:formatter];
    [_kcpUcField setFormatter:formatter];
    [_kcpDcField setFormatter:formatter];
    [_kcpRbField setFormatter:formatter];
    [_kcpWbField setFormatter:formatter];
    [_muxConcurrencyField setFormatter:formatter];
//    _tcpHdField setautomatcic
    [_tcpHeaderField setAutomaticQuoteSubstitutionEnabled:false];
    [_wsHeaderField setAutomaticQuoteSubstitutionEnabled:false];
    
    //read settings
    [self fillStream:configWindowController.selectedProfile.streamSettings andMuxSettings:configWindowController.selectedProfile.muxSettings];
    
}

- (void)fillStream:(NSDictionary*)streamSettings andMuxSettings:(NSDictionary*)muxSettings {
    //kcp
    [_kcpMtuField setIntegerValue:[streamSettings[@"kcpSettings"][@"mtu"] integerValue]];
    [_kcpTtiField setIntegerValue:[streamSettings[@"kcpSettings"][@"tti"] integerValue]];
    [_kcpUcField setIntegerValue:[streamSettings[@"kcpSettings"][@"uplinkCapacity"] integerValue]];
    [_kcpDcField setIntegerValue:[streamSettings[@"kcpSettings"][@"downlinkCapacity"] integerValue]];
    [_kcpRbField setIntegerValue:[streamSettings[@"kcpSettings"][@"readBufferSize"] integerValue]];
    [_kcpWbField setIntegerValue:[streamSettings[@"kcpSettings"][@"writeBufferSize"] integerValue]];
    [_kcpCongestionButton selectItemAtIndex:[streamSettings[@"kcpSettings"][@"congestion"] boolValue] ? 1 : 0];
    [_kcpHeaderTypeButton selectItemAtIndex:searchInArray(streamSettings[@"kcpSettings"][@"header"][@"type"], OBFU_LIST)];
    
    //tcp
    [_tcpHeaderCusButton setState:[streamSettings[@"tcpSettings"][@"header"][@"type"] isEqualToString:@"http"] ? 1 : 0];
    if ([_tcpHeaderCusButton state]) {
        [_tcpHeaderField setString:
         [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:streamSettings[@"tcpSettings"][@"header"] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]];
    } else {
        [_tcpHeaderField setString:@"{\"type\": \"none\"}"];
    }
    //websocket
    NSString *savedWsPath = streamSettings[@"wsSettings"][@"path"];
    [_wsPathField setStringValue: savedWsPath != nil ? savedWsPath : @""];
    if (streamSettings[@"wsSettings"][@"headers"] != nil) {
        [_wsHeaderField setString:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:streamSettings[@"wsSettings"][@"headers"] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]];
    } else {
        [_wsHeaderField setString:@"{}"];
    }
    //http/2
    [_httpPathField setStringValue:nilCoalescing(streamSettings[@"httpSettings"][@"path"], @"")];
    NSString* hostString = @"";
    if ([streamSettings[@"httpSettings"] objectForKey:@"host"]) {
        NSArray* hostArray = streamSettings[@"httpSettings"][@"host"];
        if([hostArray isKindOfClass:[NSArray class]] && [hostArray count] > 0) {
            hostString = [hostArray componentsJoinedByString:@","];
        }
    }
    [_httpHostsField setStringValue:hostString];
    //quic
    [_quicKeyField setStringValue:nilCoalescing(streamSettings[@"quicSettings"][@"key"], @"")];
    [_quicSecurityButton selectItemAtIndex:searchInArray(streamSettings[@"quicSettings"][@"security"], QUIC_SECURITY_LIST)];
    [_quicHeaderButton selectItemAtIndex:searchInArray(streamSettings[@"quicSettings"][@"header"][@"type"], OBFU_LIST)];
    
    //tls
    [_tlsUseButton setState:[[streamSettings objectForKey:@"security"] boolValue]];
    NSDictionary* tlsSettings = [streamSettings objectForKey:@"tlsSettings"];
    [_tlsAiButton setState:[tlsSettings[@"allowInsecure"] boolValue]];
    [_tlsAllowInsecureCiphersButton setState:[tlsSettings[@"allowInsecureCiphers"] boolValue]];
    NSArray* alpnArray = streamSettings[@"tlsSettings"][@"alpn"];
    NSString* alpnString = [alpnArray componentsJoinedByString:@","];
    [_tlsAlpnField setStringValue:nilCoalescing(alpnString, @"http/1.1")];
    [_tlsServerNameField setStringValue:streamSettings[@"tlsSettings"][@"serverName"]];
    
    [self useTLS:nil];
    // mux
    [_muxEnableButton setState:[nilCoalescing(muxSettings[@"enabled"], @NO) boolValue]];
    [_muxConcurrencyField setIntegerValue:[nilCoalescing(muxSettings[@"concurrency"], @8) integerValue]];
    // tcp fast open
    NSDictionary* tfoSettings = [streamSettings objectForKey:@"sockopt"];
    [_tfoEnableButton setState:[tfoSettings[@"tcpFastOpen"] boolValue]];
}

- (IBAction)useTLS:(id)sender {
    [_tlsAiButton setEnabled:[_tlsUseButton state]];
    [_tlsAllowInsecureCiphersButton setEnabled:[_tlsUseButton state]];
}

- (IBAction)tReset:(id)sender {
    ServerProfile *p = [[ServerProfile alloc] init];
    [self fillStream:p.streamSettings andMuxSettings:p.muxSettings];
}

- (IBAction)showTcpHeaderExample:(id)sender {
    runCommandLine(@"/usr/bin/open", @[[[NSBundle mainBundle] pathForResource:@"tcp_http_header_example" ofType:@"txt"], @"-a", @"/Applications/TextEdit.app"]);
}

- (IBAction)tCancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)ok:(id)sender {
    NSLog(@"%@", [_httpPathField stringValue]);
    if ([self checkInputs]) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    }
}

- (IBAction)transportHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://v2ray.com/chapter_02/05_transport.html"]];
}

- (BOOL)checkInputs {
    NSError* httpHeaderParseError;
    if ([[_tcpHeaderField string] length] == 0) {
        [_tcpHeaderField setString:TCP_NONE_HEADER_OBJECT];
    }
    [NSJSONSerialization JSONObjectWithData:[[_tcpHeaderField string] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&httpHeaderParseError];
    if (httpHeaderParseError) {
        NSAlert* parseAlert = [[NSAlert alloc] init];
        [parseAlert setMessageText:@"Error in parsing customized tcp http header!"];
        [parseAlert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) { }];
        return NO;
    }
    
    NSError* wsHeaderParseError;
    if ([[_wsHeaderField string] length] == 0) {
        [_wsHeaderField setString:@"{}"];
    }
    [NSJSONSerialization JSONObjectWithData:[[_wsHeaderField string] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&wsHeaderParseError];
    if(wsHeaderParseError) {
        NSAlert* parseAlert = [[NSAlert alloc] init];
        [parseAlert setMessageText:@"Error in parsing customized WebSocket headers!"];
        [parseAlert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) { }];
        return NO;
    }
    return YES;
}

- (NSArray*)generateSettings {
    NSString* tcpHttpHeaderString = TCP_NONE_HEADER_OBJECT;
    if ([_tcpHeaderCusButton state]) {
        tcpHttpHeaderString = [_tcpHeaderField string];
    }
    NSDictionary* tcpHttpHeader = [NSJSONSerialization JSONObjectWithData:[tcpHttpHeaderString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    NSDictionary* wsHeader = [NSJSONSerialization JSONObjectWithData:[[_wsHeaderField string] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    NSArray* httpHosts;
    if ([[[_httpHostsField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        httpHosts = @[];
    } else {
        NSString* hostsString = [[_httpHostsField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
        httpHosts = [hostsString componentsSeparatedByString:@","];
    }
    NSDictionary *httpSettings;
    if ([httpHosts count] > 0) {
        httpSettings = @{ @"host": httpHosts,
                          @"path": [self->_httpPathField stringValue]
                          };
    } else {
        httpSettings = @{ @"path": [self->_httpPathField stringValue] };
    }
    NSDictionary *streamSettingsImmutable =
    @{@"kcpSettings":
          @{@"mtu":[NSNumber numberWithInteger:[self->_kcpMtuField integerValue]],
            @"tti":[NSNumber numberWithInteger:[self->_kcpTtiField integerValue]],
            @"uplinkCapacity":[NSNumber numberWithInteger:[self->_kcpUcField integerValue]],
            @"downlinkCapacity":[NSNumber numberWithInteger:[self->_kcpDcField integerValue]],
            @"readBufferSize":[NSNumber numberWithInteger:[self->_kcpRbField integerValue]],
            @"writeBufferSize":[NSNumber numberWithInteger:[self->_kcpWbField integerValue]],
            @"congestion":[NSNumber numberWithBool:[self->_kcpCongestionButton indexOfSelectedItem] != 0],
            @"header":@{@"type":[[self->_kcpHeaderTypeButton selectedItem] title]}
            },
      @"tcpSettings":@{@"header": tcpHttpHeader},
      @"wsSettings": @{
              @"path": [[_wsPathField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
              @"headers": nilCoalescing(wsHeader, @{})
              },
      @"quicSettings": @{
              @"security": [[self->_quicSecurityButton selectedItem] title],
              @"key": [_quicKeyField stringValue],
              @"header": @{
                      @"type": [[self->_quicHeaderButton selectedItem] title]
                      }
              },
      @"security": [self->_tlsUseButton state] ? @"tls" : @"none",
      @"tlsSettings": @{
              @"serverName": [_tlsServerNameField stringValue],
              @"allowInsecure": [NSNumber numberWithBool:[self->_tlsAiButton state]==1],
              @"allowInsecureCiphers": [NSNumber numberWithBool:[self->_tlsAllowInsecureCiphersButton state]==1],
              @"alpn": [[[_tlsAlpnField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@","]
              },
      @"httpSettings": httpSettings
      };
    NSMutableDictionary *streamSettings = [streamSettingsImmutable mutableCopy];
    if ([self->_tfoEnableButton state]) {
        streamSettings[@"sockopt"] = @{
                                      @"tcpFastOpen": @(YES)
                                      };
    }
    NSDictionary* muxSettings = @{
                                  @"enabled":[NSNumber numberWithBool:[self->_muxEnableButton state]==1],
                                  @"concurrency":[NSNumber numberWithInteger:[self->_muxConcurrencyField integerValue]]
                                  };
    return @[streamSettings, muxSettings];
}


@end
