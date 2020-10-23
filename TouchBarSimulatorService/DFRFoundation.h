//
//  TouchBarSimulatorServiceProtocol.h
//  TouchBarSimulatorService
//
//  Created by Jeremy on 8/15/20.
//

/* From DFRFoundation.framework */
@class DFRTouchBarSimulator, DFRTouchBar;

typedef enum  {
    DFRTouchBarFirstGeneration = 2,
    DFRTouchBarSecondGeneration = 3,
} DFRTouchBarStyle;

/*!
 @function DFRTouchBarSimulatorCreate
 @abstract C-style initializer for DFRTouchBarSimulator
 @param generation First generation (2) uses legacy API, second generation (3) uses newer API as shown in this project
 @param properties This is always NULL so I'm really not sure what options exist.
 @param sameAsGeneration Not sure why this is needed but if it holds a different value than generation, it won't work.
 */
DFRTouchBarSimulator* DFRTouchBarSimulatorCreate(DFRTouchBarStyle generation, id properties, DFRTouchBarStyle sameAsGeneration);

DFRTouchBar* DFRTouchBarSimulatorGetTouchBar(DFRTouchBarSimulator*);

BOOL DFRTouchBarSimulatorPostEventWithMouseActivity(DFRTouchBarSimulator*, NSEventType type, NSPoint p);

CGDisplayStreamRef DFRTouchBarCreateDisplayStream(DFRTouchBar *touchBar, int displayID, dispatch_queue_t queue, CGDisplayStreamFrameAvailableHandler handler);

void DFRTouchBarSimulatorInvalidate(DFRTouchBarSimulator*);


/* Legacy
void DFRSetStatus(int status);
BOOL DFRFoundationPostEventWithMouseActivity(NSEventType type, NSPoint p);
void DFRSetStatus(int status); CGDisplayStreamRef SLSDFRDisplayStreamCreate(int displayID, dispatch_queue_t queue, CGDisplayStreamFrameAvailableHandler handler);
*/
