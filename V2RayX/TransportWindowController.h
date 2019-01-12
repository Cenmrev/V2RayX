//
//  TransportWindowController.h
//  V2RayX
//
//

#import <Cocoa/Cocoa.h>
#import "ConfigWindowController.h"
#import "utilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface TransportWindowController : NSWindowController

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName parentController:(ConfigWindowController*)parent;

- (BOOL)checkInputs;
- (NSArray*)generateSettings;

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
@property (unsafe_unretained) IBOutlet NSTextView *tcpHeaderField;


//ws fields
@property (weak) IBOutlet NSTextField *wsPathField;
@property (unsafe_unretained) IBOutlet NSTextView *wsHeaderField;
//https fields
@property (weak) IBOutlet NSTextField *httpHostsField;
@property (weak) IBOutlet NSTextField *httpPathField;

// quic fields
@property (weak) IBOutlet NSPopUpButton *quicSecurityButton;
@property (weak) IBOutlet NSTextField *quicKeyField;
@property (weak) IBOutlet NSPopUpButton *quicHeaderButton;


//tls fields
@property (weak) IBOutlet NSButton *tlsUseButton;
@property (weak) IBOutlet NSButton *tlsAiButton;
@property (weak) IBOutlet NSButton *tlsAllowInsecureCiphersButton;
@property (weak) IBOutlet NSTextField *tlsAlpnField;
@property (weak) IBOutlet NSTextField *tlsServerNameField;

//mux fields
@property (weak) IBOutlet NSButton *muxEnableButton;
@property (weak) IBOutlet NSTextField *muxConcurrencyField;

//tcp fast open
@property (weak) IBOutlet NSButton *tfoEnableButton;

@end

NS_ASSUME_NONNULL_END
