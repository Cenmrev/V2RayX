//
//  AdvancedWindowController.h
//  V2RayX
//
//

#import <Cocoa/Cocoa.h>
#import "ConfigWindowController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdvancedWindowController : NSWindowController

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName ParentController:(ConfigWindowController*)parent;

@property (strong) IBOutlet NSTextField *dipInfoField;

// v2ray core
@property (weak) IBOutlet NSTextField *corePathField;
@property (weak) IBOutlet NSTextField *coreFileListField;

@end

NS_ASSUME_NONNULL_END
