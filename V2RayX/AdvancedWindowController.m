//
//  AdvancedWindowController.m
//  V2RayX
//
//

#import "AdvancedWindowController.h"
#import "MutableDeepCopying.h"
#include <stdio.h>

@interface AdvancedWindowController () {
    ConfigWindowController* configWindowController;
    //outbound
   
}

@property (strong) NSPopover* popover;
@property NSInteger selectedOutbound;
@property (atomic) NSInteger selectedRuleSet;
@property (atomic) NSInteger selectedRule;

@end

@implementation AdvancedWindowController

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName parentController:(ConfigWindowController*)parent {
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        configWindowController = parent;
    }
    return self;
}

- (void)removeObservers {
    [self removeObserver:self forKeyPath:@"selectedOutbound"];
    [self removeObserver:self forKeyPath:@"selectedRuleSet"];
    [self removeObserver:self forKeyPath:@"selectedRule"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // initialize UI
    [_outboundTable setFocusRingType:NSFocusRingTypeNone];
    [_ruleTable setFocusRingType:NSFocusRingTypeNone];
    [_ruleSetTable setFocusRingType:NSFocusRingTypeNone];
    [_configTable setFocusRingType:NSFocusRingTypeNone];
    [_subscriptionTable setFocusRingType:NSFocusRingTypeNone];
    [[self domainStrategyButton] removeAllItems];
    for(NSString* strategy in DOMAIN_STRATEGY_LIST) {
        [[self domainStrategyButton] addItemWithTitle:strategy];
    }
    [[self networkListButton] removeAllItems];
    for(NSString* network in ROUTING_NETWORK_LIST) {
        [[self networkListButton] addItemWithTitle:network];
    }
    [_protocolButton removeAllItems];
    for (NSString* p in SNIFFING_PROTOCOL) {
        [_protocolButton addItemWithTitle:p];
    }
    _outboundJsonView.automaticQuoteSubstitutionEnabled = false;
    _domainTextView.automaticQuoteSubstitutionEnabled = false;
    [_routeToBox removeAllItems];
    [_routeToBox addItemsWithObjectValues:RESERVED_TAGS];
    [_inboundTagBox removeAllItems];
    [_inboundTagBox addItemsWithObjectValues:@[@"socksinbound", @"httpinbound"]];
    
    // outbound
    [_outboundJsonView setFont:[NSFont fontWithName:@"Menlo" size:13]];
    [self addObserver:self
           forKeyPath:@"selectedOutbound"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    // rule
    [self addObserver:self
           forKeyPath:@"selectedRuleSet"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self addObserver:self
           forKeyPath:@"selectedRule"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:NSControlTextDidChangeNotification
                                               object:_ruleSetNameField];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:NSControlTextDidChangeNotification
                                               object:_routeToBox];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:NSControlTextDidChangeNotification
                                               object:_portField];
    
    
    // core path
    self.corePathField.stringValue = [NSString stringWithFormat:@"%@/Library/Application Support/V2RayX/v2ray-core/",NSHomeDirectory()];
    self.enableRestore = configWindowController.enableRestore;
    
    self.enableEncryption = configWindowController.enableEncryption;
    self.encryptionKey = [[NSString alloc] initWithString:configWindowController.encryptionKey];
    // encryption
    _changeIndicatorField.stringValue = @"";
    
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
    // subscriptions
    self.subscriptions = [configWindowController.subscriptions mutableCopy];
    [_subscriptionTable reloadData];
    // rules
    self.selectedRuleSet = 0;
    self.selectedRule = 0;
    self.routingRuleSets = [configWindowController.routingRuleSets mutableDeepCopy];
    // configs
    self.configs = [configWindowController.cusProfiles mutableDeepCopy];
    [_configTable reloadData];
    // core
    [_enableRestoreButton selectItemAtIndex:_enableRestore?1:0];
}

- (IBAction)ok:(id)sender {
    
    if (![self checkOutbound]) {
        return;
    }
    if (![self checkConfig]) {
        return;
    }
    [self removeObservers];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender {
    [self removeObservers];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

// table data
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == _outboundTable) {
        return [self.outbounds count];
    }
    if (tableView == _configTable) {
        return [self.configs count];
    }
    if (tableView == _ruleSetTable) {
        return self.routingRuleSets.count;
    }
    if (tableView == _ruleTable) {
        return [self.routingRuleSets[_selectedRuleSet][@"rules"] count];
    }
    if (tableView == _subscriptionTable) {
        return [self.subscriptions count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _outboundTable) {
        return self.outbounds[row][@"tag"];
    }
    if (tableView == _configTable) {
        return self.configs[row];
    }
    if (tableView == _ruleSetTable) {
        return self.routingRuleSets[row][@"name"];
    }
    if(tableView == _ruleTable) {
        NSUInteger ruleCount = [self.routingRuleSets[_selectedRuleSet][@"rules"] count];
        NSDictionary* rule = self.routingRuleSets[_selectedRuleSet][@"rules"][row];
        NSString* routeTo = rule[@"outboundTag"] ? rule[@"outboundTag"] : rule[@"balancerTag"];
        return row + 1 == ruleCount ? [NSString stringWithFormat:@"final:%@", routeTo] : [NSString stringWithFormat:@"%lu:%@", row, routeTo] ;
    }
    if (tableView == _subscriptionTable) {
        return self.subscriptions[row];
    }
    return @"";
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
    if (notification.object == _ruleSetTable) {
        self.selectedRuleSet = [_ruleSetTable selectedRow];
        [_ruleTable reloadData];
    }
    if (notification.object == _ruleTable) {
        self.selectedRule = [_ruleTable selectedRow];
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _configTable) {
        self.configs[row] = object;
    } else if (tableView == _subscriptionTable) {
        self.subscriptions[row] = object;
    }
}

// bound

- (BOOL)checkOutbound {
    if (_outbounds.count == 0) {
        return YES;
    }
    NSError *e;
    NSDictionary* newOutboud = [NSJSONSerialization JSONObjectWithData:[_outboundJsonView.string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&e];
    if (e) {
        [self showAlert:@"NOT a valid json"];
        [_outboundTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedOutbound] byExtendingSelection:NO];
        return NO;
    } else {
        self.outbounds[_selectedOutbound] = newOutboud;
        self.selectedOutbound = _outboundTable.selectedRow;
        [_outboundTable reloadData];
        return YES;
    }
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
        }
    } else {
        if (_selectedOutbound >= 0 && _selectedOutbound < _outbounds.count) {
            [_outbounds removeObjectAtIndex:_selectedOutbound];
            self.selectedOutbound = MIN((NSInteger)_outbounds.count - 1, _selectedOutbound);
        }
    }
    [_outboundTable reloadData];
    _outboundJsonView.editable = _outbounds.count > 0;
}

// rules

-(void)textFieldDidChange:(NSNotification *)notification {
    if (notification.object == _ruleSetNameField) {
        self.routingRuleSets[_selectedRuleSet][@"name"] = _ruleSetNameField.stringValue;
    }
    if (notification.object == _routeToBox) {
        NSMutableDictionary* rule =
        self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule];
        if ([@"balance" isEqualToString:_routeToBox.stringValue]) {
            rule[@"balancerTag"] = @"balance";
            [rule removeObjectForKey:@"outboundTag"];
        } else {
            rule[@"outboundTag"] = _routeToBox.stringValue;
            [rule removeObjectForKey:@"balancerTag"];
        }
    }
    if (notification.object == _portField) {
        NSMutableDictionary* rule =
        self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule];
        NSString* trimedInput = [_portField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *port = [f numberFromString:trimedInput];
        rule[@"port"] = nilCoalescing(port, trimedInput);
    }
    if (notification.object == _inboundTagBox) {
        self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule][@"inboundTag"] = _inboundTagBox.stringValue;
    }
}

- (IBAction)addRemoveRuleSet:(id)sender {
    [[self window] makeFirstResponder:_ruleSetTable];
    if ([sender selectedSegment] == 0) {
        NSMutableDictionary* newRuleSet = [ROUTING_DIRECT mutableDeepCopy];
        newRuleSet[@"name"] = @"new_rule_set";
        [_routingRuleSets addObject:newRuleSet];
        [_ruleSetTable reloadData];
        [_ruleSetTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_routingRuleSets.count - 1] byExtendingSelection:NO]; // toggle
    } else if([sender selectedSegment] == 1 && _selectedRuleSet > 0 && _selectedRuleSet < _routingRuleSets.count){
        [_routingRuleSets removeObjectAtIndex:_selectedRuleSet];
        NSUInteger originalIndex = _ruleSetTable.selectedRow;
        [_ruleSetTable selectRowIndexes:[NSIndexSet indexSetWithIndex:MIN(_selectedRuleSet, _routingRuleSets.count - 1)] byExtendingSelection:NO]; // toggle
        if (originalIndex == _ruleSetTable.selectedRow) {
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:_ruleSetTable]];
        }
        [_ruleSetTable reloadData];
    } else if ([sender selectedSegment] == 2) {
        NSAlert* alert = [[NSAlert alloc] init];
        alert.messageText = @"Do you want to reset rule sets to original three ones?";
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                NSLog(@"will rest");
                self->_routingRuleSets = [@[ROUTING_GLOBAL, ROUTING_BYPASSCN_PRIVATE_APPLE, ROUTING_DIRECT] mutableDeepCopy];
                NSUInteger originalIndex = self->_ruleSetTable.selectedRow;
                [self->_ruleSetTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO]; // toggle
                if (originalIndex == self->_ruleSetTable.selectedRow) {
                    [self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:self->_ruleSetTable]];
                }
                [self->_ruleSetTable reloadData];
            }
        }];
    } else if ([sender selectedSegment] == 3 && _selectedRuleSet >= 0 && _selectedRuleSet < _routingRuleSets.count) {
        [_routingRuleSets addObject:[[_routingRuleSets objectAtIndex:_selectedRuleSet] mutableDeepCopy]];
        [_ruleSetTable reloadData];
        [_ruleSetTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_routingRuleSets.count - 1] byExtendingSelection:NO]; // toggle
    }
}

- (IBAction)didSelectStrategy:(id)sender {
    if (_selectedRuleSet < _routingRuleSets.count) {
        _routingRuleSets[_selectedRuleSet][@"domainStrategy"] = _domainStrategyButton.selectedItem.title;
    }
}

- (IBAction)addRemoveRule:(id)sender {
    [[self window] makeFirstResponder:_ruleTable];
    NSMutableArray* rules = _routingRuleSets[_selectedRuleSet][@"rules"];
    if ([sender selectedSegment] == 0) {
        [rules insertObject:[@{
                              @"type": @"field",
                              @"outboundTag": @"direct"} mutableDeepCopy] atIndex:rules.count-1];
    } else {
        if (_selectedRule + 1 == [rules count]) {
            return;
        }
        [rules removeObjectAtIndex:_selectedRule];
    }
    [_ruleTable reloadData];
    self.selectedRule = _selectedRule; // toggle
}

- (IBAction)didClickEnable:(id)sender {

#define enableFilter(enableButton, field, key) \
    field.enabled = enableButton.state; \
    if (!enableButton.state) { \
        [self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule] removeObjectForKey:key];\
    }
    
    if (sender == _domainEnableButton) {
        enableFilter(_domainEnableButton, _editDomainButton, @"domain")
        if (_domainEnableButton.state) {
            [self showEditView:_editDomainButton];
        } else if (self.popover.shown) {
            [self.popover close];
        }
    } else if (sender == _ipEnableButton) {
        enableFilter(_ipEnableButton, _editIpButton, @"ip")
        if (_ipEnableButton.state) {
            [self showEditView:_editIpButton];
        } else if (self.popover.shown) {
            [self.popover close];
        }
    } else if (sender == _inboundEnableButton) {
        enableFilter(_inboundEnableButton, _inboundTagBox, @"inboundTag")
        if (_inboundEnableButton.state) {
            [self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule] setObject:_inboundTagBox.stringValue forKey:@"inboundTag"];
        }
    } else if (sender == _protocolEnableButton) {
        enableFilter(_protocolEnableButton, _protocolButton, @"protocol")
        if (_protocolEnableButton.state) {
            [self didSelectRuleItem:_protocolButton];
        }
    } else if (sender == _networkEnableButton) {
        enableFilter(_networkEnableButton, _networkListButton, @"network")
        if (_networkEnableButton.state) {
            [self didSelectRuleItem:_networkListButton];
        }
    } else if (sender == _portEnableButton) {
        enableFilter(_portEnableButton, _portField, @"port")
        if (_portEnableButton.state) {
            [self textFieldDidChange:[[NSNotification alloc] initWithName:NSTextDidChangeNotification object:_portField userInfo:nil]];
        }
    }
}


- (IBAction)didSelectRuleItem:(id)sender {
    if (sender == _networkListButton && _networkEnableButton.state) {
        [self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule] setObject:_networkListButton.selectedItem.title forKey:@"network"];
    } else if (sender == _protocolButton && _protocolEnableButton.state) {
        [self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule] setObject:_protocolButton.selectedItem.title forKey:@"protocol"];
    } else if ((sender == _inboundTagBox && _inboundEnableButton.state) || sender == _routeToBox) {
        [self textFieldDidChange:[[NSNotification alloc] initWithName:NSTextDidChangeNotification object:sender userInfo:nil]];
    }
}

- (IBAction)showEditView:(id)sender {
    if (self.popover.shown) {
        [self.popover close];
    }
    self.popover = [[NSPopover alloc] init];
    self.popover.behavior = NSPopoverBehaviorApplicationDefined;
    self.popover.contentViewController = [[NSViewController alloc] init];
    if (sender == _editDomainButton) {
        self.popover.contentViewController.view = _domainListEditView;
    } else if (sender == _editIpButton) {
        self.popover.contentViewController.view = _ipListEditView;
    }
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}
- (IBAction)saveDomainOrIPList:(id)sender {
    [self.popover close];
    if (sender == _saveIPListButton) {
        self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule][@"ip"] = [[_ipTextView string] componentsSeparatedByString:@"\n"];
        NSLog(@"%@", self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule][@"ip"]);
    } else {
        self.routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule][@"domain"] = [[_ipTextView string] componentsSeparatedByString:@"\n"];
    }
}

- (IBAction)closeDomainOrIPList:(id)sender {
    [self.popover close];
}


//

- (IBAction)addRemoveSubscription:(id)sender {
    NSLog(@"%@", sender);
    if ([sender selectedSegment] == 0) {
        [_subscriptions addObject:@"enter your subscription link here"];
        [_subscriptionTable reloadData];
    } else if ([sender selectedSegment] == 1 && [_subscriptionTable selectedRow] >= 0 && [_subscriptionTable selectedRow] < _subscriptions.count) {
        [_subscriptions removeObjectAtIndex:[_subscriptionTable selectedRow]];
        [_subscriptionTable reloadData];
    }
    NSLog(@"%@", _subscriptions);
}

// configs

- (IBAction)addRemoveConfig:(id)sender {
    if ([sender selectedSegment] == 0) {
        [_configs addObject:@"/path/to/your/config.json"];
        [_configTable reloadData];
//        [_configTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[_configs count] -1] byExtendingSelection:NO];
//        [_configTable setFocusedColumn:[_configs count] - 1];
    } else if ([sender selectedSegment] == 1 && [_configTable selectedRow] >= 0 && [_configTable selectedRow] < _configs.count) {
        [_configs removeObjectAtIndex:[_configTable selectedRow]];
        [_configTable reloadData];
    }
}

- (BOOL)checkConfig {
    [_checkLabel setHidden:NO];
    NSString* v2rayBinPath = [configWindowController.appDelegate getV2rayPath];
    for (NSString* filePath in _configs) {
        int returnCode = runCommandLine(v2rayBinPath, @[@"-test", @"-config", filePath]);
        if (returnCode != 0) {
            [_checkLabel setHidden:YES];
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:@"%@ is not a valid v2ray config file", filePath]];
            [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                return;
            }];
            return NO;
        }
    }
    return YES;
}

// core
- (IBAction)showCorePath:(id)sender {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.corePathField.stringValue]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.corePathField.stringValue withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:self.corePathField.stringValue]]];
}

- (IBAction)changeEnableRestore:(NSPopUpButton*)sender {
    _enableRestore = [sender indexOfSelectedItem];
}

- (IBAction)showInformation:(id)sender {
    self.popover = [[NSPopover alloc] init];
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.contentViewController = [[NSViewController alloc] init];
    if (sender == _domainIpHelpButton) {
        self.popover.contentViewController.view = _domainIpHelpView;
    } else if (sender == _routeToHelpButton) {
        self.popover.contentViewController.view = _routingTagHelpView;
    }
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}

- (IBAction)showHelp:(id)sender {
    NSString* tabTitle = _mainTabView.selectedTabViewItem.label;
//    NSLog(@"%@", _mainTabView.selectedTabViewItem.label);
    if ([@"Rules" isEqualToString:tabTitle]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com/chapter_02/03_routing.html"]];
    } else if ([@"Outbounds" isEqualToString:tabTitle]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com/chapter_02/01_overview.html#outboundobject"]];
    } else if ([@"Configs" isEqualToString:tabTitle]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com/chapter_02/01_overview.html"]];
    } else if ([@"V2Ray Core" isEqualToString:tabTitle]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.v2ray.com/chapter_00/install.html#download"]];
    }
}


- (void)showAlert:(NSString*)text {
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setInformativeText:text];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    NSLog(@"keypath=%@", keyPath);
    // outboud
    if ([@"selectedOutbound" isEqualToString:keyPath]) {
        if (_selectedOutbound > -1) {
            [_outboundTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedOutbound] byExtendingSelection:NO];
            _outboundJsonView.string = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:_outbounds[_selectedOutbound] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        } else {
            _outboundJsonView.string = @"";
        }
    }
    // rule
    if ([@"selectedRuleSet" isEqualToString:keyPath] && _selectedRuleSet < _routingRuleSets.count) {
        _ruleSetNameField.stringValue = _routingRuleSets[_selectedRuleSet][@"name"];
        [_domainStrategyButton selectItemAtIndex:searchInArray(_routingRuleSets[_selectedRuleSet][@"domainStrategy"], DOMAIN_STRATEGY_LIST)];
        self.selectedRule = _selectedRule; //toggle
    }
    if ([@"selectedRule" isEqualToString:keyPath] && _selectedRuleSet < _routingRuleSets.count && _selectedRule < [_routingRuleSets[_selectedRuleSet][@"rules"] count]  ) {
        if (self.popover.shown) {
            [self.popover close];
        }
        NSDictionary* rules = _routingRuleSets[_selectedRuleSet][@"rules"][_selectedRule];
        BOOL selectedLastRule = _selectedRule + 1 == [_routingRuleSets[_selectedRuleSet][@"rules"] count];
        
        _domainEnableButton.enabled = !selectedLastRule;
        _domainEnableButton.state = rules[@"domain"] != NULL;
        _editDomainButton.enabled = _domainEnableButton.state;
        if (rules[@"domain"]) {
            _domainTextView.string = [rules[@"domain"] componentsJoinedByString:@"\n"];
        } else {
            _domainTextView.string = @"";
        }
        
        _ipEnableButton.enabled = !selectedLastRule;
        _ipEnableButton.state = rules[@"ip"] != NULL;
        _editIpButton.enabled = _ipEnableButton.state;
        if (rules[@"ip"]) {
            _ipTextView.string = [rules[@"ip"] componentsJoinedByString:@"\n"];
        } else {
            _ipTextView.string = @"";
        }
        
        _inboundEnableButton.enabled = !selectedLastRule;
        _inboundEnableButton.state = rules[@"inboundTag"] != NULL;
        _inboundTagBox.enabled = _inboundEnableButton.state;
        _inboundTagBox.stringValue = nilCoalescing(rules[@"inboundTag"], @"");
        
        _protocolEnableButton.enabled = !selectedLastRule;
        _protocolEnableButton.state = rules[@"protocol"] != NULL;
        _protocolButton.enabled = _protocolEnableButton.state;
        [_protocolButton selectItemAtIndex:searchInArray(rules[@"protocol"], SNIFFING_PROTOCOL)];
        
        _portEnableButton.enabled = !selectedLastRule;
        _portEnableButton.state = rules[@"port"] != NULL;
        _portField.enabled = _portEnableButton.state && !selectedLastRule;
        _portField.objectValue = nilCoalescing(rules[@"port"], @"0-65535");
        
        _networkEnableButton.enabled = !selectedLastRule;
        _networkEnableButton.state = rules[@"network"] != NULL;
        _networkListButton.enabled = _networkEnableButton.state;
        [_networkListButton selectItemAtIndex:searchInArray(rules[@"network"], ROUTING_NETWORK_LIST)];
        
        
        _routeToBox.stringValue = rules[@"outboundTag"] ? rules[@"outboundTag"] : rules[@"balancerTag"];
    }
}

- (IBAction)changePassword:(id)sender {
    if ([[_encryptionKeyField stringValue] isEqualToString:[_encryptionKeyConfirmField stringValue]]) {
        if ([[_encryptionKeyField stringValue] length] > 32) {
            self.encryptionKey = [_encryptionKeyField.stringValue substringToIndex:32];
        } else {
            self.encryptionKey = [_encryptionKeyConfirmField.stringValue stringByPaddingToLength:32 withString:@"-" startingAtIndex:0];
        }
        [_changeIndicatorField setStringValue:@"success"];
    } else {
        [_changeIndicatorField setStringValue:@"two password do not match each other."];
    }
}

@end
