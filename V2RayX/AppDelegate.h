//
//  AppDelegate.h
//  V2RayX
//
//  Copyright © 2016年 Project V2Ray. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConfigWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, ConfigWindowControllerDelegate>

- (IBAction)showHelp:(id)sender;
- (IBAction)enableProxy:(id)sender;
- (IBAction)chooseAutoMode:(id)sender;
- (IBAction)chooseGlobalMode:(id)sender;
- (IBAction)showConfigWindow:(id)sender;
- (IBAction)editPac:(id)sender;
//- (NSArray*)readDefaultsAsArray;
- (NSDictionary*)readDefaultsAsDictionary;
@property (strong, nonatomic)  NSStatusItem *statusBarItem;
@property (strong, nonatomic) IBOutlet NSMenu *statusBarMenu;
@property (weak, nonatomic) IBOutlet NSMenuItem *v2rayStatusItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *enabelV2rayItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *autoModeItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *globalModeItem;
@property (weak, nonatomic) IBOutlet NSMenuItem *serversItem;
@property (weak, nonatomic) IBOutlet NSMenu *serverListMenu;

@end

