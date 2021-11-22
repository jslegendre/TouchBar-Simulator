//
//  TouchBarSimulatorService.m
//  TouchBarSimulatorService
//
//  Created by Jeremy on 8/15/20.
//

#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>
#import <CoreImage/CoreImage.h>
#import "TouchBarSimulatorService.h"
#import "DFRFoundation.h"


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

@interface TouchBarSimulatorService () <MTKViewDelegate>
@property CGDisplayStreamRef touchBarStream;
@property DFRTouchBarSimulator *simulator;
@property (nonatomic,strong) MTKView *mtlView;
@property (nonatomic,strong) CIImage *frame;
@property (nonatomic,strong) id<MTLDevice> device;
@property (nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic,strong) CIContext *context;
@end

@implementation TouchBarSimulatorService
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

- (void)drawInMTKView:(MTKView *)view {
    if(!_frame) return;
    id<MTLTexture> outputTexture = _mtlView.currentDrawable.texture;
    if (!outputTexture) return;
    if (_frame.extent.size.width == 0) return;
    
    _mtlView.drawableSize = _frame.extent.size;
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    [self.context render:_frame toMTLTexture:outputTexture commandBuffer:commandBuffer bounds:_frame.extent colorSpace:CGColorSpaceCreateDeviceRGB()];
    [commandBuffer presentDrawable:self.mtlView.currentDrawable];
    [commandBuffer commit];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.frame = nil;
    self.device = MTLCreateSystemDefaultDevice();
    self.mtlView = [[MTKView alloc] initWithFrame:self.view.frame device:self.device];
    self.mtlView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtlView.delegate = self;
    self.mtlView.framebufferOnly = NO;
    self.mtlView.autoResizeDrawable = YES;
    self.mtlView.enableSetNeedsDisplay = YES;
    self.context = [CIContext contextWithMTLDevice:self.device options:@{kCIContextWorkingColorSpace: (__bridge id)CGColorSpaceCreateDeviceRGB(), kCIContextUseSoftwareRenderer: [NSNumber numberWithBool:NO], kCIContextHighQualityDownsample: [NSNumber numberWithBool:YES]}];
    self.commandQueue = [self.device newCommandQueue];
    self.mtlView.frame = NSMakeRect(5, 5, 1004, 30);
    [self.view addSubview:_mtlView];
    
    TouchBarSimulatorStreamView *streamView = [[TouchBarSimulatorStreamView alloc] initWithFrame:NSMakeRect(5, 5, 1004, 30)];
    [self.view addSubview:streamView];
    
    self.simulator = DFRTouchBarSimulatorCreate(3, 0, 3);
    [streamView setSimulator:self.simulator];
    
    DFRTouchBar *touchBar = DFRTouchBarSimulatorGetTouchBar(self.simulator);
    self.touchBarStream = DFRTouchBarCreateDisplayStream(touchBar, 0, dispatch_get_main_queue(), ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef  _Nullable frameSurface, CGDisplayStreamUpdateRef  _Nullable updateRef) {
        self->_frame = [CIImage imageWithIOSurface:frameSurface];
        self->_mtlView.needsDisplay = YES;
//        streamView.layer.contents = (__bridge id _Nullable)(frameSurface);
    });
    
    if (self.touchBarStream) {
        CGDisplayStreamStart(self.touchBarStream);
    }
}

- (void)viewWillDisappear {
    if (self.touchBarStream) {
        DFRTouchBarSimulatorInvalidate(self.simulator);
        CGDisplayStreamStop(self.touchBarStream);
        CFRelease(self.touchBarStream);
    }
}
@end
