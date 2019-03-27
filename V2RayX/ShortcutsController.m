//
//  ShortcutsController.m
//  V2RayX
//
//  Created by Jarvis on 2018/8/28.
//  Copyright © 2018年 Project V2Ray. All rights reserved.
//

#import "ShortcutsController.h"
#import <MASShortcut/Shortcut.h>

@implementation ShortcutsController

+ (void)bindShortcuts {
    MASShortcutBinder* binder = [MASShortcutBinder sharedBinder];
    [binder
     bindShortcutWithDefaultsKey: @"LoadUnloadCore"
     toAction:^{
         [[NSNotificationCenter defaultCenter] postNotificationName: @"NOTIFY_LOAD_UNLOAD_SHORTCUT" object: nil];
     }];
}

@end
