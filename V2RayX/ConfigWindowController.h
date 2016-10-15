//
//  ConfigWindowController.h
//  V2RayX
//
//  Copyright © 2016年 Project V2Ray. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ServerProfile.h"

@protocol ConfigWindowControllerDelegate <NSObject>

@optional
- (void)configurationDidChange;
- (NSArray*)readDefaultsAsArray;
- (NSDictionary*)readDefaultsAsDictionary;

@end

@interface ConfigWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
- (IBAction)addRemoveServer:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)okSave:(id)sender;
@property (weak) IBOutlet NSTableView *profileTable;
@property (weak) IBOutlet NSSegmentedControl *addRemoveButton;
@property (weak) IBOutlet NSTextField *localPortField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *alterIdField;
@property (weak) IBOutlet NSTabView *globalTransportTab;
@property (weak) IBOutlet NSButton *globalTransportButton;

@property (nonatomic, strong) ServerProfile* selectedProfile;
@property NSInteger selectedServerIndex;
@property NSInteger localPort;
@property BOOL udpSupport;
@property (nonatomic, weak) id<ConfigWindowControllerDelegate> delegate;
@end
