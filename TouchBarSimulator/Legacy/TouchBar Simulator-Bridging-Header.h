//
//  TouchBar Simulator-Bridging-Header.h
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/12/23.
//

#ifndef TouchBar_Simulator_Bridging_Header_h
#import "ViewBridge.h"

@interface NSWindow (Private)
    - (void)_setPreventsActivation:(bool)preventsActivation;
@end

#define TouchBar_Simulator_Bridging_Header_h


#endif /* TouchBar_Simulator_Bridging_Header_h */
