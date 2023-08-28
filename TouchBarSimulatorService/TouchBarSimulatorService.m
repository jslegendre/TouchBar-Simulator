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

typedef struct {
    simd_float2 inSize;
    simd_float2 outSize;
} UpscalerArgs;


@interface TouchBarSimulatorStreamView : NSView
@property DFRTouchBarSimulator *simulator;
@end

@implementation TouchBarSimulatorStreamView

- (void)mouseEvent:(NSEvent *)event {
    /*
    NSPoint windowLocation = event.locationInWindow;
    //if (self.frame.size.width != 1004) {
        CGFloat x = windowLocation.x * (1085 / self.frame.size.width);
        CGFloat y = windowLocation.y * (30 / self.frame.size.height);
    
        windowLocation.x = x;
        windowLocation.y = y;
    //}
    NSPoint location = [self convertPoint:windowLocation fromView:nil];
    NSLog(@"location:%f, %f, WIN: %f, %f, FRAME: %f.", location.x, location.y, windowLocation.x, windowLocation.y, self.frame.size.width);
     */
    // FIXME: Precision
    
    NSPoint windowLocation = event.locationInWindow;
    NSPoint viewLocation = [self convertPoint:windowLocation fromView:self];
    // linear-transforming viewLocation
    NSPoint location = {viewLocation.x / self.frame.size.width * 1004.0,
        viewLocation.y / self.frame.size.height * 30.0};
    //NSLog(@"location:%f, %f, WIN: %f, %f, FRAME: %f.", location.x, location.y, windowLocation.x, windowLocation.y, self.frame.size.width);
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

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;
    return self;
}

@end

@interface TouchBarSimulatorService () <MTKViewDelegate>
@property CGDisplayStreamRef touchBarStream;
@property DFRTouchBarSimulator *simulator;
@property (nonatomic,strong) MTKView *mtlView;
@property (nonatomic,strong) id<MTLDevice> device;
@property (nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic,strong) MTLRenderPipelineDescriptor *renderPipelineDesc;
@property (nonatomic, strong) id<MTLFunction> upscaler;
@property (nonatomic, strong) id<MTLFunction> filter;
@property (nonatomic, strong) id<MTLFunction> applySmoothing;
@property IOSurfaceRef surface;
@end

@implementation TouchBarSimulatorService

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)drawableSize {}

- (void)drawInMTKView:(MTKView *)view {
    if(!_surface) return;
    
    size_t surfaceWidth = IOSurfaceGetWidth(_surface);
    size_t surfaceHeight = IOSurfaceGetHeight(_surface);

    MTLTextureDescriptor *newTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:surfaceWidth height:surfaceHeight mipmapped:NO];
    [newTextureDescriptor setUsage:MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite];
    
    
    id<MTLTexture> newTexture = [_device newTextureWithDescriptor:newTextureDescriptor iosurface:_surface plane:0];
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];

    id<MTLComputePipelineState> pipelineState = [_device newComputePipelineStateWithFunction:_filter error:nil];
    [commandEncoder setComputePipelineState:pipelineState];
    [commandEncoder setTexture:newTexture atIndex:0];
    MTLSize threadGroupCount = MTLSizeMake(8, 6, 1);
    MTLSize threadGroups = MTLSizeMake(surfaceWidth / threadGroupCount.width, surfaceHeight / threadGroupCount.height, 1);
    [commandEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupCount];

    pipelineState = [_device newComputePipelineStateWithFunction:_applySmoothing error:nil];
    [commandEncoder setComputePipelineState:pipelineState];
    [commandEncoder setTexture:newTexture atIndex:0];
    [commandEncoder setTexture:newTexture atIndex:1];
    threadGroupCount = MTLSizeMake(8, 6, 1);
    threadGroups = MTLSizeMake(surfaceWidth / threadGroupCount.width, surfaceHeight / threadGroupCount.height, 1);
    [commandEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupCount];

//    float outWidth = surfaceWidth * 2;// _mtlView.frame.size.width * 4;
//    float outHeight = surfaceHeight * 2;//_mtlView.frame.size.height * 4;
//
//    UpscalerArgs args = {
//        .inSize = { (float)surfaceWidth, (float)surfaceHeight },
//        .outSize = { outWidth, outHeight },
//    };
//
//    MTLTextureDescriptor *finalTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:outWidth height:outHeight mipmapped:NO];
//    [finalTextureDescriptor setUsage:MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite];
//    finalTextureDescriptor.width = outWidth;
//    finalTextureDescriptor.height = outHeight;
//    finalTextureDescriptor.storageMode = MTLStorageModePrivate;
//    id<MTLTexture> finalTexture = [_device newTextureWithDescriptor:finalTextureDescriptor];
//
//    pipelineState = [_device newComputePipelineStateWithFunction:_upscaler error:nil];
//    commandEncoder = [commandBuffer computeCommandEncoder];
//    [commandEncoder setComputePipelineState:pipelineState];
//    [commandEncoder setTexture:newTexture atIndex:0];
//    [commandEncoder setTexture:finalTexture atIndex:1];
//    [commandEncoder setBytes:&args length:sizeof(UpscalerArgs) atIndex:0];
//    threadGroupCount = MTLSizeMake(8, 6, 1);
//    threadGroups = MTLSizeMake(outWidth / threadGroupCount.width, outHeight / threadGroupCount.height, 1);
//    [commandEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupCount];
    
    [commandEncoder endEncoding];

    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_mtlView.currentRenderPassDescriptor];
    id <MTLRenderPipelineState> state = [_device newRenderPipelineStateWithDescriptor:_renderPipelineDesc error:NULL];
    [renderEncoder setRenderPipelineState:state];
    [renderEncoder setFragmentTexture:newTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:_mtlView.currentDrawable];
    [commandBuffer commit];

    CFRelease(_surface);
    _surface = NULL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.device = MTLCreateSystemDefaultDevice();
    
    self.mtlView = [[MTKView alloc] initWithFrame:self.view.frame device:self.device];
    self.mtlView.layer.backgroundColor = NSColor.clearColor.CGColor;
    self.mtlView.layer.opaque = NO;
    self.mtlView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtlView.delegate = self;
    self.mtlView.framebufferOnly = NO;
    self.mtlView.autoResizeDrawable = YES;
    self.mtlView.enableSetNeedsDisplay = YES;
    self.mtlView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;

    self.commandQueue = [self.device newCommandQueue];
    self.mtlView.frame = NSMakeRect(0, 0, 1004, 30);
    [self.view addSubview:_mtlView];
    
    [_mtlView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_mtlView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:_mtlView
                                      attribute:NSLayoutAttributeHeight
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:_mtlView
                                      attribute:NSLayoutAttributeWidth
                                      multiplier:(_mtlView.frame.size.height / _mtlView.frame.size.width)
                                      constant:0]];
    
    MTKView *mv = self.mtlView;
    NSDictionary *dict = NSDictionaryOfVariableBindings(mv);
    NSArray *constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mv]-0-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:dict];

    [self.view addConstraints:constraintsArray];
    [NSLayoutConstraint activateConstraints:constraintsArray];
    [self.view layoutSubtreeIfNeeded];

    id <MTLLibrary> lib = [_device newDefaultLibraryWithBundle:[NSBundle bundleForClass:[TouchBarSimulatorService class]] error:nil];
    _renderPipelineDesc = [MTLRenderPipelineDescriptor new];
    _renderPipelineDesc.sampleCount = 1;
    _renderPipelineDesc.alphaToCoverageEnabled = YES;
    _renderPipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    _renderPipelineDesc.vertexFunction = [lib newFunctionWithName:@"vertexShader"];
    _renderPipelineDesc.fragmentFunction = [lib newFunctionWithName:@"fragmentShader"];
    

    _upscaler = [lib newFunctionWithName:@"BicubicMain"];
    _filter = [lib newFunctionWithName:@"removeBlackColor"];
    _applySmoothing = [lib newFunctionWithName:@"smoothEdges"];

    
    TouchBarSimulatorStreamView *streamView = [[TouchBarSimulatorStreamView alloc] initWithFrame:NSMakeRect(0, 0, 1004, 30)];// 1004, 30
    [self.view addSubview:streamView];
    streamView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    self.simulator = DFRTouchBarSimulatorCreate(3, 0, 3); // 3,0,3
    [streamView setSimulator:self.simulator];
    
    DFRTouchBar *touchBar = DFRTouchBarSimulatorGetTouchBar(self.simulator);
    self.touchBarStream = DFRTouchBarCreateDisplayStream(touchBar, 0, dispatch_get_main_queue(), ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef  _Nullable frameSurface, CGDisplayStreamUpdateRef  _Nullable updateRef) {
        self->_surface = frameSurface;
        CFRetain(frameSurface);
        self->_mtlView.needsDisplay = YES;
//        streamView.layer.contents = (__bridge id _Nullable)(frameSurface);
    });
    
    if (self.touchBarStream) {
        CGDisplayStreamStart(self.touchBarStream);
    }
}

- (void) dealloc { // FIXME: VIEWDIDDISAPPEAR INVOKED MULTIPLE TIMES!!
    if (self.touchBarStream) {
        DFRTouchBarSimulatorInvalidate(self.simulator);
        CGDisplayStreamStop(self.touchBarStream);
        CFRelease(self.touchBarStream);
    }
    NSLog(@"View dealloced."); // FIXME: SEEMS NEVER INVOKED!!!
    //[super dealloc];
}

@end
