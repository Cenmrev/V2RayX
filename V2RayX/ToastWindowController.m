//
//  ToastWindowController.m
//  V2RayX
//
//  Created by Jarvis on 2018/8/28.
//  Copyright © 2018年 Project V2Ray. All rights reserved.
//

#import "ToastWindowController.h"
#import <Quartz/Quartz.h>

@interface ToastWindowController ()
@property (weak) IBOutlet NSView *panelView;
@property (weak) IBOutlet NSTextField *titleTextField;
@property (strong) NSTimer *timerToFadeOut;
@property (assign) BOOL fadingOut;
@end

@implementation ToastWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.shouldCascadeWindows = NO;
    
    if (self.window) {
        NSWindow *win = self.window;
        [win setOpaque:NO];
        [win setBackgroundColor:[NSColor clearColor]];
        [win setStyleMask:NSWindowStyleMaskBorderless];
        [win setHidesOnDeactivate:NO];
        [win setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [win setLevel:NSFloatingWindowLevel];
        [win orderFrontRegardless];
    }
    CALayer *viewLayer = [[CALayer alloc] init];
    [viewLayer setBackgroundColor: CGColorCreateGenericRGB(0.05, 0.05, 0.05, 0.75)];
    [viewLayer setCornerRadius:18.0];
    self.panelView.wantsLayer = YES;
    self.panelView.layer = viewLayer;
    self.panelView.layer.opaque = 0.0;
    self.titleTextField.stringValue = self.message;
    
    [self setupHud];
}

- (void)setupHud {
    [self.titleTextField sizeToFit];
    CGFloat kHudHorizontalMargin = 30;
    CGFloat kHudHeight = 90.0;
    
    CGRect labelFrame = self.titleTextField.frame;
    CGRect hubWindowFrame = self.window.frame;
    hubWindowFrame.size.width = labelFrame.size.width + kHudHorizontalMargin * 2;
    hubWindowFrame.size.height = kHudHeight;
    
    NSRect screenRect = NSScreen.screens[0].visibleFrame;
    hubWindowFrame.origin.x = (screenRect.size.width - hubWindowFrame.size.width) * 0.5;
    hubWindowFrame.origin.y = (screenRect.size.height - hubWindowFrame.size.height) * 0.5;
    [self.window setFrame:hubWindowFrame display:YES];
    
    NSRect viewFrame = hubWindowFrame;
    viewFrame.origin.x = 0;
    viewFrame.origin.y = 0;
    self.panelView.frame = viewFrame;
    
    labelFrame.origin.x = kHudHorizontalMargin;
    labelFrame.origin.y = (hubWindowFrame.size.height - labelFrame.size.height) * 0.5;
    self.titleTextField.frame = labelFrame;
}

- (void)fadeInHud {
    if (_timerToFadeOut) {
        [_timerToFadeOut invalidate];
        _timerToFadeOut = nil;
    }
    
    _fadingOut = NO;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.35];
    [CATransaction setCompletionBlock:^{
        [self didFadeIn];
    }];
    self.panelView.layer.opacity = 1.0;
    [CATransaction commit];
}

- (void)didFadeIn {
    _timerToFadeOut = [NSTimer scheduledTimerWithTimeInterval:0.35 target:self selector:@selector(fadeOutHud) userInfo:nil repeats:NO];
}

- (void)fadeOutHud {
    _fadingOut = YES;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.35];
    [CATransaction setCompletionBlock:^{
        [self didFadeOut];
    }];
    self.panelView.layer.opacity = 0.0;
    [CATransaction commit];
}

- (void)didFadeOut {
    if (_fadingOut) {
        [self.window orderOut:self];
    }
    _fadingOut = NO;
}

@end
