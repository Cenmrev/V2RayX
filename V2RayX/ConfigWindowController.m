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
#import "ConfigImporter.h"

@interface ConfigWindowController ()

@property (strong) TransportWindowController* transportWindowController;
@property (strong) AdvancedWindowController* advancedWindowController;
@property (strong) NSPopover* popover;
@end

@implementation ConfigWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* v2rayPath = [self.appDelegate getV2rayPath];
        
        NSTask *task = [[NSTask alloc] init];
        if (@available(macOS 10.13, *)) {
            [task setExecutableURL:[NSURL fileURLWithPath:v2rayPath]];
        } else {
            [task setLaunchPath:v2rayPath];
        }
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
    [_profileTable setFocusRingType:NSFocusRingTypeNone];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    [_portField setFormatter:formatter];
    [_alterIdField setFormatter:formatter];
    [_localPortField setFormatter:formatter];
    [_httpPortField setFormatter:formatter];
//    [_addRemoveButton setMenu:_importFromJsonMenu forSegment:2];
    
    // copy data
    _profiles = [[NSMutableArray alloc] init];
    _outbounds = [[NSMutableArray alloc] init];
    for (NSDictionary *p in _appDelegate.profiles) {
        if ([@"vmess" isEqualToString:p[@"protocol"]] && [p[@"settings"][@"vnext"] count] == 1) {
            [_profiles addObject:[ServerProfile profilesFromJson:p][0]];
        } else {
            [_outbounds addObject:p];
        }
    }
    _cusProfiles = [_appDelegate.cusProfiles mutableDeepCopy];
    _subscriptions = [_appDelegate.subscriptions mutableCopy];
    
    _routingRuleSets = [_appDelegate.routingRuleSets mutableCopy];
    //
    [_profileTable reloadData];
    self.selectedServerIndex = 0;
    self.selectedCusServerIndex = 0;
    self.httpPort = _appDelegate.httpPort;
    self.localPort = _appDelegate.localPort;
    self.udpSupport = _appDelegate.udpSupport;
    self.shareOverLan = _appDelegate.shareOverLan;
    self.dnsString = _appDelegate.dnsString;
    self.enableRestore = _appDelegate.enableRestore;
    self.enableEncryption = _appDelegate.enableEncryption;
    self.encryptionKey = [NSString stringWithString:_appDelegate.encryptionKey];
    NSDictionary *logLevelDic = @{
                               @"debug": @4,
                               @"info": @3,
                               @"warning": @2,
                               @"error":@1,
                               @"none":@0
                               };
    self.logLevel = [logLevelDic[_appDelegate.logLevel] integerValue];
    
    [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:self.selectedServerIndex] byExtendingSelection:NO];
    [[self window] makeFirstResponder:_profileTable];
}

// set controller as profilesTable's datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == _profileTable) {
        return [_profiles count];
    }
    return 0;
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
}

- (IBAction)chooseNetwork:(NSPopUpButton *)sender {
    if (_selectedServerIndex >= 0 && _selectedServerIndex < [_profiles count]) {
        [self checkTLSforHttp2];
    }
}

- (BOOL)checkTLSforHttp2 {
    if ([_networkButton indexOfSelectedItem] == 3) { // selected http/2
        BOOL tlsEnabled = [self.selectedProfile.streamSettings[@"security"] isEqual: @"tls"];
        if (!tlsEnabled) {
            NSAlert *httpTlsAlerm = [[NSAlert alloc] init];
            [httpTlsAlerm addButtonWithTitle:@"Close"];
            [httpTlsAlerm addButtonWithTitle:@"Help"];
            [httpTlsAlerm setMessageText:@"Both client and server must enable TLS to use HTTP/2 network! Enbale TLS in transport settings. Click \"Help\" if you need more information"];
            [httpTlsAlerm beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSAlertSecondButtonReturn) {
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com/chapter_02/transport/h2.html#tips"]];
                }
            }];
            [_networkButton selectItemAtIndex:0];
            return NO; // does not pass checking
        }
    }
    return true; //  pass checking
}

- (IBAction)addRemoveServer:(id)sender {
    [[self window] makeFirstResponder:_profileTable];
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
    }
    else if ([sender selectedSegment] == 2) {
        // share server
    } else if ([sender selectedSegment] == 3) {
        // duplicate
        if (_selectedServerIndex >= 0 && _selectedServerIndex < [_profiles count]) {
            [_profiles addObject:[_profiles[_selectedServerIndex] deepCopy]];
            [_profileTable reloadData];
        }
    }
}

- (IBAction)importConfigs:(id)sender {
    [NSMenu popUpContextMenu:_importFromJsonMenu withEvent:[NSApp currentEvent] forView:sender];
}

- (IBAction)cancel:(id)sender {
    [[self window] close];
}

- (NSString*)firstFewLines:(NSDictionary*)dict {
    NSInteger limit = 13;
    NSString* str = [dict description];
    NSArray* lines = [str componentsSeparatedByString:@"\n"];
    if (lines.count < limit) {
        return str;
    } else {
        NSString* r = [[lines subarrayWithRange:NSMakeRange(0, limit)] componentsJoinedByString:@"\n"];
        return [NSString stringWithFormat:@"%@\n...", r];
    }
}

- (IBAction)okSave:(id)sender {
    if (![self checkTLSforHttp2]) {
        return;
    }
    NSMutableArray *allOutbounds = [[NSMutableArray alloc] init];
    for (ServerProfile* p in _profiles) {
        [allOutbounds addObject:[p outboundProfile]];
    }
    for (NSMutableDictionary* p in _outbounds) {
        [allOutbounds addObject:p];
    }
    NSMutableDictionary *allOutboundDict =[[NSMutableDictionary alloc] init];
    for (NSMutableDictionary* outbound in allOutbounds) {
        if (!outbound[@"tag"] || ![outbound[@"tag"] isKindOfClass:[NSString class]] || [outbound[@"tag"] length] == 0) {
            [self showAlert: [NSString stringWithFormat:@"%@\ntag is not valid!", [self firstFewLines:outbound]]];
            return;
        }
        if ([RESERVED_TAGS indexOfObject:outbound[@"tag"]] != NSNotFound) {
            [self showAlert: [NSString stringWithFormat:@"tag %@ is reserved, please use another one!", outbound[@"tag"]]];
            return;
        }
        if (allOutboundDict[outbound[@"tag"]]) {
            [self showAlert: [NSString stringWithFormat:@"The two outbounds share the same tag: %@\n%@\nAND\n%@",outbound[@"tag"], [self firstFewLines:outbound], [self firstFewLines:allOutboundDict[outbound[@"tag"]]]]];
            return;
        }
        allOutboundDict[outbound[@"tag"]] = outbound;
    }
    _appDelegate.profiles = allOutbounds;
    NSString* dnsStr = [[_dnsField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([dnsStr length] == 0) {
        dnsStr = @"localhost";
    }
    _appDelegate.logLevel = _logLevelButton.selectedItem.title;
    _appDelegate.localPort = [_localPortField integerValue];
    _appDelegate.httpPort = [_httpPortField integerValue];
    _appDelegate.udpSupport = self.udpSupport;
    _appDelegate.shareOverLan = self.shareOverLan;
    _appDelegate.dnsString = dnsStr;
    _appDelegate.cusProfiles = self.cusProfiles;
    _appDelegate.subscriptions = self.subscriptions;
    _appDelegate.enableRestore = self.enableRestore;
    [_appDelegate.routingRuleSets removeAllObjects];
    for (NSMutableDictionary* set in self.routingRuleSets) {
        NSMutableDictionary* validatedSet = [ConfigImporter validateRuleSet:set];
        if (validatedSet) {
            [_appDelegate.routingRuleSets addObject:validatedSet];
        }
    }
    if (_appDelegate.routingRuleSets.count == 0) {
        [_appDelegate.routingRuleSets addObject:[ROUTING_DIRECT mutableDeepCopy]];
    }
    _appDelegate.enableEncryption = self.enableEncryption;
    _appDelegate.encryptionKey = self.encryptionKey;
    [_appDelegate saveConfigInfo];
    [_appDelegate updateSubscriptions:self];
    [[self window] close];
}

- (IBAction)showAdvancedWindow:(NSButton *)sender {
    self.advancedWindowController = [[AdvancedWindowController alloc] initWithWindowNibName:@"AdvancedWindow" parentController:self];
    [[self window] beginSheet:self.advancedWindowController.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            self.outbounds = self.advancedWindowController.outbounds;
            self.cusProfiles = self.advancedWindowController.configs;
            self.routingRuleSets = self.advancedWindowController.routingRuleSets;
            self.subscriptions = self.advancedWindowController.subscriptions;
            self.enableRestore = self.advancedWindowController.enableRestore;
            self.enableEncryption = self.advancedWindowController.enableEncryption;
            self.encryptionKey = self.advancedWindowController.encryptionKey;
        }
        self.advancedWindowController = nil;
    }];
}


- (IBAction)showTransportSettings:(id)sender {
    if ([_profiles count] == 0) {
        return;
    }
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
- (void)askInputWithPrompt: (NSString*)prompt handler:(void (^ __nullable)(NSString* inputStr))handler {
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = prompt;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    NSTextField *inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 24)];
    inputField.usesSingleLineMode = true;
    inputField.lineBreakMode = NSLineBreakByTruncatingHead;
    [alert setAccessoryView:inputField];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            handler([inputField stringValue]);
        }
    }];
}

- (void)showAlert:(NSString*)text {
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setInformativeText:text];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        ;
    }];
}

- (IBAction)importFromStandardLink:(id)sender {
    [self askInputWithPrompt:@"Support standard vmess:// and ss:// link. Standard vmess:// link is still under discussion. Use \"Import from other links...\" to import other links, for example, vmess:// invented by v2rayN." handler:^(NSString *inputStr) {
        if (inputStr.length) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSMutableDictionary* ssOutbound = [ConfigImporter ssOutboundFromSSLink:inputStr];
                if (ssOutbound) {
                    [self.outbounds addObject:ssOutbound];
                    [self presentImportResultOfVmessCount:0 otherCount:1 ruleSetCount:0];
                } else {
                    [self presentImportResultOfVmessCount:0 otherCount:0 ruleSetCount:0];
                }
            });
        }
    }];
}

- (void)presentImportResultOfVmessCount:(NSInteger)vmessCount otherCount:(NSInteger)otherCount  ruleSetCount:(NSInteger)ruleSetCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_profileTable reloadData];
        self.popover = [[NSPopover alloc] init];
        self.importMessageField.stringValue = [NSString stringWithFormat:@"Imported %lu vmess and %lu other protocol outbounds, %lu routing rule sets.", vmessCount, otherCount, ruleSetCount];
        self.popover.contentViewController = [[NSViewController alloc] init];
        self.popover.contentViewController.view = self.importResultView;
        self.popover.behavior = NSPopoverBehaviorTransient;
        [self.popover showRelativeToRect:[self.importButton bounds] ofView:self.importButton preferredEdge:NSMaxYEdge];
    });

}

- (IBAction)importFromMiscLinks:(id)sender {
    [self askInputWithPrompt:@"V2RayX will try importing ssd://, vmess:// and http(s):// links from v2rayN and SSD(may cause failure)." handler:^(NSString *inputStr) {
        inputStr = [inputStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([inputStr length] != 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                ServerProfile* p = [ConfigImporter importFromVmessOfV2RayN:inputStr];
                NSInteger vmessCount = 0;
                NSInteger otherCount = 0;
                if (p) {
                    [self.profiles addObject:p];
                    vmessCount = 1;
                }
                NSDictionary* ssdResult = [ConfigImporter importFromSubscriptionOfSSD:inputStr];
                for (NSDictionary* d in ssdResult[@"other"]) {
                    [self.outbounds addObject:[d mutableDeepCopy]];
                    otherCount += 1;
                }
                NSMutableDictionary* p2 = [ConfigImporter importFromHTTPSubscription:inputStr];
                if (p2) {
                    [self.profiles addObjectsFromArray:p2[@"vmess"]];
                    [self.outbounds addObjectsFromArray:p2[@"other"]];
                    vmessCount += [p2[@"vmess"] count];
                    otherCount += [p2[@"other"] count];
                }
                [self presentImportResultOfVmessCount:vmessCount otherCount:otherCount ruleSetCount:0];
            });
        }
    }];
}

- (IBAction)importFromJSONFiles:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowedFileTypes:@[@"json"]];
    [openPanel setDirectoryURL:[[NSFileManager defaultManager] homeDirectoryForCurrentUser]];

    [openPanel beginSheetModalForWindow:[self window]  completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSArray* files = [openPanel URLs];
                NSMutableDictionary* result = [ConfigImporter importFromStandardConfigFiles:files];
                [self.profiles addObjectsFromArray:result[@"vmess"]];
                [self.outbounds addObjectsFromArray:result[@"other"]];
                [self.routingRuleSets addObjectsFromArray:result[@"rules"]];
                [self presentImportResultOfVmessCount:[result[@"vmess"] count] otherCount:[result[@"other"] count] ruleSetCount:[result[@"rules"] count]];
            });
        }
    }];
}

- (IBAction)showLog:(id)sender {
    [_appDelegate viewLog:sender];
}

@end
