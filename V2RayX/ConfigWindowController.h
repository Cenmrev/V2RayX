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
- (IBAction)addRemoveServer:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)okSave:(id)sender;
@property (weak) IBOutlet NSTableView *profileTable;
@property (weak) IBOutlet NSSegmentedControl *addRemoveButton;

@property (weak) IBOutlet NSTextField *localPortField;
@property (weak) IBOutlet NSTextField *httpPortField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *alterIdField;
@property (weak) IBOutlet NSTextField *dnsField;
@property (weak) IBOutlet NSButton *globalTransportButton;
@property (weak) IBOutlet NSWindow* routingConfigWindow;
@property (weak) IBOutlet NSPopUpButton *logLevelButton;
@property (weak) IBOutlet NSMenu *importFromJsonMenu;
@property (weak) IBOutlet NSButton *globalRoutingButton;
@property (weak) IBOutlet NSWindow* transportWindow;
@property (weak) IBOutlet NSWindow* cusConfigWindow;

//kcp fields
@property (weak) IBOutlet NSTextField *kcpMtuField;
@property (weak) IBOutlet NSTextField *kcpTtiField;
@property (weak) IBOutlet NSTextField *kcpUcField;
@property (weak) IBOutlet NSTextField *kcpDcField;
@property (weak) IBOutlet NSTextField *kcpRbField;
@property (weak) IBOutlet NSTextField *kcpWbField;
@property (weak) IBOutlet NSPopUpButton *kcpCongestionButton;
@property (weak) IBOutlet NSPopUpButton *kcpHeaderTypeButton;

//tcp fields
@property (weak) IBOutlet NSButton *tcpHeaderCusButton;
@property (unsafe_unretained) IBOutlet NSTextView *tcpHdField;

//ws fields
@property (weak) IBOutlet NSTextField *wsPathField;
@property (unsafe_unretained) IBOutlet NSTextView *wsHeaderField;

//https fields
@property (weak) IBOutlet NSTextField *httpHostsField;
@property (weak) IBOutlet NSTextField *httpPathField;

//tls fields
@property (weak) IBOutlet NSButton *tlsUseButton;
@property (weak) IBOutlet NSButton *tlsAiButton;
@property (weak) IBOutlet NSTextField *tlsSnField;

//mux fields
@property (weak) IBOutlet NSButton *muxEnableButton;
@property (weak) IBOutlet NSTextField *muxConcurrencyField;

//proxy fields
@property (weak) IBOutlet NSTextField *proxyAddressField;
@property (weak) IBOutlet NSTextField *proxyPortField;

//cus config file fields
@property (weak) IBOutlet NSTableView *cusProfileTable;
@property (weak) IBOutlet NSTextField *checkLabel;

//routing config field
@property (weak) IBOutlet NSTextField *routingProxyField;
@property (weak) IBOutlet NSTextField *routingDirectField;
@property (weak) IBOutlet NSTextField *routingBlockField;
@property NSString* routingProxyListPath;
@property NSString* routingDirectListPath;
@property NSString* routingBlockListPath;


@property AppDelegate* appDelegate;
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
@property (nonatomic) NSMutableArray *cusProfiles;


@end
