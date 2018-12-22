//
//  AppDelegate.m
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import "AppDelegate.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "ConfigWindowController.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "ServerProfile.h"
#import "MutableDeepCopying.h"

#define kUseAllServer -10

@interface AppDelegate () {
    GCDWebServer *webServer;
    ConfigWindowController *configWindowController;

    dispatch_queue_t taskQueue;
    dispatch_source_t dispatchPacSource;
    FSEventStreamRef fsEventStream;
    
    NSData* v2rayJSONconfig;
}

@end

@implementation AppDelegate

static AppDelegate *appDelegate;

- (NSData*)v2rayJSONconfig {
    return v2rayJSONconfig;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    profiles = [[NSMutableArray alloc] init];
    cusProfiles = [[NSMutableArray alloc] init];
    _routingRuleSets = [[NSMutableArray alloc] init];
    [self readDefaults];
    v2rayJSONconfig = [[NSData alloc] init];
    
    // create a serial queue used for NSTask operations
    taskQueue = dispatch_queue_create("cenmrev.v2rayx.nstask", DISPATCH_QUEUE_SERIAL);
    
    if (![self installHelper:false]) {
        [[NSApplication sharedApplication] terminate:nil];// installation failed or stopped by user,
    };
    
    _statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusBarItem setMenu:_statusBarMenu];
    [_statusBarItem setHighlightMode:YES];
    
    plistPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/cenmrev.v2rayx.v2ray-core.plist",NSHomeDirectory()];
    //pacPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/pac/pac.js",NSHomeDirectory()];
    pacPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/pac/%@",NSHomeDirectory(), selectedPacPath];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString *pacDir = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/pac", NSHomeDirectory()];
    //create application support directory and pac directory
    if (![fileManager fileExistsAtPath:pacDir]) {
        [fileManager createDirectoryAtPath:pacDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //check if pac file exist
    if (![fileManager fileExistsAtPath:pacPath]) {
        NSString* simplePac = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"pac"];
        [fileManager copyItemAtPath:simplePac toPath:pacPath error:nil];
    }
    
    // Create Log Dir
    do {
        NSString* logDirName = [NSString stringWithFormat:@"cenmrev.v2rayx.log.%@",
                                [[NSUUID UUID] UUIDString]];
        logDirPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), logDirName];
    } while ([fileManager fileExistsAtPath:logDirPath]);
    [fileManager createDirectoryAtPath:logDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[NSString stringWithFormat:@"%@/access.log", logDirPath] contents:nil attributes:nil];
    [fileManager createFileAtPath:[NSString stringWithFormat:@"%@/error.log", logDirPath] contents:nil attributes:nil];
    
    // set up pac server
    __weak typeof(self) weakSelf = self;
    //http://stackoverflow.com/questions/14556605/capturing-self-strongly-in-this-block-is-likely-to-lead-to-a-retain-cycle
    webServer = [[GCDWebServer alloc] init];
    [webServer addHandlerForMethod:@"GET" path:@"/proxy.pac" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [GCDWebServerDataResponse responseWithData:[weakSelf pacData] contentType:@"application/x-ns-proxy-autoconfig"];
    }];
    [webServer addHandlerForMethod:@"GET" path:@"/config.json" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [GCDWebServerDataResponse responseWithData:[weakSelf v2rayJSONconfig] contentType:@"application/json"];
    }];
    NSNumber* setingVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"setingVersion"];
    if(setingVersion == nil || [setingVersion integerValue] != kV2RayXSettingVersion) {
        NSAlert *noServerAlert = [[NSAlert alloc] init];
        [noServerAlert setMessageText:@"If you are running V2RayX for the first time, ignore this message. \nSorry, unknown settings!\nAll V2RayX settings will be reset."];
        [noServerAlert runModal];
        [self writeDefaultSettings]; //explicitly write default settings to user defaults file
    }
//    profiles = [[NSMutableArray alloc] init];
//    cusProfiles = [[NSMutableArray alloc] init];
//    [self readDefaults];
    // back up proxy settings
    if (proxyState == true && proxyMode != manual) {
        [self backupSystemProxy];
    }
    [self configurationDidChange];
    
    //https://randexdev.com/2012/03/how-to-detect-directory-changes-using-gcd/
    int fildes = open([pacPath cStringUsingEncoding:NSUTF8StringEncoding], O_RDONLY);
    dispatchPacSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fildes, DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_event_handler(dispatchPacSource, ^{
        NSLog(@"pac changed");
        [appDelegate updateSystemProxy];
    });
    dispatch_resume(dispatchPacSource);
    
    appDelegate = self;
    
    // resume the service when mac wakes up
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(configurationDidChange) name:NSWorkspaceDidWakeNotification object:NULL];
}

- (void) writeDefaultSettings {
    NSDictionary *defaultSettings =
    @{
      @"setingVersion": [NSNumber numberWithInteger:kV2RayXSettingVersion],
      @"logLevel": @"none",
      @"proxyState": [NSNumber numberWithBool:NO],
      @"proxyMode": @(manual),
      @"selectedServerIndex": [NSNumber numberWithInteger:0],
      @"localPort": [NSNumber numberWithInteger:1081],
      @"httpPort": [NSNumber numberWithInteger:8001],
      @"udpSupport": [NSNumber numberWithBool:NO],
      @"shareOverLan": [NSNumber numberWithBool:NO],
      @"dnsString": @"localhost",
      @"profiles":@[
              [[[ServerProfile alloc] init] outboundProfile]
              ],
      @"selectedCusServerIndex": [NSNumber numberWithInteger:-1],
      @"useCusProfile": @NO,
      @"cusProfiles": @[],
      @"routingRuleSets": @[ROUTING_DIRECT, ROUTING_GLOBAL, ROUTING_BYPASSCN_PRIVATE_APPLE],
      @"selectedRoutingSet":@0,
      @"useMultipleServer": @NO
      };
    for (NSString* key in [defaultSettings allKeys]) {
        [[NSUserDefaults standardUserDefaults] setObject:defaultSettings[key] forKey:key];
    }
}

- (NSData*) pacData {
    return [NSData dataWithContentsOfFile:pacPath];
}

- (void)saveConfig {
    NSDictionary *settings =@{
      @"logLevel": logLevel,
      @"proxyState": @(proxyState),
      @"proxyMode": @(proxyMode),
      @"selectedServerIndex": @(selectedServerIndex),
      @"localPort": @(localPort),
      @"httpPort": @(httpPort),
      @"udpSupport": @(udpSupport),
      @"shareOverLan": @(shareOverLan),
      @"dnsString": dnsString,
      @"profiles":profiles,
      @"cusProfiles": cusProfiles,
      @"routingRuleSets": _routingRuleSets,
      @"selectedRoutingSet": @(_selectedRoutingSet),
      @"selectedCusServerIndex": @(selectedCusServerIndex),
      @"useCusProfile": @(useCusProfile),
      @"useMultipleServer": @(useMultipleServer),
      @"selectedPacIndex": @(selectedPacIndex),
      @"selectedPacPath": selectedPacPath
      };
    for (NSString* key in [settings allKeys]) {
        [[NSUserDefaults standardUserDefaults] setObject:settings[key] forKey:key];
    }
    NSLog(@"Settings saved.");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    //stop monitor pac
    if (dispatchPacSource) {
        dispatch_source_cancel(dispatchPacSource);
    }
    //unload v2ray
    runCommandLine(@"/bin/launchctl", @[@"unload", plistPath]);
    NSLog(@"V2RayX quiting, V2Ray core unloaded.");
    //remove log file
    [[NSFileManager defaultManager] removeItemAtPath:logDirPath error:nil];
    //save settings
    [self saveConfig];
    //turn off proxy
    if (proxyState && proxyMode != manual) {
        [self restoreSystemProxy];//restore system proxy
    }
}

- (IBAction)showHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com"]];
}

- (IBAction)enableProxy:(id)sender {
    if(proxyState == false && proxyMode != manual) {
        [self backupSystemProxy];
    }
    if(proxyState == true && proxyMode != manual) {
        [self restoreSystemProxy];
    }
    proxyState = !proxyState;
    [self configurationDidChange];
}

- (IBAction)chooseV2rayRules:(id)sender {
    if(proxyState == true && proxyMode == manual) {
        [self backupSystemProxy];
    }
    proxyMode = rules;
    [self configurationDidChange];
}

- (IBAction)choosePacMode:(id)sender {
    if(proxyState == true && proxyMode == manual) {
    [self backupSystemProxy];
}
    proxyMode = pac;
    [self configurationDidChange];
}

- (IBAction)chooseGlobalMode:(id)sender {
    if(proxyState == true && proxyMode == manual) {
        [self backupSystemProxy];
    }
    proxyMode = global;
    [self configurationDidChange];
}

- (IBAction)chooseManualMode:(id)sender {
    if(proxyState == true && proxyMode != manual) {
        [self restoreSystemProxy];
    }
    proxyMode = manual;
    [self configurationDidChange];
}

- (IBAction)showConfigWindow:(id)sender {
    if (configWindowController) {
        [configWindowController close];
    }
    configWindowController =[[ConfigWindowController alloc] initWithWindowNibName:@"ConfigWindow"];
    configWindowController.appDelegate = self;
    [configWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [configWindowController.window makeKeyAndOrderFront:nil];
}

- (IBAction)editPac:(id)sender {
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:pacPath]]];
}

- (IBAction)resetPac:(id)sender {
    NSAlert *resetAlert = [[NSAlert alloc] init];
    [resetAlert setMessageText:@"The pac file will be reset to the original one coming with V2RayX. Are you sure to proceed?"];
    [resetAlert addButtonWithTitle:@"Yes"];
    [resetAlert addButtonWithTitle:@"Cancel"];
    NSModalResponse response = [resetAlert runModal];
    if(response == NSAlertFirstButtonReturn) {
        NSString* simplePac = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"pac"];
        pacPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/pac/pac.js",NSHomeDirectory()];
        if ([[NSFileManager defaultManager] isWritableFileAtPath:pacPath]) {
            [[NSData dataWithContentsOfFile:simplePac] writeToFile:pacPath atomically:YES];
        } else {
            NSAlert* writePacAlert = [[NSAlert alloc] init];
            [writePacAlert setMessageText:[NSString stringWithFormat:@"%@ is not writable!", pacPath]];
            [writePacAlert runModal];
        }
    }
}

- (IBAction)viewLog:(id)sender {
    if (!useCusProfile) {
        [[NSWorkspace sharedWorkspace] openFile:logDirPath];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"Check %@.", cusProfiles[selectedCusServerIndex]]];
        [alert runModal];
    }
}

- (void)updateMenus {
    if (proxyState) {
        [_v2rayStatusItem setTitle:@"v2ray-core: loaded"];
        [_enabelV2rayItem setTitle:@"Unload core"];
        NSImage *icon = [NSImage imageNamed:@"statusBarIcon"];
        [icon setTemplate:YES];
        [_statusBarItem setImage:icon];
    } else {
        [_v2rayStatusItem setTitle:@"v2ray-core: unloaded"];
        [_enabelV2rayItem setTitle:@"Load core"];
        [_statusBarItem setImage:[NSImage imageNamed:@"statusBarIcon_disabled"]];
        NSLog(@"icon updated");
    }
    [_pacModeItem setState:proxyMode == pac];
    [_manualModeItem setState:proxyMode == manual];
    if (!useCusProfile) {
        [_v2rayRulesItem setState:proxyMode == rules];
        [_globalModeItem setState:proxyMode == global];
        [_v2rayRulesItem setHidden:false];
    } else {
        [_globalModeItem setState:proxyMode == global || proxyMode == rules];
        [_v2rayRulesItem setHidden:YES];
    }
    
}

- (void)updatePacMenuList {
    NSLog(@"updatePacMenuList");
    [_pacListMenu removeAllItems];
    NSString *pacDir = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/pac", NSHomeDirectory()];
//    NSLog(@"updatePacMenuList%@", pacDir);
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *allPath =[manager subpathsAtPath:pacDir];
    int i = 0;
    for (NSString *subPath in allPath) {
        NSString *extString = [subPath pathExtension];
        if (![extString  isEqual: @"js"]){
            continue;
        }
//        NSLog(@"updatePacMenuList: %@", subPath);
        NSString *itemTitle = subPath;
        NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:itemTitle action:@selector(switchPac:) keyEquivalent:@""];
        newItem.state = (i == selectedPacIndex)? 1 : 0;;
        [newItem setTag:i];
        //[newItem setTag:i];
//        if (useMultipleServer){
//            newItem.state = 0;
//        } else {
//            newItem.state = (useCusProfile && i - [profiles count] == selectedCusServerIndex)? 1 : 0;
//        }
        [_pacListMenu addItem:newItem];
        i++;
    }
    [_pacListMenu addItem:[NSMenuItem separatorItem]];
    [_pacListMenu addItem:_editPacMenuItem];
    [_pacsItem setSubmenu:_pacListMenu];
}

-(IBAction)chooseRuleSet:(id)sender {
    _selectedRoutingSet = [sender tag];
    [self configurationDidChange];
}

- (void)updateRuleSetMenuList {
    [_ruleSetMenuList removeAllItems];
    NSInteger i = 0;
    for (NSDictionary* rule in _routingRuleSets) {
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:rule[@"name"] action:@selector(chooseRuleSet:) keyEquivalent:@""];
        item.tag = i;
        item.state = i == _selectedRoutingSet;
        [_ruleSetMenuList addItem:item];
        i += 1;
    }
}

- (void)updateServerMenuList {
    [_serverListMenu removeAllItems];
    if ([profiles count] == 0 && [cusProfiles count] == 0) {
        [_serverListMenu addItem:[[NSMenuItem alloc] initWithTitle:@"no available servers, please add server profiles through config window." action:nil keyEquivalent:@""]];
    } else {
        int i = 0;
        for (NSDictionary *p in profiles) {
            NSString *itemTitle;
            if (p[@"tag"] && [p[@"tag"] length]) {
                itemTitle = [NSString stringWithFormat:@"%@:%@",p[@"protocol"], p[@"tag"]];
            } else {
                itemTitle = p[@"protocol"];
            }
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:itemTitle action:@selector(switchServer:) keyEquivalent:@""];
            [newItem setTag:i];
            if (useMultipleServer){
                newItem.state = 0;
            } else {
                newItem.state = (!useCusProfile && i == selectedServerIndex)? 1 : 0;
            }
            [_serverListMenu addItem:newItem];
            i++;
        }
        if([profiles count] > 1) {
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:@"Use All" action:@selector(switchServer:) keyEquivalent:@""];
            [newItem setTag:kUseAllServer];
            newItem.state = useMultipleServer;
            [_serverListMenu addItem:newItem];
        }
        [_serverListMenu addItem:[NSMenuItem separatorItem]];
        for (NSString* cusProfilePath in cusProfiles) {
            NSString *itemTitle = [[cusProfilePath componentsSeparatedByString:@"/"] lastObject];
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:itemTitle action:@selector(switchServer:) keyEquivalent:@""];
            [newItem setTag:i];
            if (useMultipleServer){
                newItem.state = 0;
            } else {
                newItem.state = (useCusProfile && i - [profiles count] == selectedCusServerIndex)? 1 : 0;
            }
            [_serverListMenu addItem:newItem];
            i+=1;
        }
    }
    [_serversItem setSubmenu:_serverListMenu];
}

- (void)switchPac:(id)sender {
    NSLog(@"%ld", [sender tag]);
    [self setSelectedPacIndex:[sender tag]];
    [self setSelectedPacPath:[sender title]];
    NSLog(@"use pac:select %ld", (long)selectedPacIndex);
    pacPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/pac/%@",NSHomeDirectory(), selectedPacPath];
    int fildes = open([pacPath cStringUsingEncoding:NSUTF8StringEncoding], O_RDONLY);
    dispatchPacSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fildes, DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_event_handler(dispatchPacSource, ^{
        NSLog(@"pac changed");
        [appDelegate updateSystemProxy];
    });
    dispatch_resume(dispatchPacSource);
    proxyMode = pac;
    [self configurationDidChange];
}

- (void)switchServer:(id)sender {
    NSLog(@"%ld", [sender tag]);
    if ([sender tag] >= 0 && [sender tag] < [profiles count]) {
        [self setUseMultipleServer:NO];
        [self setUseCusProfile:NO];
        [self setSelectedServerIndex:[sender tag]];
    } else if ([sender tag] >= [profiles count] && [sender tag] < [profiles count] + [cusProfiles count]) {
        [self setUseMultipleServer:NO];
        [self setUseCusProfile:YES];
        [self setSelectedCusServerIndex:[sender tag] - [profiles count]];
    } else if ([sender tag] == kUseAllServer) {
        [self setUseMultipleServer:YES];
    }
    NSLog(@"use cus pro:%hhd, select %ld, select cus %ld", useCusProfile, (long)selectedServerIndex, selectedCusServerIndex);
    [self configurationDidChange];
}

- (void)readDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    proxyState = [nilCoalescing([defaults objectForKey:@"proxyState"], [NSNumber numberWithBool:NO]) boolValue]; //turn off proxy as default
    proxyMode = [nilCoalescing([defaults objectForKey:@"proxyMode"], [NSNumber numberWithInteger:rules]) integerValue]; // use v2ray rules as defualt mode
    localPort = [nilCoalescing([defaults objectForKey:@"localPort"], @1081) integerValue]; //use 1081 as default local port
    httpPort = [nilCoalescing([defaults objectForKey:@"httpPort"], @8001) integerValue]; //use 8001 as default local http port
    udpSupport = [nilCoalescing([defaults objectForKey:@"udpSupport"], [NSNumber numberWithBool:NO]) boolValue];// do not support udp as default
    shareOverLan = [nilCoalescing([defaults objectForKey:@"shareOverLan"], [NSNumber numberWithBool:NO]) boolValue];
    dnsString = nilCoalescing([defaults objectForKey:@"dnsString"], @"localhost");
    logLevel = nilCoalescing([defaults objectForKey:@"logLevel"], @"none");
    useCusProfile = [nilCoalescing([defaults objectForKey:@"useCusProfile"], [NSNumber numberWithBool:NO]) boolValue];
    selectedPacPath = nilCoalescing([defaults objectForKey:@"selectedPacPath"], @"pac.js");
    id dSelectedPacIndex = [defaults objectForKey:@"selectedPacIndex"];
    if ([dSelectedPacIndex isKindOfClass:[NSNumber class]]) {
        selectedPacIndex = [dSelectedPacIndex integerValue];
    } else {
        selectedPacIndex = 0;
    }
    
    [profiles removeAllObjects];
    
    if ([[defaults objectForKey:@"profiles"] isKindOfClass:[NSArray class]] && [[defaults objectForKey:@"profiles"] count] > 0) {
        for (NSDictionary* aProfile in [defaults objectForKey:@"profiles"]) {
            [profiles addObject:aProfile];
        }
    }
    if ([profiles count] > 0) {
        id dSelectedServerIndex = [defaults objectForKey:@"selectedServerIndex"];
        if ([dSelectedServerIndex isKindOfClass:[NSNumber class]]) {
            selectedServerIndex = [dSelectedServerIndex integerValue];
            if (selectedServerIndex < 0 || selectedServerIndex >= [profiles count]) {
                selectedServerIndex = 0;
            }
        } else {
            selectedServerIndex = 0;
        }
    } else {
        selectedServerIndex = -1;
    }
    if ([profiles count] > 1) {
        id dUseMultipleServer = [defaults objectForKey:@"useMultipleServer"];
        if ([dUseMultipleServer isKindOfClass:[NSNumber class]]) {
            useMultipleServer = [dUseMultipleServer boolValue];
        } else {
            useMultipleServer = NO;
        }
    } else {
        useMultipleServer = NO;
    }
    
    [cusProfiles removeAllObjects];
    if ([[defaults objectForKey:@"cusProfiles"] isKindOfClass:[NSArray class]] && [[defaults objectForKey:@"cusProfiles"] count] > 0) {
        for (id cusPorfile in [defaults objectForKey:@"cusProfiles"]) {
            if ([cusPorfile isKindOfClass:[NSString class]]) {
                [cusProfiles addObject:cusPorfile];
            }
        }
    }
    if ([cusProfiles count] > 0) {
        id dSelectedCusServerIndex = [defaults objectForKey:@"selectedCusServerIndex"];
        if ([dSelectedCusServerIndex isKindOfClass:[NSNumber class]]) {
            selectedCusServerIndex = [dSelectedCusServerIndex integerValue];
            if (selectedCusServerIndex < 0 || selectedCusServerIndex >= [cusProfiles count]) {
                selectedCusServerIndex = 0;
            }
        } else {
            selectedCusServerIndex = 0;
        }
    } else {
        selectedCusServerIndex = -1;
    }
    
    [_routingRuleSets removeAllObjects];
    if ([[defaults objectForKey:@"routingRuleSets"] isKindOfClass:[NSArray class]] && [[defaults objectForKey:@"routingRuleSets"] count] > 0) {
        _routingRuleSets = [[defaults objectForKey:@"routingRuleSets"] mutableDeepCopy];
    } else {
        _routingRuleSets = [@[ROUTING_GLOBAL, ROUTING_DIRECT, ROUTING_BYPASSCN_PRIVATE_APPLE] mutableDeepCopy];
    }
    if ([[defaults objectForKey:@"selectedRoutingSet"] isKindOfClass:[NSNumber class]] && [[defaults objectForKey:@"selectedRoutingSet"] integerValue] < _routingRuleSets.count) {
        _selectedRoutingSet = [[defaults objectForKey:@"selectedRoutingSet"] integerValue];
    } else {
        _selectedRoutingSet = 0;
    }
}


-(void)unloadV2ray {
    dispatch_async(taskQueue, ^{
        runCommandLine(@"/bin/launchctl", @[@"unload", self->plistPath]);
        NSLog(@"V2Ray core unloaded.");
    });
}

- (NSDictionary*)generateConfigFile {
    NSMutableDictionary* fullConfig = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"config-sample_new" ofType:@"plist"]];
    fullConfig[@"log"] = @{
                           @"access": [NSString stringWithFormat:@"%@/access.log", logDirPath],
                           @"error": [NSString stringWithFormat:@"%@/error.log", logDirPath],
                           @"loglevel": logLevel
                           };
    fullConfig[@"inbounds"][0][@"port"] = @(localPort);
    fullConfig[@"inbounds"][0][@"listen"] = shareOverLan ? @"0.0.0.0" : @"127.0.0.1";
    fullConfig[@"inbounds"][0][@"settings"][@"udp"] = [NSNumber numberWithBool:udpSupport];
    fullConfig[@"inbounds"][1][@"port"] = @(httpPort);
    fullConfig[@"inbounds"][1][@"listen"] = shareOverLan ? @"0.0.0.0" : @"127.0.0.1";
    
    NSArray* dnsArray = [dnsString componentsSeparatedByString:@","];
    if ([dnsArray count] > 0) {
        fullConfig[@"dns"][@"servers"] = dnsArray;
    } else {
        fullConfig[@"dns"][@"servers"] = @[@"localhost"];
    }
    if (proxyMode == rules) {
        fullConfig[@"routing"] = [_routingRuleSets[_selectedRoutingSet] mutableDeepCopy];
    } else if (proxyMode == pac) {
        fullConfig[@"routing"] = [ROUTING_BYPASSCN_PRIVATE_APPLE mutableDeepCopy];
    } else {
        fullConfig[@"routing"] = [ROUTING_GLOBAL mutableDeepCopy];
    }
    if (!useMultipleServer) {
        // replace tag main with current selected outbound tag
        NSString* currentMainTag = profiles[selectedServerIndex][@"tag"];
        for (NSMutableDictionary* aRule in fullConfig[@"routing"][@"rules"]) {
            if ([@"main" isEqualToString:aRule[@"outboundTag"]]) {
                aRule[@"outboundTag"] = currentMainTag;
            }
        }
    } else {
        // replace outbound tag main with balancetag
        for (NSMutableDictionary* aRule in fullConfig[@"routing"][@"rules"]) {
            if ([@"main" isEqualToString:aRule[@"outboundTag"]]) {
                [aRule removeObjectForKey:@"outboundTag"];
                [aRule setObject:@"balance" forKey:@"balancerTag"];
            }
        }
        
    }
    // deal with outbound
    NSMutableDictionary* configOutboundDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* allOutbounds = [[NSMutableDictionary alloc] init]; // make sure tag is unique
    for (NSDictionary* outbound in profiles) {
        allOutbounds[outbound[@"tag"]] = [outbound mutableDeepCopy];
    }
    NSArray* allProxyTags = allOutbounds.allKeys;
    allOutbounds[@"direct"] = OUTBOUND_DIRECT;
    allOutbounds[@"decline"] = OUTBOUND_DECLINE;
//    NSLog(@"%@", allOutbounds);
    BOOL usebalance = false;
    for (NSDictionary* rule in fullConfig[@"routing"][@"rules"]) {
        if (rule[@"balancerTag"] && !rule[@"outboundTag"]) {
            // if any rule uses balancer, stop the loop and add a balancer to the routing part
            usebalance = true;
            break;
        } else {
            // pick up all mentioned outbounds in the routing rule set
            if (allOutbounds[rule[@"outboundTag"]]) {
                configOutboundDict[rule[@"outboundTag"]] = allOutbounds[rule[@"outboundTag"]];
            }
        }
    }
    if (usebalance) {
        // if balancer is used, add all outbounds into config file, and add all tags to the balancer selector
        fullConfig[@"routing"][@"balancers"] = @[@{
                                                     @"tag":@"balance",
                                                     @"selector": allProxyTags
                                                     }];
        fullConfig[@"outbounds"] = allOutbounds.allValues;
    } else {
        // otherwise, we convert all collected outbounds into an array
        fullConfig[@"outbounds"] = configOutboundDict.allValues;
    }
    return fullConfig;

}

//- (NSDictionary*)generateConfigFrom:(NSDictionary*)outbound {
//    NSMutableDictionary* fullConfig = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"config-sample" ofType:@"plist"]];
//    fullConfig[@"log"] = @{
//                           @"access": [NSString stringWithFormat:@"%@/access.log", logDirPath],
//                           @"error": [NSString stringWithFormat:@"%@/error.log", logDirPath],
//                           @"loglevel": logLevel
//                           };
//    fullConfig[@"inbound"][@"port"] = @(localPort);
//    fullConfig[@"inbound"][@"listen"] = shareOverLan ? @"0.0.0.0" : @"127.0.0.1";
//    fullConfig[@"inboundDetour"][0][@"listen"] = shareOverLan ? @"0.0.0.0" : @"127.0.0.1";
//    fullConfig[@"inboundDetour"][0][@"port"] = @(httpPort);
//    fullConfig[@"inbound"][@"settings"][@"udp"] = [NSNumber numberWithBool:udpSupport];
//    if (!useMultipleServer) {
//        fullConfig[@"outbound"] = outbound;
//    } else {
//        fullConfig[@"outbound"] = outbound;
//        NSMutableArray* vPoints = [[NSMutableArray alloc] init];
//        for (NSDictionary* aProfile in profiles) {
//            if ([@"vmess" isEqualToString:aProfile[@"protocol"]]) {
//                [vPoints addObject:aProfile[@"settings"][@"vnext"][0]];
//            }
//        }
//        fullConfig[@"outbound"][@"settings"][@"vnext"] = vPoints;
//    }
//    NSArray* dnsArray = [dnsString componentsSeparatedByString:@","];
//    if ([dnsArray count] > 0) {
//        fullConfig[@"dns"][@"servers"] = dnsArray;
//    } else {
//        fullConfig[@"dns"][@"servers"] = @[@"localhost"];
//    }
//    if (proxyMode == rules) {
//        [fullConfig[@"routing"][@"settings"][@"rules"][0][@"domain"] addObject:@"geosite:cn"];
//        [fullConfig[@"routing"][@"settings"][@"rules"][1][@"ip"] addObject:@"geoip:cn"];
//    } else if (proxyMode == manual) {
//        fullConfig[@"routing"][@"settings"][@"rules"] = @[];
//    }
//    return fullConfig;
//}

-(BOOL)loadV2ray {
    if (![webServer isRunning]) {
        [webServer startWithPort:webServerPort bonjourName:nil];
    }
    if (!useMultipleServer && useCusProfile) {
        v2rayJSONconfig = [NSData dataWithContentsOfFile:cusProfiles[selectedCusServerIndex]];
    } else {
        NSDictionary *fullConfig = [self generateConfigFile];
        v2rayJSONconfig = [NSJSONSerialization dataWithJSONObject:fullConfig options:NSJSONWritingPrettyPrinted error:nil];
    }
    [self generateLaunchdPlist:plistPath];
    dispatch_async(taskQueue, ^{
        runCommandLine(@"/bin/launchctl",  @[@"load", self->plistPath]);
    });
    return YES;
}

-(void)generateLaunchdPlist:(NSString*)path {
    NSString* v2rayPath = [self getV2rayPath];
    NSLog(@"use core: %@", v2rayPath);
    NSString *configPath = [NSString stringWithFormat:@"http://127.0.0.1:%d/config.json", webServerPort];
    NSDictionary *runPlistDic = [[NSDictionary alloc] initWithObjects:@[@"v2rayproject.v2rayx.v2ray-core", @[v2rayPath, @"-config", configPath], [NSNumber numberWithBool:YES]] forKeys:@[@"Label", @"ProgramArguments", @"RunAtLoad"]];
    [runPlistDic writeToFile:path atomically:NO];
}

-(NSString*)getV2rayPath {
    NSString* defaultV2ray = [NSString stringWithFormat:@"%@/v2ray", [[NSBundle mainBundle] resourcePath]];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* cusV2ray = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/v2ray-core/v2ray",NSHomeDirectory()];
    for (NSString* binary in @[@"v2ray", @"v2ctl"]) {
        NSString* fullpath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/v2ray-core/%@",NSHomeDirectory(), binary];
        BOOL isDir = YES;
        if (![fileManager fileExistsAtPath:fullpath isDirectory:&isDir] || isDir || ![fileManager setAttributes:@{NSFilePosixPermissions: [NSNumber numberWithShort:0777]} ofItemAtPath:fullpath error:nil]) {
            return defaultV2ray;
        }
    }
    for (NSString* data in @[@"geoip.dat", @"geosite.dat"]) {
        NSString* fullpath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/v2ray-core/%@",NSHomeDirectory(), data];
        BOOL isDir = YES;
        if (![fileManager fileExistsAtPath:fullpath isDirectory:&isDir] || isDir ) {
            return defaultV2ray;
        }
    }
    return cusV2ray;
    
}

int runCommandLine(NSString* launchPath, NSArray* arguments) {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:launchPath];
    [task setArguments:arguments];
    NSPipe *stdoutpipe = [NSPipe pipe];
    [task setStandardOutput:stdoutpipe];
    NSPipe *stderrpipe = [NSPipe pipe];
    [task setStandardError:stderrpipe];
    NSFileHandle *file;
    file = [stdoutpipe fileHandleForReading];
    [task launch];
    NSData *data;
    data = [file readDataToEndOfFile];
    NSString *string;
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }
    file = [stderrpipe fileHandleForReading];
    data = [file readDataToEndOfFile];
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }
    [task waitUntilExit];
    return task.terminationStatus;
}

-(void)updateSystemProxy {
    NSArray *arguments;
    if (proxyState) {
        if (proxyMode == 1) { // pac mode
            // close system proxy first to refresh pac file
            if (![webServer isRunning]) {
                [webServer startWithPort:webServerPort bonjourName:nil];
            }
            dispatch_async(taskQueue, ^{
                runCommandLine(kV2RayXHelper, @[@"off"]);
            });
            arguments = @[@"auto"];
        } else {
            if (proxyMode == 3) { // manual mode
                arguments = @[@"-v"]; // do nothing
            } else { // global mode and rule mode
                if(useMultipleServer || !useCusProfile) {
                    arguments = @[@"global", [NSString stringWithFormat:@"%ld", localPort], [NSString stringWithFormat:@"%ld", httpPort]];
                } else {
                    NSInteger cusHttpPort = 0;
                    NSInteger cusSocksPort = 0;
                    NSDictionary* cusJson = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:cusProfiles[selectedCusServerIndex]] options:0 error:nil];
                    if (cusJson[@"inboundDetour"] != nil && [cusJson[@"inboundDetour"] isKindOfClass:[NSArray class]]) {
                        for (NSDictionary *inboundDetour in cusJson[@"inboundDetour"]) {
                            if ([inboundDetour[@"protocol"] isEqualToString:@"http"]) {
                                cusHttpPort = [inboundDetour[@"port"] integerValue];
                            }
                            if ([inboundDetour[@"protocol"] isEqualToString:@"socks"]) {
                                cusSocksPort = [inboundDetour[@"port"] integerValue];
                            }
                        }
                    }
                    if ([cusJson[@"inbound"][@"protocol"] isEqualToString:@"http"]) {
                        cusHttpPort = [cusJson[@"inbound"][@"port"] integerValue];
                    }
                    if ([cusJson[@"inbound"][@"protocol"] isEqualToString:@"socks"]) {
                        cusSocksPort = [cusJson[@"inbound"][@"port"] integerValue];
                    }
                    NSLog(@"socks: %ld, http: %ld", cusSocksPort, cusHttpPort);
                    arguments = @[@"global", [NSString stringWithFormat:@"%ld", cusSocksPort], [NSString stringWithFormat:@"%ld", cusHttpPort]];
                }
            }
        }
        dispatch_async(taskQueue, ^{
            runCommandLine(kV2RayXHelper,arguments);
        });
    } else {
        ; // do nothing
    }
    NSLog(@"system proxy state:%@,%ld",proxyState?@"on":@"off", (long)proxyMode);
}

-(void)backupSystemProxy {
    SCPreferencesRef prefRef = SCPreferencesCreate(nil, CFSTR("V2RayX"), nil);
    NSDictionary* sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
    [sets writeToURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/system_proxy_backup.plist",NSHomeDirectory()]] atomically:NO];
}

-(void)restoreSystemProxy {
    dispatch_async(taskQueue, ^{
        runCommandLine(kV2RayXHelper,@[@"restore"]);
    });
}

/*
-(BOOL)currentProxySetByMe {
    SCPreferencesRef prefRef = SCPreferencesCreate(nil, CFSTR("V2RayX"), nil);
    NSDictionary* sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
    //NSLog(@"%@", sets);
    for (NSString *key in [sets allKeys]) {
        NSMutableDictionary *dict = [sets objectForKey:key];
        NSString *hardware = [dict valueForKeyPath:@"Interface.Hardware"];
        if ([hardware isEqualToString:@"AirPort"] || [hardware isEqualToString:@"Wi-Fi"] || [hardware isEqualToString:@"Ethernet"]) {
            NSDictionary* proxy = dict[(NSString*)kSCEntNetProxies];
            BOOL autoProxy = [proxy[(NSString*) kCFNetworkProxiesProxyAutoConfigURLString] isEqualToString:@"http://127.0.0.1:8070/proxy.pac"];
            BOOL autoProxyEnabled = [proxy[(NSString*) kCFNetworkProxiesProxyAutoConfigEnable] boolValue];
            BOOL socksProxy = [proxy[(NSString*) kCFNetworkProxiesSOCKSProxy] isEqualToString:@"127.0.0.1"];
            BOOL socksPort = [proxy[(NSString*) kCFNetworkProxiesSOCKSPort] integerValue] == localPort;
            BOOL socksProxyEnabled = [proxy[(NSString*) kCFNetworkProxiesSOCKSEnable] boolValue];
            if ((autoProxyEnabled && autoProxy) || (socksProxyEnabled && socksPort && socksProxy) ) {
                continue;
            } else {
                NSLog(@"Device %@ is not set by me", key);
                return NO;
            }
        }
    }
    return YES;
}*/

- (IBAction)authorizeV2sys:(id)sender {
    [self installHelper:true];
}

- (BOOL)installHelper:(BOOL)force {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!force && [fileManager fileExistsAtPath:kV2RayXHelper] && [self isSysconfVersionOK]) {
        // helper already installed
        return YES;
    }
    NSAlert *installAlert = [[NSAlert alloc] init];
    [installAlert addButtonWithTitle:@"Install"];
    [installAlert addButtonWithTitle:@"Quit"];
    [installAlert setMessageText:@"V2RayX needs to install a small tool to /Library/Application Support/V2RayX/ with administrator privileges to set system proxy quickly.\nOtherwise you need to type in the administrator password every time you change system proxy through V2RayX."];
    if ([installAlert runModal] == NSAlertFirstButtonReturn) {
        NSLog(@"start install");
        NSString *helperPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"install_helper.sh"];
        NSLog(@"run install script: %@", helperPath);
        NSDictionary *error;
        NSString *script = [NSString stringWithFormat:@"do shell script \"bash %@\" with administrator privileges", helperPath];
        NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
        if ([appleScript executeAndReturnError:&error]) {
            NSLog(@"installation success");
            return YES;
        } else {
            NSLog(@"installation failure");
            //unknown failure
            return NO;
        }
    } else {
        // stopped by user
        return NO;
    }
}

- (BOOL)isSysconfVersionOK {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kV2RayXHelper];
    
    NSArray *args;
    args = [NSArray arrayWithObjects:@"-v", nil];
    [task setArguments: args];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *fd;
    fd = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [fd readDataToEndOfFile];
    
    NSString *str;
    str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (![str isEqualToString:VERSION]) {
        return NO;
    }
    return YES;
}

-(void)configurationDidChange {
    dispatch_async(taskQueue, ^{
        [self saveConfig];
    });
    [self unloadV2ray];
    if (proxyState) {
        if ((selectedServerIndex >= 0 && selectedServerIndex < [profiles count]) || (selectedCusServerIndex >= 0 && selectedCusServerIndex < [cusProfiles count] )) {
            if([cusProfiles count] == 0) {
                useCusProfile = false;
            }
            if([profiles count] == 0) {
                useCusProfile = true;
            }
            [self loadV2ray];
        } else {
            proxyState = NO;
            if (proxyMode != manual) {
                [self restoreSystemProxy];
            }
            //[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"proxyState"];
            NSAlert *noServerAlert = [[NSAlert alloc] init];
            [noServerAlert setMessageText:@"No available Server Profiles!"];
            [noServerAlert runModal];
            NSLog(@"V2Ray core loaded failed: no avalibale servers.");
        }
    }
    if (_selectedRoutingSet >= _routingRuleSets.count || _selectedRoutingSet < 0) {
        _selectedRoutingSet = 0;
    }
    [self updateSystemProxy];
    [self updateMenus];
    [self updateServerMenuList];
    [self updatePacMenuList];
    [self updateRuleSetMenuList];
}

- (IBAction)copyExportCmd:(id)sender {
    if (!useCusProfile) {
        [[NSPasteboard generalPasteboard] clearContents];
        NSString* command = [NSString stringWithFormat:@"export http_proxy=\"http://127.0.0.1:%ld\"; export HTTP_PROXY=\"http://127.0.0.1:%ld\"; export https_proxy=\"http://127.0.0.1:%ld\"; export HTTPS_PROXY=\"http://127.0.0.1:%ld\"", httpPort, httpPort, httpPort, httpPort];
        [[NSPasteboard generalPasteboard] setString:command forType:NSStringPboardType];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"Check %@.", cusProfiles[selectedCusServerIndex]]];
        [alert runModal];
    }
}

- (IBAction)viewConfigJson:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%d/config.json", webServerPort]]];
}

@synthesize logDirPath;

@synthesize proxyState;
@synthesize proxyMode;
@synthesize localPort;
@synthesize httpPort;
@synthesize udpSupport;
@synthesize shareOverLan;
@synthesize selectedServerIndex;
@synthesize selectedPacIndex;
@synthesize selectedPacPath;
@synthesize dnsString;
@synthesize profiles;
@synthesize logLevel;
@synthesize cusProfiles;
@synthesize useCusProfile;
@synthesize selectedCusServerIndex;
@synthesize useMultipleServer;
@end
