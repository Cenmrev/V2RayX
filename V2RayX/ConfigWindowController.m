//
//  ConfigWindowController.m
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import "ConfigWindowController.h"
#import "AppDelegate.h"
#import "MutableDeepCopying.h"
#import "TransportWindowController.h"
#import "AdvancedWindowController.h"

@interface ConfigWindowController ()

@property (strong) TransportWindowController* transportWindowController;
@property (strong) AdvancedWindowController* advancedWindowController;

@end

@implementation ConfigWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* v2rayPath = [self->appDelegate getV2rayPath];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:v2rayPath];
        [task setArguments:@[@"-version"]];
        NSPipe *stdoutpipe = [NSPipe pipe];
        [task setStandardOutput:stdoutpipe];
        [task launch];
        [task waitUntilExit];
        NSFileHandle *file = [stdoutpipe fileHandleForReading];
        NSData *data = [file readDataToEndOfFile];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_versionField setStringValue:[string componentsSeparatedByString:@"\n"][0]];
             });
        
    });
    
    [_networkButton removeAllItems];
    for(NSString* network in NETWORK_LIST) {
        [_networkButton addItemWithTitle:network];
    }
    [_vmessSecurityButton removeAllItems];
    for(NSString* security in VMESS_SECURITY_LIST) {
        [_vmessSecurityButton addItemWithTitle:security];
    }
    
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
    _outbounds = [[NSMutableArray alloc] init];
    for (NSDictionary *p in appDelegate.profiles) {
        if ([@"vmess" isEqualToString:p[@"protocol"]] && [p[@"settings"][@"vnext"] count] == 1) {
            [_profiles addObject:[ServerProfile profilesFromJson:p][0]];
        } else {
            [_outbounds addObject:p];
        }
    }
    _cusProfiles = [[NSMutableArray alloc] init];
    for (NSString* p in appDelegate.cusProfiles) {
        [_cusProfiles addObject:[NSString stringWithString:p]];
    }
    //
    [_profileTable reloadData];
    self.selectedServerIndex = 0;
    self.selectedCusServerIndex = 0;
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
            return [[p outboundTag] length] > 0 ? [p outboundTag] : [NSString stringWithFormat:@"%@:%ld", [p address], [p port]];
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
//            NSLog(@"selectef p =  %@", _profiles[_selectedServerIndex]);
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
    appDelegate.localPort = [_localPortField integerValue];
    appDelegate.httpPort = [_httpPortField integerValue];
    appDelegate.udpSupport = self.udpSupport;
    appDelegate.shareOverLan = self.shareOverLan;
    appDelegate.dnsString = dnsStr;
    NSMutableArray *allOutbounds = [[NSMutableArray alloc] init];
    for (ServerProfile* p in _profiles) {
        [allOutbounds addObject:[p outboundProfile]];
    }
    for (NSDictionary* p in _outbounds) {
        [allOutbounds addObject:p];
    }
    appDelegate.profiles = allOutbounds;
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
    self.advancedWindowController = [[AdvancedWindowController alloc] initWithWindowNibName:@"AdvancedWindow" parentController:self];
    [[self window] beginSheet:self.advancedWindowController.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            self.outbounds = self.advancedWindowController.outbounds;
            self.cusProfiles = self.advancedWindowController.configs;
        }
        self.advancedWindowController = nil;
    }];
}


- (IBAction)showTransportSettings:(id)sender {
    self.transportWindowController = [[TransportWindowController alloc] initWithWindowNibName:@"TransportWindow" parentController:self];
    [[self window] beginSheet:self.transportWindowController.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            NSArray* a = [self->_transportWindowController generateSettings];
            self.selectedProfile.streamSettings = a[0];
            self.selectedProfile.muxSettings = a[1];
        }
        self.transportWindowController = nil;
    }];
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

- (void)importFromVmess:(NSString*)vmessStr {
    if ([vmessStr length] < 9 || ![[[vmessStr substringToIndex:8] lowercaseString] isEqualToString:@"vmess://"]) {
//        [self showAlert:@"Not a vmess:// link!"];
        return;
    }
//    NSLog(@"%@", vmessStr);
//    NSLog(@"%@", [vmessStr substringFromIndex:8]);
    // https://stackoverflow.com/questions/19088231/base64-decoding-in-ios-7
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:[vmessStr substringFromIndex:8] options:0];
    if (!decodedData) {
        [self showAlert:@"Not a valid link!"];
        return;
    }
    NSError* jsonParseError;
    NSDictionary *sharedServer = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:&jsonParseError];
    if (jsonParseError) {
        [self showAlert:@"Not a valid link!"];
        return;
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
//    NSDictionary *securityDict = @{@"aes-128-cfb":@0, @"aes-128-gcm":@1, @"chacha20-poly1305":@2, @"auto":@3, @"none":@4};
//    if ([sharedServer objectForKey:@"type"] && [securityDict objectForKey:[sharedServer objectForKey:@"type"]]) {
//        newProfile.security = [securityDict[sharedServer[@"type"]] intValue];
//    }
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
    }
    newProfile.streamSettings = streamSettings;
    [_profiles addObject:newProfile];
    [_profileTable reloadData];
    [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:([_profiles count] - 1)] byExtendingSelection:NO];
}
    
- (IBAction)subscribeV2rayN:(id)sender {
    /* https://github.com/2dust/v2rayN/wiki/订阅功能说明 */
    NSString* inputStr = [[self input:@"Please input the server info. " defaultValue:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([inputStr length] == 0) {
        return;
    }
    // https://blog.csdn.net/yi_zz32/article/details/48769487
    NSURL *url = [NSURL URLWithString:inputStr];
    NSError *urlError = nil;
    NSString *urlStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&urlError];
    if (!urlError) {
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:urlStr options:0];
        if (!decodedData) {
            [self showAlert:@"Not a valid link!"];
            return;
        }
        NSString *decodedDataStr = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        decodedDataStr = [decodedDataStr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSArray *decodedDataArray = [decodedDataStr componentsSeparatedByString:@"\n"];
        for (id linkStr in decodedDataArray) {
            if ([linkStr length] != 0) {
//                NSLog(@"%@", linkStr);
                [self importFromVmess:linkStr];
            }
        }
    }
    else {
        [self showAlert:@"Open the subscription link failed!"];
        return;
    }
}

- (IBAction)importFromQRCodeV2rayN:(id)sender {
    /* https://github.com/2dust/v2rayN/wiki/分享链接格式说明(ver-2) */
    NSString* inputStr = [[self input:@"Please input the server info. Format: vmess://" defaultValue:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([inputStr length] == 0) {
        return;
    }
    else {
        [self importFromVmess:inputStr];
    }
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
                    [s setOutboundTag:[NSString stringWithFormat:@"imported %@", s.outboundTag]];
                }
                [self->_profiles addObjectsFromArray:servers];
            }
        }
        [self->_profileTable reloadData];
    }];
}

- (IBAction)showLog:(id)sender {
    [appDelegate viewLog:sender];
}

@synthesize appDelegate;

@end
