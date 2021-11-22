//
//  AppDelegate.m
//  TouchBar Simulator
//
//  Created by Jeremy on 8/15/20.
//

#import <ViewBridge/ViewBridge.h>

#import "AppDelegate.h"

@interface NSWindow (Private)
- (void )_setPreventsActivation:(bool)preventsActivation;
@end

@interface AppDelegate ()

@property (strong) IBOutlet NSPanel *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window.worksWhenModal = YES;
    [self.window _setPreventsActivation:YES];
    [self.window setIgnoresMouseEvents:NO];
    // Touchbar pixel size @2x scaled is 2008 x 60
    //self.window.aspectRatio = NSMakeSize(502, 15);
    
    // Retina scaling (1004 x 30) + 10px padding is 1014 x 40
    self.window.aspectRatio = NSMakeSize(507, 20); //NSMakeSize(169, 5);
    self.window.movableByWindowBackground = NO;
    self.window.contentView.wantsLayer = YES;
    self.window.contentView.layer.backgroundColor = NSColor.blackColor.CGColor;
    self.window.collectionBehavior |= NSWindowCollectionBehaviorCanJoinAllSpaces;
    
    [NSRemoteViewController requestViewController:@"TouchBarSimulatorService" fromServiceWithBundleIdentifier:@"com.github.jslegendre.TouchBarSimulatorService" connectionHandler:^(NSRemoteViewController* remoteViewController){
        self.window.contentViewController = remoteViewController;
    }];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [(NSRemoteViewController *)self.window.contentViewController disconnect];
}


@end
