//
//  AdvancedWindowController.m
//  V2RayX
//
//

#import "AdvancedWindowController.h"
#import "MutableDeepCopying.h"

@interface AdvancedWindowController () {
    ConfigWindowController* configWindowController;
    //outbound
   
}

@property (strong) NSPopover* popover;
@property NSInteger selectedOutbound;

@end

@implementation AdvancedWindowController

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName parentController:(ConfigWindowController*)parent {
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
//    selectedOutbound = 0;
    [self addObserver:self forKeyPath:@"selectedOutbound" options:NSKeyValueObservingOptionNew context:nil];
//    [self addObserver:self forKeyPath:@"outbounds.count" options:NSKeyValueObservingOptionNew context:nil];
    [self fillData];
}

- (void)fillData {
    // outbound
    self.outbounds = [configWindowController.outbounds mutableCopy];
    _outboundJsonView.editable = self.outbounds.count > 0;
    if (self.outbounds.count > 0) {
        self.selectedOutbound = 0;
    } else {
        self.selectedOutbound = -1;
    }
    [_outboundTable reloadData];
}

- (IBAction)ok:(id)sender {
//    NSLog(@"%@", [_httpPathField stringValue]);
//    if ([self checkInputs]) {
    if (![self checkOutbound]) {
        return;
    }
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
//    }
}

- (IBAction)help:(id)sender {
    // https://www.v2ray.com/chapter_02/01_overview.html#outboundobject
}

// table data
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == _outboundTable) {
        return [self.outbounds count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _outboundTable) {
        return self.outbounds[row][@"tag"];
    }
    return @"daf";
}

// table delegate
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (notification.object == _outboundTable) {
        if (_outboundTable.selectedRow != _selectedOutbound) {
            [self checkOutbound];
        } else {
            NSLog(@"do nothing");
        }
    }
}

- (BOOL)checkOutbound {
    NSError *e;
    NSDictionary* newOutboud = [NSJSONSerialization JSONObjectWithData:[_outboundJsonView.string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&e];
    if (e) {
        [self showAlert:@"not a valid json"];
        [_outboundTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedOutbound] byExtendingSelection:NO];
        return NO;
    } else {
        self.outbounds[_selectedOutbound] = newOutboud;
        self.selectedOutbound = _outboundTable.selectedRow;
        [_outboundTable reloadData];
        return YES;
    }
}

- (BOOL)checkOutboudAndSave:(NSDictionary**)dict {
    NSError *e;
    *dict = [NSJSONSerialization JSONObjectWithData:[_outboundJsonView.string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&e];
    return e == nil;
}

- (void)textDidEndEditing:(NSNotification *)notification {
    NSLog(@"finished text");
}

- (IBAction)addRemoveOutbound:(id)sender {
    if ([sender selectedSegment] == 0) {
        NSString* tagName = [NSString stringWithFormat:@"tag%lu", self.outbounds.count];
        [self.outbounds addObject:@{
                                    @"sendThrough": @"0.0.0.0",
                                    @"protocol": @"protocol name",
                                    @"settings": @{},
                                    @"tag": tagName,
                                    @"streamSettings": @{},
                                    @"mux": @{}
                                    }];
        if (_selectedOutbound == -1) {
            _selectedOutbound = 0;
            self.selectedOutbound = 0;
//            [_outboundTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedOutbound] byExtendingSelection:NO];
//            _outboundJsonView.string = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:_outbounds[_selectedOutbound] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        }
    } else {
        if (_selectedOutbound >= 0 && _selectedOutbound < _outbounds.count) {
            [_outbounds removeObjectAtIndex:_selectedOutbound];
            self.selectedOutbound = MIN((NSInteger)_outbounds.count - 1, _selectedOutbound);
//            if (_selectedOutbound >= 0) {
//                [_outboundTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedOutbound] byExtendingSelection:NO];
//                _outboundJsonView.string = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:_outbounds[_selectedOutbound] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
//            } else {
//                _outboundJsonView.string = @"";
//            }
        }
    }
    [_outboundTable reloadData];
    _outboundJsonView.editable = _outbounds.count > 0;
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

- (void)showAlert:(NSString*)text {
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setInformativeText:text];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([@"selectedOutbound" isEqualToString:keyPath]) {
        if (_selectedOutbound > -1) {
            [_outboundTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedOutbound] byExtendingSelection:NO];
            _outboundJsonView.string = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:_outbounds[_selectedOutbound] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        } else {
            _outboundJsonView.string = @"";
        }
    }
//    if ([@"outbounds.count" isEqualToString:keyPath]) {
//        _outboundJsonView.editable = _outbounds.count > 0;
//    }
}

@end
