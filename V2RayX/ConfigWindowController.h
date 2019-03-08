//
//  ConfigWindowController.h
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ServerProfile.h"

@interface ConfigWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
- (IBAction)chooseNetwork:(NSPopUpButton *)sender;
@property (weak) IBOutlet NSPopUpButton *networkButton;
@property (weak) IBOutlet NSPopUpButton *vmessSecurityButton;
- (IBAction)addRemoveServer:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)okSave:(id)sender;
@property (weak) IBOutlet NSButton *importButton;
@property (weak) IBOutlet NSTableView *profileTable;
@property (weak) IBOutlet NSSegmentedControl *addRemoveButton;
@property (weak) IBOutlet NSView *importResultView;
@property (weak) IBOutlet NSTextField *importMessageField;

@property (weak) IBOutlet NSTextField *localPortField;
@property (weak) IBOutlet NSTextField *httpPortField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *alterIdField;
@property (weak) IBOutlet NSTextField *dnsField;
@property (weak) IBOutlet NSButton *globalTransportButton;
@property (weak) IBOutlet NSPopUpButton *logLevelButton;
@property (weak) IBOutlet NSMenu *importFromJsonMenu;
@property (weak) IBOutlet NSButton *transportSettingsButton;

@property (weak) AppDelegate* appDelegate;
@property (nonatomic) ServerProfile* selectedProfile;
@property (nonatomic) NSInteger logLevel;
@property (nonatomic) NSInteger selectedServerIndex;
@property (nonatomic) NSInteger selectedCusServerIndex;
@property (nonatomic) NSInteger localPort;
@property (nonatomic) NSInteger httpPort;
@property (nonatomic) BOOL udpSupport;
@property (nonatomic) BOOL shareOverLan;
@property (nonatomic) NSString* dnsString;
@property (nonatomic) NSMutableArray *profiles;
@property (nonatomic) NSMutableArray *outbounds; // except than vmess
@property (nonatomic) NSMutableArray *subscriptions;
@property NSMutableArray* routingRuleSets;
@property (nonatomic) NSMutableArray *cusProfiles;
@property BOOL enableRestore;
@property BOOL enableEncryption;
@property NSString* encryptionKey;

@property (weak) IBOutlet NSTextField *versionField;

@end
