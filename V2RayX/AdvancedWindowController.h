//
//  AdvancedWindowController.h
//  V2RayX
//
//

#import <Cocoa/Cocoa.h>
#import "ConfigWindowController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdvancedWindowController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource, NSTextViewDelegate>

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName parentController:(ConfigWindowController*)parent;
@property (weak) IBOutlet NSTextField *checkLabel;

//outbounds
@property (weak) IBOutlet NSTableView *outboundTable;
@property (unsafe_unretained) IBOutlet NSTextView *outboundJsonView;
@property (weak) IBOutlet NSSegmentedControl *outboundAddControl;
@property NSMutableArray* outbounds;


//rules
@property (strong) IBOutlet NSTextField *dipInfoField;

//config
@property (weak) IBOutlet NSTableView *configTable;
@property (weak) IBOutlet NSSegmentedControl *configAddControl;
@property NSMutableArray* configs;

// v2ray core
@property (weak) IBOutlet NSTextField *corePathField;
@property (weak) IBOutlet NSTextField *coreFileListField;

@end

NS_ASSUME_NONNULL_END
