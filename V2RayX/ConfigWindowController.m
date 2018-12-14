//
//  ConfigWindowController.m
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import "ConfigWindowController.h"
#import "AppDelegate.h"
#import "MutableDeepCopying.h"

@interface ConfigWindowController () 

@end

@implementation ConfigWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    //set textField Display
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    [_portField setFormatter:formatter];
    [_alterIdField setFormatter:formatter];
    [_localPortField setFormatter:formatter];
    [_httpPortField setFormatter:formatter];
    [_addRemoveButton setMenu:_importFromJsonMenu forSegment:2];
    
    // copy data
    _profiles = [[NSMutableArray alloc] init];
    for (ServerProfile *p in appDelegate.profiles) {
        [_profiles addObject:[p deepCopy]];
    }
    _cusProfiles = [[NSMutableArray alloc] init];
    for (NSString* p in appDelegate.cusProfiles) {
        [_cusProfiles addObject:[NSString stringWithString:p]];
    }
    //
    [_profileTable reloadData];
    [self setSelectedServerIndex:appDelegate.selectedServerIndex];// must be put after reloadData!
    self.selectedCusServerIndex = appDelegate.selectedCusServerIndex;
    self.httpPort = appDelegate.httpPort;
    self.localPort = appDelegate.localPort;
    self.udpSupport = appDelegate.udpSupport;
    self.shareOverLan = appDelegate.shareOverLan;
    self.dnsString = appDelegate.dnsString;
    NSDictionary *logLevelDic = @{
                               @"debug": @4,
                               @"info": @3,
                               @"warning": @2,
                               @"error":@1,
                               @"none":@0
                               };
    self.logLevel = [logLevelDic[appDelegate.logLevel] integerValue];
    
    [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:self.selectedServerIndex] byExtendingSelection:NO];
    [[self window] makeFirstResponder:_profileTable];
}

// set controller as profilesTable and cusProfileTable's datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == _profileTable) {
        return [_profiles count];
    }
    if (tableView == _cusProfileTable) {
        return [_cusProfiles count];
    }
    return 0;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _cusProfileTable) {
        [_cusProfiles setObject:object atIndexedSubscript:row];
    }
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _profileTable) {
        if ([_profiles count] > 0) {
            ServerProfile* p = [_profiles objectAtIndex:row];
            return [[p remark] length] > 0 ? [p remark] : [NSString stringWithFormat:@"%@:%ld", [p address], [p port]];
        } else {
            return nil;
        }
    }
    if (tableView == _cusProfileTable) {
        if ([_cusProfiles count] > 0) {
            return _cusProfiles[row];
        } else {
            return nil;
        }
    }
    return nil;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    if ([notification object] == _profileTable) {
        if ([_profiles count] > 0) {
            [self setSelectedServerIndex:[_profileTable selectedRow]];
            [self setSelectedProfile:_profiles[_selectedServerIndex]];
        }
    }
    if ([notification object] == _cusProfileTable) {
        if ([_cusProfiles count] > 0) {
            [self setSelectedCusServerIndex:[_cusProfileTable selectedRow]];
        }
    }
    
}

- (IBAction)chooseNetwork:(NSPopUpButton *)sender {
    [self checkTLSforHttp2];
}

- (BOOL)checkTLSforHttp2 {
    if ([_networkButton indexOfSelectedItem] == 3) { // selected http/2
        BOOL tlsEnabled = [self.selectedProfile.streamSettings[@"security"] isEqual: @"tls"];
        if (!tlsEnabled) {
            NSAlert *httpTlsAlerm = [[NSAlert alloc] init];
            [httpTlsAlerm addButtonWithTitle:@"Close"];
            [httpTlsAlerm addButtonWithTitle:@"Help"];
            [httpTlsAlerm setMessageText:@"Both client and server must enable TLS to use HTTP/2 network! Enbale TLS in transport settings. Click \"Help\" if you need more information"];
            if ([httpTlsAlerm runModal] == NSAlertSecondButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com/chapter_02/transport/h2.html#tips"]];
            }
            [_networkButton selectItemAtIndex:0];
            return NO; // does not pass checking
        }
    }
    return true; //  pass checking
}

- (IBAction)addRemoveServer:(id)sender {
    if ([sender selectedSegment] == 0) {
        ServerProfile* newProfile = [[ServerProfile alloc] init];
        [_profiles addObject:newProfile];
        [_profileTable reloadData];
        [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:([_profiles count] - 1)] byExtendingSelection:NO];
    } else if ([sender selectedSegment] == 1 && [_profiles count] > 0) {
        NSInteger originalSelectedServerIndex = [_profileTable selectedRow];
        [_profiles removeObjectAtIndex:originalSelectedServerIndex];
        if ([_profiles count] > 0) {
            if (originalSelectedServerIndex == [_profiles count]) {//deleted the last server
                //select the last server of the remains
                [self setSelectedServerIndex:[_profiles count] - 1];
            }
            [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedServerIndex] byExtendingSelection:NO];
            [self setSelectedProfile:_profiles[_selectedServerIndex]];
        } else { // all the profiles are deleted;
            [self setSelectedServerIndex:-1];
            [self setSelectedProfile:nil];
        }
        [_profileTable reloadData];
    } else if ([sender selectedSegment] == 2) {
        [NSMenu popUpContextMenu:[sender menuForSegment:2] withEvent:[NSApp currentEvent] forView:sender];
    }
}

- (IBAction)cancel:(id)sender {
    [[self window] close];
}

- (IBAction)okSave:(id)sender {
    if (![self checkTLSforHttp2]) {
        return;
    }
    NSString* dnsStr = [[_dnsField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([dnsStr length] == 0) {
        dnsStr = @"localhost";
    }
    appDelegate.logLevel = _logLevelButton.selectedItem.title;
    appDelegate.selectedServerIndex = self.selectedServerIndex;
    appDelegate.selectedCusServerIndex = self.selectedCusServerIndex;
    appDelegate.localPort = [_localPortField integerValue];
    appDelegate.httpPort = [_httpPortField integerValue];
    appDelegate.udpSupport = self.udpSupport;
    appDelegate.shareOverLan = self.shareOverLan;
    appDelegate.dnsString = dnsStr;
    appDelegate.profiles = self.profiles;
    appDelegate.cusProfiles = self.cusProfiles;
    
    [appDelegate configurationDidChange];
    [[self window] close];
}

- (IBAction)addRemoveCusProfile:(NSSegmentedControl *)sender {
    if ([sender selectedSegment] == 0) {
        [_cusProfiles addObject:@"/path/to/your/config.json"];
        [_cusProfileTable reloadData];
        [_cusProfileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[_cusProfiles count] -1] byExtendingSelection:NO];
        [_cusProfileTable setFocusedColumn:[_cusProfiles count] - 1];
        //[[_cusProfileTable viewAtColumn:0 row:_cusProfiles count]-1 makeIfNecessary:NO] becomeFirstResponder];
    } else if ([sender selectedSegment] == 1 && [_cusProfiles count] > 0) {
        NSInteger originalSelected = [_cusProfileTable selectedRow];
        [_cusProfiles removeObjectAtIndex:originalSelected];
        if ([_cusProfiles count] > 0) {
            if (originalSelected == [_cusProfiles count]) {
                [self setSelectedCusServerIndex:[_cusProfiles count] - 1];
            }
            [_cusProfileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedCusServerIndex] byExtendingSelection:NO];
        } else {
            [self setSelectedCusServerIndex:-1];
        }
        [_cusProfileTable reloadData];
    }
}


- (IBAction)showCusConfigWindow:(NSButton *)sender {
    if (_cusConfigWindow == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"customizedConfigWindow" owner:self topLevelObjects:nil];
    }
    //show sheet
    [[self window] beginSheet:_cusConfigWindow completionHandler:^(NSModalResponse returnCode) {
    }];
}

- (IBAction)cFinish:(NSButton *)sender {
    [_checkLabel setHidden:NO];
    NSString* v2rayBinPath = [NSString stringWithFormat:@"%@/v2ray", [[NSBundle mainBundle] resourcePath]];
    for (NSString* filePath in _cusProfiles) {
        int returnCode = runCommandLine(v2rayBinPath, @[@"-test", @"-config", filePath]);
        if (returnCode != 0) {
            [_checkLabel setHidden:YES];
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:@"%@ is not a valid v2ray config file", filePath]];
            [alert beginSheetModalForWindow:_cusConfigWindow completionHandler:^(NSModalResponse returnCode) {
                return;
            }];
            return;
        }
    }
    [[self window] endSheet:_cusConfigWindow];
}



- (IBAction)showTransportSettings:(id)sender {
    if (_transportWindow == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"transportWindow" owner:self topLevelObjects:nil];
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
    [_proxyPortField setFormatter:formatter];
    //read settings
    NSDictionary *transportSettings = [self.selectedProfile streamSettings];
    //kcp
    [_kcpMtuField setIntegerValue:[transportSettings[@"kcpSettings"][@"mtu"] integerValue]];
    [_kcpTtiField setIntegerValue:[transportSettings[@"kcpSettings"][@"tti"] integerValue]];
    [_kcpUcField setIntegerValue:[transportSettings[@"kcpSettings"][@"uplinkCapacity"] integerValue]];
    [_kcpDcField setIntegerValue:[transportSettings[@"kcpSettings"][@"downlinkCapacity"] integerValue]];
    [_kcpRbField setIntegerValue:[transportSettings[@"kcpSettings"][@"readBufferSize"] integerValue]];
    [_kcpWbField setIntegerValue:[transportSettings[@"kcpSettings"][@"writeBufferSize"] integerValue]];
    [_kcpCongestionButton selectItemAtIndex:[transportSettings[@"kcpSettings"][@"congestion"] boolValue] ? 1 : 0];
    NSString *headerType = transportSettings[@"kcpSettings"][@"header"][@"type"];
    if ([headerType isKindOfClass:[NSString class]]) {
        if ([headerType isEqualToString:@"srtp"]) {
            [_kcpHeaderTypeButton selectItemAtIndex:1];
        } else if ([headerType isEqualToString:@"utp"]) {
            [_kcpHeaderTypeButton selectItemAtIndex:2];
        } else if ([headerType isEqualToString:@"wechat-video"]) {
            [_kcpHeaderTypeButton selectItemAtIndex:3];
        } else if ([headerType isEqualToString:@"dtls"]) {
            [_kcpHeaderTypeButton selectItemAtIndex:4];
        } else if ([headerType isEqualToString:@"wireguard"]) {
            [_kcpHeaderTypeButton selectItemAtIndex:5];
        }
    }
    //tcp
    [_tcpHeaderCusButton setState:[transportSettings[@"tcpSettings"][@"header"][@"type"] isEqualToString:@"http"] ? 1 : 0];
    if ([_tcpHeaderCusButton state]) {
        [_tcpHdField setString:
         [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:transportSettings[@"tcpSettings"][@"header"] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]];
    } else {
        [_tcpHdField setString:@"{\"type\": \"none\"}"];
    }
    //websocket
    NSString *savedWsPath = transportSettings[@"wsSettings"][@"path"];
    [_wsPathField setStringValue: savedWsPath != nil ? savedWsPath : @""];
    if (transportSettings[@"wsSettings"][@"headers"] != nil) {
        [_wsHeaderField setString:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:transportSettings[@"wsSettings"][@"headers"] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]];
    } else {
        [_wsHeaderField setString:@"{}"];
    }
    //http/2
    [_httpPathField setStringValue:nilCoalescing(transportSettings[@"httpSettings"][@"path"], @"")];
    NSString* hostString = @"";
    if ([transportSettings[@"httpSettings"] objectForKey:@"host"]) {
        NSArray* hostArray = transportSettings[@"httpSettings"][@"host"];
        if([hostArray count] > 0) {
            hostString = [hostArray componentsJoinedByString:@","];
        }
    }
    [_httpHostsField setStringValue:hostString];
    //tls
    [_tlsUseButton setState:[[transportSettings objectForKey:@"security"] boolValue]];
    NSDictionary* tlsSettings = [transportSettings objectForKey:@"tlsSettings"];
    [_tlsAiButton setState:[tlsSettings[@"allowInsecure"] boolValue]];
    [_tlsAllowInsecureCiphersButton setState:[tlsSettings[@"allowInsecureCiphers"] boolValue]];
    NSArray* alpnArray = transportSettings[@"tlsSettings"][@"alpn"];
    NSString* alpnString = @"";
    alpnString = [alpnArray componentsJoinedByString:@","];
    [_tlsAlpnField setStringValue:nilCoalescing(alpnString, @"http/1.1")];
    /*
    if (tlsSettings[@"serverName"]) {
        [_tlsSnField setStringValue:self.selectedProfile.address];
    }
    */
    [self useTLS:nil];
    // mux
    NSDictionary *muxSettings = [self.selectedProfile muxSettings];
    [_muxEnableButton setState:[nilCoalescing(muxSettings[@"enabled"], @NO) boolValue]];
    [_muxConcurrencyField setIntegerValue:[nilCoalescing(muxSettings[@"concurrency"], @8) integerValue]];
    // tcp fast open
    NSDictionary* tfoSettings = [transportSettings objectForKey:@"sockopt"];
    [_tfoEnableButton setState:[tfoSettings[@"tcpFastOpen"] boolValue]];
    // proxy
    /*
    NSDictionary *proxySettings = [selectedProfile proxySettings];
    [_proxyAddressField setStringValue:nilCoalescing(proxySettings[@"address"], @"")];
    [_proxyPortField setIntegerValue:[nilCoalescing(proxySettings[@"port"], @0) integerValue]];*/
    //show sheet
    [[self window] beginSheet:_transportWindow completionHandler:^(NSModalResponse returnCode) {
    }];
}

- (IBAction)tReset:(id)sender {
    //kcp fields
    [_kcpMtuField setIntegerValue:1350];
    [_kcpTtiField setIntegerValue:50];
    [_kcpUcField setIntegerValue:5];
    [_kcpDcField setIntegerValue:20];
    [_kcpRbField setIntegerValue:2];
    [_kcpWbField setIntegerValue:1];
    [_kcpCongestionButton selectItemAtIndex:0];
    [_kcpHeaderTypeButton selectItemAtIndex:0];
    //tcp fields
    [_tcpHeaderCusButton setState:0];
    //ws fields
    [_wsPathField setStringValue:@""];
    [_wsHeaderField setString:@"{}"];
    //tls fields
    [_tlsUseButton setState:0];
    [_tlsAiButton setState:0];
    [_tlsAllowInsecureCiphersButton setState:0];
    [_tlsAlpnField setStringValue:@"http/1.1"];
    //http/2 fields
    [_httpHostsField setStringValue:@""];
    [_httpPathField setStringValue:@""];
    //mux fields
    [_muxEnableButton setState:0];
    [_muxEnableButton setIntegerValue:8];
    //tcp fast open
    [_tfoEnableButton setState:0];
    //outbound proxy
    [_proxyPortField setIntegerValue:0];
    [_proxyAddressField setStringValue:@""];
}
- (IBAction)tCancel:(id)sender {
    [[self window] endSheet:_transportWindow];
}
- (IBAction)tOK:(id)sender {
    //check tcp header
    NSString* tcpHttpHeaderString = @"{\"type\": \"none\"}";
    if ([self->_tcpHeaderCusButton state]) {
        tcpHttpHeaderString = [self->_tcpHdField string];
    }
    NSError* httpHeaderParseError;
    NSDictionary* tcpHttpHeader = [NSJSONSerialization JSONObjectWithData:[tcpHttpHeaderString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&httpHeaderParseError];
    if (httpHeaderParseError) {
        NSAlert* parseAlert = [[NSAlert alloc] init];
        [parseAlert setMessageText:@"Error in parsing customized tcp http header!"];
        [parseAlert beginSheetModalForWindow:_transportWindow completionHandler:^(NSModalResponse returnCode) {
            return;
        }];
        return;
    }
    
    NSString* wsHeaderString = [nilCoalescing([self->_wsHeaderField string], @"") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSDictionary* wsHeader;
    if ([wsHeaderString length]) {
        NSError* wsHeaderParseError;
        wsHeader = [NSJSONSerialization JSONObjectWithData:[wsHeaderString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&wsHeaderParseError];
        if(wsHeaderParseError) {
            NSAlert* parseAlert = [[NSAlert alloc] init];
            [parseAlert setMessageText:@"Error in parsing customized WebSocket headers!"];
            [parseAlert beginSheetModalForWindow:_transportWindow completionHandler:^(NSModalResponse returnCode) {
                return;
            }];
            return;
        }
    }
    
    NSAlert* settingAlert = [[NSAlert alloc] init];
    [settingAlert setMessageText:@"Make sure you have read the help before clicking OK!"];
    [settingAlert addButtonWithTitle:@"Yes, save!"];
    [settingAlert addButtonWithTitle:@"Do not save."];
    NSArray* httpHosts;
    if ([_httpHostsField stringValue] == nil || [[[_httpHostsField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        httpHosts = @[];
    } else {
        NSString* hostsString = [[_httpHostsField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
        httpHosts = [hostsString componentsSeparatedByString:@","];
    }
    NSArray* tlsAlpn;
    tlsAlpn = [[_tlsAlpnField stringValue] componentsSeparatedByString:@","];
    [settingAlert beginSheetModalForWindow:_transportWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            //save settings
            NSDictionary *httpSettings;
            if ([httpHosts count] > 0) {
                httpSettings = @{ @"host": httpHosts,
                                  @"path": nilCoalescing([self->_httpPathField stringValue], @"")
                                  };
            } else {
                httpSettings = @{ @"path": nilCoalescing([self->_httpPathField stringValue], @"") };
            }
            // old sockopt config
            /*
            NSDictionary *sockopt;
            if ([self->_tfoEnableButton state]) {
                sockopt = @{
                           @"tcpFastOpen": [NSNumber numberWithBool:[self->_tfoEnableButton state] == 1]
                           };
            } else {
                sockopt = @{};
            }
             */
            NSDictionary *sockopt = @{
                                      @"tcpFastOpen": [NSNumber numberWithBool:[self->_tfoEnableButton state] == 1]
                                      };
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
                      @"path": nilCoalescing([self->_wsPathField stringValue], @""),
                      @"headers": nilCoalescing(wsHeader, @{})
                  },
              @"security": [self->_tlsUseButton state] ? @"tls" : @"none",
              @"tlsSettings": @{
                      @"serverName": nilCoalescing(self.selectedProfile.address, @""),
                      @"allowInsecure": [NSNumber numberWithBool:[self->_tlsAiButton state]==1],
                      @"allowInsecureCiphers": [NSNumber numberWithBool:[self->_tlsAllowInsecureCiphersButton state]==1],
                      @"alpn": tlsAlpn
              },
              @"httpSettings": httpSettings,
              };
            NSMutableDictionary *streamSettings = [streamSettingsImmutable mutableCopy];
            if ([self->_tfoEnableButton state]) {
                [streamSettings setObject:sockopt forKey:@"sockopt"];
            }
            NSDictionary* muxSettings = @{
                                          @"enabled":[NSNumber numberWithBool:[self->_muxEnableButton state]==1],
                                          @"concurrency":[NSNumber numberWithInteger:[self->_muxConcurrencyField integerValue]]
                                          };
            //NSDictionary* proxySettings = @{@"address": nilCoalescing([self->_proxyAddressField stringValue], @""), @"port": @([self->_proxyPortField integerValue])};
            self.selectedProfile.muxSettings = muxSettings;
            self.selectedProfile.streamSettings = streamSettings;
            //self.selectedProfile.proxySettings = proxySettings;
            //close sheet
            [[self window] endSheet:self->_transportWindow];
        }
    }];
}
- (IBAction)showKcpHeaderExample:(id)sender {
    runCommandLine(@"/usr/bin/open", @[[[NSBundle mainBundle] pathForResource:@"tcp_http_header_example" ofType:@"txt"], @"-a", @"/Applications/TextEdit.app"]);
}


// https://stackoverflow.com/questions/7387341/how-to-create-and-get-return-value-from-cocoa-dialog/7387395#7387395
- (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue {
    NSAlert *alert = [NSAlert alertWithMessageText: prompt
                                     defaultButton:@"OK"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 24)];
    [input setStringValue:defaultValue];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [input validateEditing];
        return [input stringValue];
    } else if (button == NSAlertAlternateReturn) {
        return nil;
    } else {
        NSAssert1(NO, @"Invalid input dialog button %ld", button);
        return nil;
    }
}

- (void)showAlert:(NSString*)text {
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setInformativeText:text];
    [alert runModal];
}

- (IBAction)importFromQRCodeV2rayNV2:(id)sender {
    /* https://github.com/2dust/v2rayN/wiki/分享链接格式说明(ver-2) */
    NSString* inputStr = [[self input:@"Please input the server info. Format: vmess://" defaultValue:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([inputStr length] == 0) {
        return;
    }
    if ([inputStr length] < 9 || ![[[inputStr substringToIndex:8] lowercaseString] isEqualToString:@"vmess://"]) {
        [self showAlert:@"Not a vmess:// link!"];
        return;
    }
    // https://stackoverflow.com/questions/19088231/base64-decoding-in-ios-7
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:[inputStr substringFromIndex:8] options:0];
    NSError* jsonParseError;
    NSDictionary *sharedServer = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:&jsonParseError];
    if (jsonParseError) {
        [self showAlert:@"Not va valid link!"];
        return;
    }
    if (![sharedServer objectForKey:@"v"] || [sharedServer[@"v"] isNotEqualTo:@"2"]) {
        [self showAlert:@"Unknown format or Unknown link version!"];
        return;
    }
    ServerProfile* newProfile = [[ServerProfile alloc] init];
    newProfile.remark = nilCoalescing([sharedServer objectForKey:@"ps"], @"imported From QR");
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
            streamSettings[@"wsSettings"][@"path"] = nilCoalescing([sharedServer objectForKey:@"path"], @"");
            streamSettings[@"wsSettings"][@"headers"][@"Host"] = nilCoalescing([sharedServer objectForKey:@"host"], @"");
            break;
        case http:
            streamSettings[@"httpSettings"][@"path"] = nilCoalescing([sharedServer objectForKey:@"path"], @"");
            if (![sharedServer objectForKey:@"host"]) {
                break;
            };
            if ([[sharedServer objectForKey:@"host"] length] > 0) {
                streamSettings[@"httpSettings"][@"host"] = [[sharedServer objectForKey:@"host"] componentsSeparatedByString:@","];
            }
            break;
        default:
            break;
    }
    if ([sharedServer objectForKey:@"tls"] && [sharedServer[@"tls"] isEqualToString:@"tls"]) {
        streamSettings[@"security"] = @"tls";
    }
    newProfile.streamSettings = streamSettings;
    [_profiles addObject:newProfile];
    [_profileTable reloadData];
    [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:([_profiles count] - 1)] byExtendingSelection:NO];
}

- (IBAction)importFromConfigJson:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowedFileTypes:@[@"json"]];
    [openPanel setDirectoryURL:[[NSFileManager defaultManager] homeDirectoryForCurrentUser]];
    [openPanel beginSheetModalForWindow:[self window]  completionHandler:^(NSModalResponse result) {
        if (result != NSOKButton) {
            return;
        }
        for (NSURL* file in [openPanel URLs]) {
            NSError* error;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:
                             [NSData dataWithContentsOfURL:file] options:0 error:&error];
            if (error) continue;
            if (![jsonObject isKindOfClass:[NSDictionary class]]) continue;
            NSMutableArray* jsons = [[NSMutableArray alloc] init];
            if ([[jsonObject objectForKey:@"outbound"] isKindOfClass:[NSDictionary class]]) {
                [jsons addObject:jsonObject[@"outbound"]];
            }
            if ([[jsonObject objectForKey:@"outboundDetour"] isKindOfClass:[NSArray class]]) {
                [jsons addObjectsFromArray:jsonObject[@"outboundDetour"]];
            }
            for (NSDictionary* json in jsons) {
                NSArray* servers = [ServerProfile profilesFromJson:json];
                for (ServerProfile* s in servers) {
                    [s setRemark:[NSString stringWithFormat:@"imported %@", s.remark]];
                }
                [self->_profiles addObjectsFromArray:servers];
            }
        }
        [self->_profileTable reloadData];
    }];
}

- (IBAction)useTLS:(id)sender {
    [_tlsAiButton setEnabled:[_tlsUseButton state]];
    [_tlsAllowInsecureCiphersButton setEnabled:[_tlsUseButton state]];
}

- (IBAction)transportHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://v2ray.com/chapter_02/05_transport.html"]];
}

- (IBAction)showLog:(id)sender {
    [appDelegate viewLog:sender];
}

@synthesize appDelegate;

@end
