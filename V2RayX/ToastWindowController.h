//
//  ToastWindowController.h
//  V2RayX
//
//  Created by Jarvis on 2018/8/28.
//  Copyright © 2018年 Project V2Ray. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ToastWindowController : NSWindowController

@property (strong) NSString *message;

- (void)fadeInHud;
@end
