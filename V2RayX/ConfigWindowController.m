//
//  ConfigWindowController.m
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import "ConfigWindowController.h"

@interface ConfigWindowController () {
    NSMutableArray *profiles;
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
    
    profiles = [[NSMutableArray alloc] init];
    
    NSDictionary *defaultsDic = [[self delegate] readDefaultsAsDictionary];
    [self setLocalPort:[defaultsDic[@"localPort"] integerValue]];
    [self setHttpPort:[defaultsDic[@"httpPort"] integerValue]];
    [self setUdpSupport:[defaultsDic[@"udpSupport"] boolValue]];
    [self setShareOverLan:[defaultsDic[@"shareOverLan"] boolValue]];
    if ([defaultsDic[@"dns"] length] > 0) {
        [self setDnsString:defaultsDic[@"dns"]];
    } else {
        [self setDnsString:@"localhost"];
    }
    profiles = defaultsDic[@"profiles"];
    [_profileTable reloadData];
    _selectedServerIndex = [defaultsDic[@"selectedServerIndex"] integerValue];
    [_profileTable selectRowIndexes:[[NSIndexSet alloc] initWithIndex:_selectedServerIndex] byExtendingSelection:NO];
}

// set controller as profilesTable's datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [profiles count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([profiles count] > 0) {
        ServerProfile* p = [profiles objectAtIndex:row];
        return [p address];
    } else {
        return nil;
    }
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex{
    [selectedProfile setAddress:anObject];
    [aTableView reloadData];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    if ([profiles count] > 0) {
        [self setSelectedProfile:[profiles objectAtIndex:[_profileTable selectedRow]]];
        [self setSelectedServerIndex:[_profileTable selectedRow]];
    }
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
    // save settings to file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:udpSupport]  forKey:@"udpSupport"];
    [defaults setObject:[NSNumber numberWithBool:shareOverLan]  forKey:@"shareOverLan"];
    [defaults setObject:[NSNumber numberWithInteger:localPort] forKey:@"localPort"];
    [defaults setObject:[NSNumber numberWithInteger:httpPort] forKey:@"httpPort"];
    NSMutableArray* profileDicArray = [[NSMutableArray alloc] init];
    for (ServerProfile *p in profiles) {
        [profileDicArray addObject:[p dictionaryForm]];
    }
    [defaults setObject:profileDicArray forKey:@"profiles"];
    [defaults setObject:[NSNumber numberWithInteger:_selectedServerIndex] forKey:@"selectedServerIndex"];
    NSString* dnsStr = [[_dnsField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([dnsStr length] == 0) {
        dnsStr = @"localhost";
    }
    [defaults setObject:dnsStr forKey:@"dns"];
    [[self delegate] configurationDidChange];
    [[self window] close];
}

- (IBAction)showtransportSettings:(id)sender {
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
    //read settings
    NSDictionary *transportSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"transportSettings"];
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
    [_tcpCrButton setState:[transportSettings[@"tcpSettings"][@"connectionReuse"] boolValue]];
    [_tcpHeaderTypeButton selectItemAtIndex:[transportSettings[@"tcpSettings"][@"header"][@"type"] isEqualToString:@"http"] ? 1 : 0];
    //websocket
    [_wsCrButton setState:[transportSettings[@"wsSettings"][@"connectionReuse"] boolValue]];
    NSString *savedWsPath = transportSettings[@"wsSettings"][@"path"];
    [_wsPathField setStringValue: savedWsPath != nil ? savedWsPath : @""];
    //tls
    [_tlsUseButton setState:[[[NSUserDefaults standardUserDefaults] objectForKey:@"useTLS"] boolValue]];
    NSDictionary* tlsSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"tlsSettings"];
    [_tlsAiButton setState:[tlsSettings[@"allowInsecure"] boolValue]];
    if (tlsSettings[@"serverName"]) {
        [_tlsSnField setStringValue:tlsSettings[@"serverName"]];
    }
    [self useTLS:nil];
    // mux
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"mux"] != nil) {
        NSNumber* enableDefault = [[defaults objectForKey:@"mux"] objectForKey:@"enabled"];
        NSNumber* concurrencyDefault = [[defaults objectForKey:@"mux"] objectForKey:@"concurrency"];
        [_muxEnableButton setState:enableDefault==nil?NO:[enableDefault boolValue]];
        [_muxConcurrencyField setIntegerValue:concurrencyDefault==nil?8:[concurrencyDefault integerValue]];
    } else {
        [_muxEnableButton setState:NO];
        [_muxConcurrencyField setIntegerValue:8];
    }
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
    [_tcpCrButton setState:1];
    [_tcpHeaderTypeButton selectItemAtIndex:0];
    //ws fields
    [_wsCrButton setState:1];
    [_wsPathField setStringValue:@""];
    //mux fields
    [_muxEnableButton setState:0];
    [_muxEnableButton setIntegerValue:8];
    
    
}
- (IBAction)tCancel:(id)sender {
    [[self window] endSheet:_transportWindow];
}
- (IBAction)tOK:(id)sender {
    NSAlert* settingAlert = [[NSAlert alloc] init];
    [settingAlert setMessageText:@"Make sure you have read the help before clicking OK!"];
    [settingAlert addButtonWithTitle:@"Yes, save!"];
    [settingAlert addButtonWithTitle:@"Do not save."];
    [settingAlert beginSheetModalForWindow:_transportWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            //save settings
            NSDictionary *transportSettings =
            @{@"kcpSettings":
                  @{@"mtu":[NSNumber numberWithInteger:[_kcpMtuField integerValue]],
                    @"tti":[NSNumber numberWithInteger:[_kcpTtiField integerValue]],
                    @"uplinkCapacity":[NSNumber numberWithInteger:[_kcpUcField integerValue]],
                    @"downlinkCapacity":[NSNumber numberWithInteger:[_kcpDcField integerValue]],
                    @"readBufferSize":[NSNumber numberWithInteger:[_kcpRbField integerValue]],
                    @"writeBufferSize":[NSNumber numberWithInteger:[_kcpWbField integerValue]],
                    @"congestion":[NSNumber numberWithBool:[_kcpCongestionButton indexOfSelectedItem] != 0],
                    @"header":@{@"type":[[_kcpHeaderTypeButton selectedItem] title]}
                    },
              @"tcpSettings":
                  @{@"connectionReuse": [NSNumber numberWithBool:[_tcpCrButton state]],
                    @"header":@{@"type":[[_tcpHeaderTypeButton selectedItem] title]}
                    },
              @"wsSettings": @{
                  @"connectionReuse": [NSNumber numberWithBool:[_wsCrButton state]],
                  @"path": [_wsPathField stringValue] != nil ? [_wsPathField stringValue] : @""
                  }
              };
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:transportSettings forKey:@"transportSettings"];
            [defaults setObject:[NSNumber numberWithBool:[_tlsUseButton state]] forKey:@"useTLS"];
            [defaults setObject:@{
                                  @"allowInsecure": [NSNumber numberWithBool:[_tlsAiButton state]],
                                  @"serverName": [_tlsSnField stringValue]
                                  } forKey:@"tlsSettings"];
            [defaults setObject:@{@"enabled":[NSNumber numberWithBool:[_muxEnableButton state]],
                                  @"concurrency":[NSNumber numberWithInteger:[_muxConcurrencyField integerValue]]
                                  } forKey:@"mux"];
            //close sheet
            [[self window] endSheet:_transportWindow];
        }
    }];
}

- (IBAction)useTLS:(id)sender {
    [_tlsAiButton setEnabled:[_tlsUseButton state]];
    [_tlsSnField setEnabled:[_tlsUseButton state]];
}

- (IBAction)transportHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com/chapter_02/05_transport.html"]];
}
@synthesize selectedProfile;
@synthesize localPort;
@synthesize httpPort;
@synthesize udpSupport;
@synthesize shareOverLan;
@synthesize dnsString;
@end
