//
//  ConfigWindowController.h
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ServerProfile.h"

@protocol ConfigWindowControllerDelegate <NSObject>

@optional
- (void)configurationDidChange;
- (NSDictionary*)readDefaultsAsDictionary;

@end

@interface ConfigWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
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

@property (weak) IBOutlet NSWindow* transportWindow;
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
@property (weak) IBOutlet NSButton *tcpCrButton;
@property (weak) IBOutlet NSPopUpButton *tcpHeaderTypeButton;
//ws fields
@property (weak) IBOutlet NSButton *wsCrButton;
@property (weak) IBOutlet NSTextField *wsPathField;
//tls fields
@property (weak) IBOutlet NSButton *tlsUseButton;
@property (weak) IBOutlet NSButton *tlsAiButton;
//mux fields
@property (weak) IBOutlet NSButton *muxEnableButton;
@property (weak) IBOutlet NSTextField *muxConcurrencyField;


@property (nonatomic) ServerProfile* selectedProfile;
@property NSInteger selectedServerIndex;
@property NSInteger localPort;
@property NSInteger httpPort;
@property BOOL udpSupport;
@property BOOL shareOverLan;
@property (nonatomic, weak) NSString* dnsString;
@property (nonatomic, weak) id<ConfigWindowControllerDelegate> delegate;
@end
