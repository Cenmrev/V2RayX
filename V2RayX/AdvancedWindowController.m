//
//  AdvancedWindowController.m
//  V2RayX
//
//

#import "AdvancedWindowController.h"

@interface AdvancedWindowController () {
    ConfigWindowController* configWindowController;
   
}

@property (strong) NSPopover* popover;

@end

@implementation AdvancedWindowController

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName ParentController:(ConfigWindowController*)parent {
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        configWindowController = parent;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = [[NSViewController alloc] init];
    self.popover.contentViewController.view = self.dipInfoField;
    self.popover.behavior = NSPopoverBehaviorTransient;
    
    self.corePathField.stringValue = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/v2ray-core/",NSHomeDirectory()];
}
- (IBAction)ok:(id)sender {
//    NSLog(@"%@", [_httpPathField stringValue]);
//    if ([self checkInputs]) {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
//    }
}

- (IBAction)help:(id)sender {
    // https://www.v2ray.com/chapter_02/01_overview.html#outboundobject
}


// core
- (IBAction)showCorePath:(id)sender {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.corePathField.stringValue]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.corePathField.stringValue withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:self.corePathField.stringValue]]];
}

- (IBAction)showInformation:(id)sender {
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}

//- (IBAction)cFinish:(NSButton *)sender {
//    [_checkLabel setHidden:NO];
//    NSString* v2rayBinPath = [NSString stringWithFormat:@"%@/v2ray", [[NSBundle mainBundle] resourcePath]];
//    for (NSString* filePath in _cusProfiles) {
//        int returnCode = runCommandLine(v2rayBinPath, @[@"-test", @"-config", filePath]);
//        if (returnCode != 0) {
//            [_checkLabel setHidden:YES];
//            NSAlert *alert = [[NSAlert alloc] init];
//            [alert setMessageText:[NSString stringWithFormat:@"%@ is not a valid v2ray config file", filePath]];
//            [alert beginSheetModalForWindow:_cusConfigWindow completionHandler:^(NSModalResponse returnCode) {
//                return;
//            }];
//            return;
//        }
//    }
//    [[self window] endSheet:_cusConfigWindow];
//}

@end
