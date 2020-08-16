//
//  TouchBarSimulatorService.m
//  TouchBarSimulatorService
//
//  Created by Jeremy on 8/15/20.
//

#import <AppKit/AppKit.h>
#import "TouchBarSimulatorService.h"
#import "DFRFoundation.h"
@import QuartzCore;


@interface TouchBarSimulatorStreamView : NSView
@property DFRTouchBarSimulator *simulator;
@end

@implementation TouchBarSimulatorStreamView

- (void)mouseEvent:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    DFRTouchBarSimulatorPostEventWithMouseActivity(self.simulator, event.type, location);
}

- (void)mouseDown:(NSEvent *)event {
    [self mouseEvent:event];
}

- (void)mouseUp:(NSEvent *)event {
    [self mouseEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self mouseEvent:event];
}

- (void)mouseEntered:(NSEvent *)event {
    [self mouseEvent:event];
}

- (void)mouseMoved:(NSEvent *)event {
    [self mouseEvent:event];
}

//- (void)awakeFromNib {
//    self.layer.backgroundColor = NSColor.blackColor.CGColor;
//    self.wantsLayer = YES;
//}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    self.layer.backgroundColor = NSColor.blackColor.CGColor;
    self.wantsLayer = YES;
    return self;
}

@end

@interface TouchBarSimulatorServiceView ()
@end

@implementation TouchBarSimulatorServiceView

- (void)awakeFromNib {
    [self.window setColorSpace:[NSColorSpace displayP3ColorSpace]];
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.blackColor.CGColor;
}

@end

@interface TouchBarSimulatorService ()
@property CGDisplayStreamRef touchBarStream;
@property DFRTouchBarSimulator *simulator;
@end

@implementation TouchBarSimulatorService

- (void)viewDidLoad {
    [super viewDidLoad];

    TouchBarSimulatorStreamView *streamView = [[TouchBarSimulatorStreamView alloc] initWithFrame:NSMakeRect(5, 5, 1004, 30)];
    [self.view addSubview:streamView];
        
    self.simulator = DFRTouchBarSimulatorCreate(3, 0, 3);
    DFRTouchBar *touchBar = DFRTouchBarSimulatorGetTouchBar(self.simulator);
    
    self.touchBarStream = DFRTouchBarCreateDisplayStream(touchBar, 0, dispatch_get_main_queue(), ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef  _Nullable frameSurface, CGDisplayStreamUpdateRef  _Nullable updateRef) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [streamView.layer setContents:(__bridge id _Nullable)(frameSurface)];
        [CATransaction commit];
    });
    
    if (self.touchBarStream) {
        CGDisplayStreamStart(self.touchBarStream);
    }
    
    [streamView setSimulator:self.simulator];
}

- (void)viewWillDisappear {
    if (self.touchBarStream) {
        DFRTouchBarSimulatorInvalidate(self.simulator);
        CGDisplayStreamStop(self.touchBarStream);
        CFRelease(self.touchBarStream);
    }
}
@end
