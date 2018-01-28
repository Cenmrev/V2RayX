//
//  AppDelegate.h
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kV2RayXHelper @"/Library/Application Support/V2RayX/v2rayx_sysconf"
#define kSysconfVersion @"v2rayx_sysconf 1.1.0"
#define kV2RayXSettingVersion 3
#define nilCoalescing(a,b) ( (a != nil) ? (a) : (b) ) // equivalent to ?? operator in Swift

typedef enum ProxyMode : NSInteger{
    rules,
    pac,
    global,
    manual
} ProxyMode;


@interface AppDelegate : NSObject <NSApplicationDelegate> {
    BOOL proxyState;
    ProxyMode proxyMode;
    NSInteger localPort;
    NSInteger httpPort;
    BOOL udpSupport;
    BOOL shareOverLan;
    NSInteger selectedServerIndex;
    NSString* dnsString;
    NSMutableArray *profiles;
    NSString* logLevel;
    
    
    NSString* plistPath;
    NSString* pacPath;
    NSString* logDirPath;
}

@property NSString* logDirPath;

@property BOOL proxyState;
@property ProxyMode proxyMode;
@property NSInteger localPort;
@property NSInteger httpPort;
@property BOOL udpSupport;
@property BOOL shareOverLan;
@property NSInteger selectedServerIndex;
@property NSString* dnsString;
@property NSMutableArray *profiles;
@property NSString* logLevel;


- (IBAction)showHelp:(id)sender;
- (IBAction)enableProxy:(id)sender;
- (IBAction)choosePacMode:(id)sender;
- (IBAction)chooseV2rayRules:(id)sender;
- (IBAction)chooseGlobalMode:(id)sender;
- (IBAction)chooseManualMode:(id)sender;
- (IBAction)showConfigWindow:(id)sender;
- (IBAction)editPac:(id)sender;
- (IBAction)viewLog:(id)sender;

- (void)configurationDidChange;
- (NSString*)logDirPath;

@property (strong, nonatomic)  NSStatusItem *statusBarItem;
@property (strong, nonatomic) IBOutlet NSMenu *statusBarMenu;
@property (weak, nonatomic) IBOutlet NSMenuItem *v2rayStatusItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *enabelV2rayItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *pacModeItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *v2rayRulesItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *globalModeItem;
@property (weak) IBOutlet NSMenuItem *manualModeItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *serversItem;
@property (weak, nonatomic) IBOutlet NSMenu *serverListMenu;

@end

