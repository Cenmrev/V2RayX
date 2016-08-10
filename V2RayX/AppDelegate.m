//
//  AppDelegate.m
//  V2RayX
//
//  Copyright © 2016年 Project V2Ray. All rights reserved.
//

#import "AppDelegate.h"
#import "ConfigWindowController.h"

#define kV2RayXHelper @"/Library/Application Support/V2RayX/v2rayx_sysconf"
#define kSysconfVersion @"v2rayx_sysconf 1.0.0"

@interface AppDelegate () {
    ConfigWindowController *configWindowController;
    BOOL proxyIsOn;
    NSInteger localPort;
    BOOL udpSupport;
    NSInteger selectedServerIndex;
    NSMutableArray *profiles;
    FSEventStreamRef fsEventStream;
    NSString* plistPath;
}

@end

@implementation AppDelegate

static AppDelegate *appDelegate;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if (![self installHelper]) {
        [[NSApplication sharedApplication] terminate:nil];// installed failed or stopped by user,
    };
    
    _statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusBarItem setMenu:_statusBarMenu];
    [_statusBarItem setHighlightMode:YES];
    
    plistPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/v2rayproject.v2rayx.v2ray-core.plist",NSHomeDirectory()];

    profiles = [[NSMutableArray alloc] init];
    
    [self configurationDidChange];
    appDelegate = self;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    runCommandLine(@"/bin/launchctl", @[@"unload", plistPath]);
    NSLog(@"V2RayX quiting, V2Ray core unloaded.");
    if (proxyIsOn) {
        proxyIsOn = NO;
        [self updateSystemProxy];//close system proxy
        proxyIsOn = YES; //save last state
    }
}

- (IBAction)showHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com"]];
}

- (IBAction)enableProxy:(id)sender {
    if ([profiles count] > 0) { // check if there is available profiles
        proxyIsOn = !proxyIsOn;
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:proxyIsOn] forKey:@"proxyIsOn"];
        [self updateMenus];
        [self updateSystemProxy];
    }
}

- (IBAction)showConfigWindow:(id)sender {
    if (configWindowController) {
        [configWindowController close];
    }
    configWindowController =[[ConfigWindowController alloc] initWithWindowNibName:@"ConfigWindow"];
    configWindowController.delegate = self;
    [configWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [configWindowController.window makeKeyAndOrderFront:nil];
}

- (void)updateMenus {
    if (proxyIsOn) {
        [_v2rayStatusItem setTitle:@"V2Ray: On"];
        [_enabelV2rayItem setTitle:@"Stop V2Ray"];
        NSImage *icon = [NSImage imageNamed:@"statusBarIcon"];
        [icon setTemplate:YES];
        [_statusBarItem setImage:icon];
    } else {
        [_v2rayStatusItem setTitle:@"V2Ray: Off"];
        [_enabelV2rayItem setTitle:@"Start V2Ray"];
        [_statusBarItem setImage:[NSImage imageNamed:@"statusBarIcon_disabled"]];
        NSLog(@"icon updated");
    }
}

- (void)updateServerMenuList {
    [_serverListMenu removeAllItems];
    if ([profiles count] == 0) {
        [_serverListMenu addItem:[[NSMenuItem alloc] initWithTitle:@"no available servers, please add server profiles through config window." action:nil keyEquivalent:@""]];
        //NSLog(@"here");
    } else {
        int i = 0;
        for (ServerProfile *p in profiles) {
            NSString *itemTitle;
            //NSLog(@"%@",p);
            if (![[p remark]isEqualToString:@""]) {
                itemTitle = [p remark];
            } else {
                itemTitle = [NSString stringWithFormat:@"%@:%ld",[p address], [p port]];
            }
            //NSLog(@"itemTitle = %@", itemTitle);
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:itemTitle action:@selector(switchServer:) keyEquivalent:@""];
            [newItem setTag:i];
            newItem.state = i == selectedServerIndex?1:0;
            [_serverListMenu addItem:newItem];
            i++;
        }
    }
    [_serversItem setSubmenu:_serverListMenu];
}

- (void)switchServer:(id)sender {
    selectedServerIndex = [sender tag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:selectedServerIndex] forKey:@"selectedServerIndex"];
    [self reloadV2ray];
    [self updateServerMenuList];
}

- (NSArray*)readDefaultsAsArray {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *dProxyState = [defaults objectForKey:@"proxyIsOn"];
    if (dProxyState == nil) {
        dProxyState = [NSNumber numberWithBool:YES];//turn on proxy as default
    }
    NSNumber* dLocalPort = [defaults objectForKey:@"localPort"];
    if (dLocalPort == nil) {
        dLocalPort = [NSNumber numberWithInteger:1081];//use 1081 as default local port
    }
    NSNumber* dUdpSupport = [defaults objectForKey:@"udpSupport"];
    if (dUdpSupport == nil) {
        dUdpSupport = [NSNumber numberWithBool:NO];// do not support udp as default
    }
    NSMutableArray *dProfilesInPlist = [defaults objectForKey:@"profiles"];
    NSMutableArray *dProfiles = [[NSMutableArray alloc] init];
    NSNumber *dServerIndex;
    if ([dProfilesInPlist isKindOfClass:[NSArray class]] && [dProfilesInPlist count] > 0) {
        for (NSArray *aProfileArray in dProfilesInPlist) {
            ServerProfile *newProfile = [[ServerProfile alloc] init];
            [newProfile setAddress:aProfileArray[0]];
            [newProfile setPort:[aProfileArray[1] integerValue]];
            [newProfile setUserId:aProfileArray[2]];
            [newProfile setAlterId:[aProfileArray[3] integerValue]];
            [newProfile setRemark:aProfileArray[4]];
            [newProfile setUseKCP:[aProfileArray[5] integerValue]];
            [dProfiles addObject:newProfile];
        }
        dServerIndex = [defaults objectForKey:@"selectedServerIndex"];
        if ([dServerIndex integerValue] <= 0 || [dServerIndex integerValue] >= [dProfiles count]) {
            // "<= 0" also includes the case where dServerIndex is nil 
            dServerIndex = [NSNumber numberWithInteger:0]; // treate illeagle selectedServerIndex value
        }
    } else {
        dServerIndex = [NSNumber numberWithInteger:-1];
    }
    return @[dProxyState,dLocalPort,dUdpSupport,dProfiles,dServerIndex];
}

- (void)readDefaults {
    NSDictionary *defaultsDic = [self readDefaultsAsDictionary];
    proxyIsOn = [defaultsDic[@"proxyState"] boolValue];
    localPort = [defaultsDic[@"localPort"] integerValue];
    udpSupport = [defaultsDic[@"udpSupport"] integerValue];
    [profiles removeAllObjects];
    profiles = defaultsDic[@"profiles"];
    selectedServerIndex = [defaultsDic[@"serverIndex"] integerValue];
    NSLog(@"read %ld profiles, selected No.%ld", [profiles count] , selectedServerIndex);
}

- (NSDictionary*)readDefaultsAsDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *dProxyState = [defaults objectForKey:@"proxyIsOn"];
    if (dProxyState == nil) {
        dProxyState = [NSNumber numberWithBool:YES];//turn on proxy as default
    }
    NSNumber* dLocalPort = [defaults objectForKey:@"localPort"];
    if (dLocalPort == nil) {
        dLocalPort = [NSNumber numberWithInteger:1081];//use 1081 as default local port
    }
    NSNumber* dUdpSupport = [defaults objectForKey:@"udpSupport"];
    if (dUdpSupport == nil) {
        dUdpSupport = [NSNumber numberWithBool:NO];// do not support udp as default
    }
    NSMutableArray *dProfilesInPlist = [defaults objectForKey:@"profiles"];
    NSMutableArray *dProfiles = [[NSMutableArray alloc] init];
    NSNumber *dServerIndex;
    if ([dProfilesInPlist isKindOfClass:[NSArray class]] && [dProfilesInPlist count] > 0) {
        for (NSDictionary *aProfile in dProfilesInPlist) {
            
            ServerProfile *newProfile = [[ServerProfile alloc] init];
            [newProfile setAddress:aProfile[@"address"]];
            [newProfile setPort:[aProfile[@"port"] integerValue]];
            [newProfile setUserId:aProfile[@"userId"]];
            [newProfile setAlterId:[aProfile[@"alterId"] integerValue]];
            [newProfile setRemark:aProfile[@"remark"]];
            [newProfile setUseKCP:[aProfile[@"useKCP"] integerValue]];
            [dProfiles addObject:newProfile];
        }
        dServerIndex = [defaults objectForKey:@"selectedServerIndex"];
        if ([dServerIndex integerValue] <= 0 || [dServerIndex integerValue] >= [dProfiles count]) {
            // "<= 0" also includes the case where dServerIndex is nil
            dServerIndex = [NSNumber numberWithInteger:0]; // treate illeagle selectedServerIndex value
        }
    } else {
        dServerIndex = [NSNumber numberWithInteger:-1];
    }
    return @{@"proxyState": dProxyState,
             @"localPort": dLocalPort,
             @"udpSupport": dUdpSupport,
             @"profiles": dProfiles,
             @"serverIndex": dServerIndex };
}

-(BOOL)reloadV2ray {
    runCommandLine(@"/bin/launchctl", @[@"unload", plistPath]);
    NSLog(@"V2Ray core unloaded.");
    if (selectedServerIndex >= 0 && selectedServerIndex < [profiles count]) {
        NSString *configPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/config.json",NSHomeDirectory()];
        NSDictionary *configDic = [[profiles objectAtIndex:selectedServerIndex] v2rayConfigWithLocalPort:localPort udpSupport:udpSupport];
        NSData* v2rayJSONconfig = [NSJSONSerialization dataWithJSONObject:configDic options:NSJSONWritingPrettyPrinted    error:nil];
        [v2rayJSONconfig writeToFile:configPath atomically:NO];
        [self generateLaunchdPlist:plistPath];
        runCommandLine(@"/bin/launchctl",  @[@"load", plistPath]);
        NSLog(@"V2Ray core loaded at port: %ld.", localPort);
        return YES;
    } else {
        NSAlert *noServerAlert = [[NSAlert alloc] init];
        [noServerAlert setMessageText:@"No available Server Profiles!"];
        [noServerAlert runModal];
        NSLog(@"V2Ray core loaded failed: no avalibale servers.");
        return NO;
    }
}

-(void)generateLaunchdPlist:(NSString*)path {
    NSString* v2rayPath = [NSString stringWithFormat:@"%@/v2ray", [[NSBundle mainBundle] resourcePath]];
    NSString *configPath = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/config.json",NSHomeDirectory()];
    NSDictionary *runPlistDic = [[NSDictionary alloc] initWithObjects:@[@"v2rayproject.v2rayx.v2ray-core", @[v2rayPath, @"-config", configPath], [NSNumber numberWithBool:YES]] forKeys:@[@"Label", @"ProgramArguments", @"RunAtLoad"]];
    [runPlistDic writeToFile:path atomically:NO];
}

void runCommandLine(NSString* launchPath, NSArray* arguments) {
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
}

-(void)updateSystemProxy {
    NSArray *arguments;
    if (proxyIsOn) {
        arguments = @[@"global", [NSString stringWithFormat:@"%ld", localPort]];
    } else {
        arguments = [NSArray arrayWithObjects:@"off", nil];
    }
    runCommandLine(kV2RayXHelper,arguments);
    NSLog(@"system proxy state:%@,%@",proxyIsOn?@"on":@"off", @"global");
}

- (BOOL)installHelper {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kV2RayXHelper] || ![self isSysconfVersionOK]) {
        NSAlert *installAlert = [[NSAlert alloc] init];
        [installAlert addButtonWithTitle:@"Install"];
        [installAlert addButtonWithTitle:@"Quit"];
        [installAlert setMessageText:@"V2RayX needs to install a small tool to /Library/Application Support/V2RayX/ with administrator privileges to set system proxy quickly."];
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
    } else {
        // helper already installed
        return YES;
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
    
    if (![str isEqualToString:kSysconfVersion]) {
        return NO;
    }
    return YES;
}

-(void)configurationDidChange {
    [self readDefaults];
    NSLog(@"profiles = %ld, just after read.",[profiles count]);
    if (![self reloadV2ray]) {
        proxyIsOn = NO;
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"proxyIsOn"];
    }
    [self updateSystemProxy];
    [self updateMenus];
    [self updateServerMenuList];
}

@end
