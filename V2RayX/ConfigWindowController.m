//
//  ConfigWindowController.m
//  V2RayX
//
//  Copyright © 2016年 Project V2Ray. All rights reserved.
//

#import "ConfigWindowController.h"

@interface ConfigWindowController () {
    NSMutableArray *profiles;
}

@end

@implementation ConfigWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    //set textField Display
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    [_portField setFormatter:formatter];
    [_alterIdField setFormatter:formatter];
    [_localPortField setFormatter:formatter];
    
    profiles = [[NSMutableArray alloc] init];
    
    //read defaults
    NSArray *defaultsArray = [[self delegate] readDefaultsAsArray];
    [self setLocalPort:[defaultsArray[2] integerValue]];
    [self setUdpSupport:[defaultsArray[3] boolValue]];
    profiles = defaultsArray[4];
    [_profileTable reloadData];
    _selectedServerIndex = [defaultsArray[5] integerValue];
}


// set controller as profilesTable's datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [profiles count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([profiles count] > 0) {
        ServerProfile* p = [profiles objectAtIndex:row];
        return [p address];
    } else {
        return nil;
    }
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex{
    [selectedProfile setAddress:anObject];
    [aTableView reloadData];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    if ([profiles count] > 0) {
        [self setSelectedProfile:[profiles objectAtIndex:[_profileTable selectedRow]]];
        [self setSelectedServerIndex:[_profileTable selectedRow]];
    }
}

- (IBAction)addRemoveServer:(id)sender {
    if ([sender selectedSegment] == 0) {
        ServerProfile* newProfile = [[ServerProfile alloc] init];
        [profiles addObject:newProfile];
        [_profileTable reloadData];
        [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:([profiles count] - 1)] byExtendingSelection:NO];
    } else if ([sender selectedSegment] == 1 && [profiles count] > 0) {
        NSInteger originalSelectedServerIndex = [_profileTable selectedRow];
        [profiles removeObjectAtIndex:originalSelectedServerIndex];
        if ([profiles count] > 0) {
            if (originalSelectedServerIndex < [profiles count]) {
                [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:originalSelectedServerIndex] byExtendingSelection:NO];
            } else {
                [_profileTable selectRowIndexes:[NSIndexSet indexSetWithIndex:([profiles count] - 1)] byExtendingSelection:NO];
            }
        } else { // all the profiles are deleted;
            [self setSelectedServerIndex:-1];
            [self setSelectedProfile:nil];
        }
        [_profileTable reloadData];
    }
}

- (IBAction)cancel:(id)sender {
    [[self window] close];
}

- (IBAction)okSave:(id)sender {
    // save settings to file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:udpSupport]  forKey:@"udpSupport"];
    [defaults setObject:[NSNumber numberWithInteger:localPort] forKey:@"localPort"];
    NSMutableArray* profileDicArray = [[NSMutableArray alloc] init];
    for (ServerProfile *p in profiles) {
        [profileDicArray addObject:[p toArray]];
    }
    [defaults setObject:profileDicArray forKey:@"profiles"];
    [defaults setObject:[NSNumber numberWithInteger:[_profileTable selectedRow]] forKey:@"selectedServerIndex"];
    
    [[self delegate] configurationDidChange];
    [[self window] close];
}


@synthesize selectedProfile;
@synthesize localPort;
@synthesize udpSupport;
@end
