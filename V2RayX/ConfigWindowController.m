//
//  ConfigWindowController.m
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import "ConfigWindowController.h"
#import "AppDelegate.h"

@interface ConfigWindowController () {
    NSMutableArray *profiles;
    NSMutableArray *cusProfiles;
}

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
    profiles = [appDelegate profiles];
    cusProfiles = [appDelegate cusProfiles];
    [_profileTable reloadData];
    [self setSelectedServerIndex:appDelegate.selectedServerIndex];// must be put after reloadData!
    [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedServerIndex] byExtendingSelection:NO];
    NSLog(@"%ld", (long)[_profileTable selectedRow]);
    NSDictionary *logLevelDic = @{
                               @"debug": @4,
                               @"info": @3,
                               @"warning": @2,
                               @"error":@1,
                               @"none":@0
                               };
    [_logLevelButton selectItemAtIndex:[logLevelDic[[appDelegate logLevel]] integerValue]];
}

// set controller as profilesTable and cusProfileTable's datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == _profileTable) {
        return [profiles count];
    }
    if (tableView == _cusProfileTable) {
        return [cusProfiles count];
    }
    return 0;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _cusProfileTable) {
        [cusProfiles setObject:object atIndexedSubscript:row];
    }
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _profileTable) {
        if ([profiles count] > 0) {
            ServerProfile* p = [profiles objectAtIndex:row];
            return [p address];
        } else {
            return nil;
        }
    }
    if (tableView == _cusProfileTable) {
        if ([cusProfiles count] > 0) {
            return cusProfiles[row];
        } else {
            return nil;
        }
    }
    return nil;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    if ([notification object] == _profileTable) {
        if ([profiles count] > 0) {
            [self setSelectedServerIndex:[_profileTable selectedRow]];
            [self setSelectedProfile:profiles[_selectedServerIndex]];
        }
    }
    if ([notification object] == _cusProfileTable) {
        if ([cusProfiles count] > 0) {
            [self setSelectedCusServerIndex:[_cusProfileTable selectedRow]];
        }
    }
    
}

- (IBAction)chooseNetwork:(NSPopUpButton *)sender {
    [self checkTLSforHttp2];
}

- (BOOL)checkTLSforHttp2 {
    if ([_networkButton indexOfSelectedItem] == 3) { // selected http/2
        BOOL tlsEnabled = [selectedProfile.streamSettings[@"security"] isEqual: @"tls"];
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
        [profiles addObject:newProfile];
        [_profileTable reloadData];
        [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:([profiles count] - 1)] byExtendingSelection:NO];
    } else if ([sender selectedSegment] == 1 && [profiles count] > 0) {
        NSInteger originalSelectedServerIndex = [_profileTable selectedRow];
        [profiles removeObjectAtIndex:originalSelectedServerIndex];
        if ([profiles count] > 0) {
            if (originalSelectedServerIndex == [profiles count]) {//deleted the last server
                //select the last server of the remains
                [self setSelectedServerIndex:[profiles count] - 1];
            }
            [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedServerIndex] byExtendingSelection:NO];
            [self setSelectedProfile:profiles[_selectedServerIndex]];
        } else { // all the profiles are deleted;
            [self setSelectedServerIndex:-1];
            [self setSelectedProfile:nil];
        }
        [_profileTable reloadData];
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
    appDelegate.dnsString = dnsStr;
    appDelegate.logLevel = _logLevelButton.selectedItem.title;
    appDelegate.selectedServerIndex = _selectedServerIndex;
    [appDelegate configurationDidChange];
    
    [[self window] close];
}

- (IBAction)addRemoveCusProfile:(NSSegmentedControl *)sender {
    if ([sender selectedSegment] == 0) {
        [cusProfiles addObject:@"/path/to/your/config.json"];
        [_cusProfileTable reloadData];
        [_cusProfileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[cusProfiles count] -1] byExtendingSelection:NO];
        [_cusProfileTable setFocusedColumn:[cusProfiles count] - 1];
        //[[_cusProfileTable viewAtColumn:0 row:[cusProfiles count]-1 makeIfNecessary:NO] becomeFirstResponder];
    } else if ([sender selectedSegment] == 1 && [cusProfiles count] > 0) {
        NSInteger originalSelected = [_cusProfileTable selectedRow];
        [cusProfiles removeObjectAtIndex:originalSelected];
        if ([cusProfiles count] > 0) {
            if (originalSelected == [cusProfiles count]) {
                [self setSelectedCusServerIndex:[cusProfiles count] - 1];
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
    NSString* v2rayBinPath = [NSString stringWithFormat:@"%@/v2ray", [[NSBundle mainBundle] resourcePath]];
    for (NSString* filePath in cusProfiles) {
        int returnCode = runCommandLine(v2rayBinPath, @[@"-test", @"-config", filePath]);
        if (returnCode != 0) {
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
    NSDictionary *transportSettings = [selectedProfile streamSettings];
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
    NSArray* hostArray = transportSettings[@"httpSettings"][@"host"];
    NSString* hostString = @"";
    if([hostArray count] > 0) {
        hostString = [hostArray componentsJoinedByString:@","];
    }
    [_httpHostsField setStringValue:hostString];
    //tls
    [_tlsUseButton setState:[[transportSettings objectForKey:@"security"] boolValue]];
    NSDictionary* tlsSettings = [transportSettings objectForKey:@"tlsSettings"];
    [_tlsAiButton setState:[tlsSettings[@"allowInsecure"] boolValue]];
    if (tlsSettings[@"serverName"]) {
        [_tlsSnField setStringValue:tlsSettings[@"serverName"]];
    }
    [self useTLS:nil];
    // mux
    NSDictionary *muxSettings = [selectedProfile muxSettings];
    [_muxEnableButton setState:[nilCoalescing(muxSettings[@"enabled"], @NO) boolValue]];
    [_muxConcurrencyField setIntegerValue:[nilCoalescing(muxSettings[@"concurrency"], @8) integerValue]];
    // proxy
    NSDictionary *proxySettings = [selectedProfile proxySettings];
    [_proxyAddressField setStringValue:nilCoalescing(proxySettings[@"address"], @"")];
    [_proxyPortField setIntegerValue:[nilCoalescing(proxySettings[@"port"], @0) integerValue]];
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
    [_tlsSnField setStringValue:@"server.cc"];
    //http/2 fields
    [_httpHostsField setStringValue:@""];
    [_httpPathField setStringValue:@""];
    //mux fields
    [_muxEnableButton setState:0];
    [_muxEnableButton setIntegerValue:8];
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
    if ([_httpHostsField stringValue] == nil) {
        httpHosts = @[];
    } else {
        NSString* hostsString = [[_httpHostsField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
        httpHosts = [hostsString componentsSeparatedByString:@","];
    }
    [settingAlert beginSheetModalForWindow:_transportWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            //save settings
            
            NSDictionary *streamSettings =
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
                      @"serverName": nilCoalescing([self->_tlsSnField stringValue], @""),
                      @"allowInsecure": [NSNumber numberWithBool:[self->_tlsAiButton state]==1],
              },
              @"httpSettings": @{
                      @"host": httpHosts,
                      @"path": nilCoalescing([self->_httpPathField stringValue], @"")
                      }
              };
            NSDictionary* muxSettings = @{
                                          @"enabled":[NSNumber numberWithBool:[self->_muxEnableButton state]==1],
                                          @"concurrency":[NSNumber numberWithInteger:[self->_muxConcurrencyField integerValue]]
                                          };
            NSDictionary* proxySettings = @{@"address": nilCoalescing([self->_proxyAddressField stringValue], @""), @"port": @([self->_proxyPortField integerValue])};
            self.selectedProfile.muxSettings = muxSettings;
            self.selectedProfile.streamSettings = streamSettings;
            self.selectedProfile.proxySettings = proxySettings;
            //close sheet
            [[self window] endSheet:self->_transportWindow];
        }
    }];
}
- (IBAction)showKcpHeaderExample:(id)sender {
    runCommandLine(@"/usr/bin/open", @[[[NSBundle mainBundle] pathForResource:@"tcp_http_header_example" ofType:@"txt"], @"-a", @"/Applications/TextEdit.app"]);
}

- (IBAction)useTLS:(id)sender {
    [_tlsAiButton setEnabled:[_tlsUseButton state]];
    [_tlsSnField setEnabled:[_tlsUseButton state]];
}

- (IBAction)transportHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://v2ray.com/chapter_02/05_transport.html"]];
}

- (IBAction)showLog:(id)sender {
    [appDelegate viewLog:sender];
}

@synthesize selectedProfile;
@synthesize appDelegate;
@end
