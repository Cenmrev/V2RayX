//
//  AppDelegate.h
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "sysconf_version.h"
#import "utilities.h"
#define kV2RayXHelper @"/Library/Application Support/V2RayX/v2rayx_sysconf"
#define kV2RayXSettingVersion 3

#define webServerPort 8070

typedef enum ProxyMode : NSInteger{
    rules,
    pac,
    global,
    manual
} ProxyMode;


int runCommandLine(NSString* launchPath, NSArray* arguments);

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    BOOL proxyState;
    ProxyMode proxyMode;
    NSInteger localPort;
    NSInteger httpPort;
    BOOL udpSupport;
    BOOL shareOverLan;
    BOOL useCusProfile;
    BOOL useMultipleServer;
    NSInteger selectedServerIndex;
    NSInteger selectedCusServerIndex;
    NSInteger selectedPacIndex;
    NSString* selectedPacPath;
    NSString* dnsString;
    NSMutableArray *profiles;
    NSMutableArray *cusProfiles;
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
@property BOOL useCusProfile;
@property NSInteger selectedServerIndex;
@property NSInteger selectedCusServerIndex;
@property NSString* dnsString;
@property NSMutableArray *profiles;
@property NSMutableArray *cusProfiles;
@property NSString* logLevel;
@property BOOL useMultipleServer;
@property NSInteger selectedPacIndex;
@property NSString* selectedPacPath;


- (IBAction)showHelp:(id)sender;
- (IBAction)enableProxy:(id)sender;
- (IBAction)choosePacMode:(id)sender;
- (IBAction)chooseV2rayRules:(id)sender;
- (IBAction)chooseGlobalMode:(id)sender;
- (IBAction)chooseManualMode:(id)sender;
- (IBAction)showConfigWindow:(id)sender;
- (IBAction)editPac:(id)sender;
- (IBAction)resetPac:(id)sender;
- (IBAction)viewLog:(id)sender;

-(NSString*)getV2rayPath;
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
@property (weak, nonatomic) IBOutlet NSMenuItem *pacsItem;
@property (weak, nonatomic) IBOutlet NSMenu *serverListMenu;
@property (weak, nonatomic) IBOutlet NSMenu *pacListMenu;
@property (weak) IBOutlet NSMenuItem *editPacMenu;


@end

