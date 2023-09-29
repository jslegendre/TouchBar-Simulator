//
//  AppDelegate.m
//  TouchBar Simulator
//
//  Created by Jeremy on 8/15/20.
//

#import "ViewBridge.h"
#import "LeAppDelegate.h"

@interface TBSimulatorPanel : NSPanel
@property (weak) IBOutlet NSApplication *filewoner;
@end

@implementation TBSimulatorPanel

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)isResizable {
    return YES;
}

@end

@interface LEAppDelegate ()

@property (strong) IBOutlet NSPanel *window;
//@property (strong) NSPanel* window;
@end

@implementation LEAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window = [[NSPanel alloc] init];
    self.window.contentView = [[NSView alloc] init];
    //self.window.styleMask &= ~(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable);
    self.window.styleMask = 0b10011011;
    
    self.window.contentAspectRatio = NSMakeSize(1014, 40);
    self.window.movableByWindowBackground = NO;
    self.window.contentView.wantsLayer = YES;
    self.window.level = kCGFloatingWindowLevel;
    self.window.contentView.layer.backgroundColor = NSColor.clearColor.CGColor;
    
    NSString *savedWindowFrame = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedWindowFrame"];
    if (savedWindowFrame) {
        [self.window setFrameFromString:savedWindowFrame];
    }
    
    NSRemoteView *remoteView = [[NSRemoteView alloc] initWithFrame: CGRectMake(0, 0, 1004, 30)];
    [remoteView setSynchronizesImplicitAnimations:NO];
    [remoteView setServiceName:@"moe.ueharayou.TouchBarSimulatorService"];
    [remoteView setServiceSubclassName:@"TouchBarSimulatorService"];
    [remoteView advanceToRunPhaseIfNeeded:^(NSError *err){
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSView *contentView = self.window.contentView;
            [contentView addSubview:remoteView];

            [remoteView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [remoteView setShouldMaskToBounds:NO];
            [[remoteView layer] setAllowsEdgeAntialiasing:YES];

            NSDictionary *dict = NSDictionaryOfVariableBindings(remoteView);
            NSArray *constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[remoteView]-5-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:dict];

            constraintsArray = [constraintsArray arrayByAddingObjectsFromArray:
                                [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[remoteView]-5-|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:dict]];
            [contentView addConstraints:constraintsArray];
            [NSLayoutConstraint activateConstraints:constraintsArray];

            [contentView layoutSubtreeIfNeeded];
            
        });
    }];
    
    [self.window orderFrontRegardless];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] setObject:self.window.stringWithSavedFrame forKey:@"savedWindowFrame"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [(NSRemoteViewController *)self.window.contentViewController disconnect];
}


@end
