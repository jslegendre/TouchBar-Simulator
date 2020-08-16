//
//  NSRemoteView.h
//  TouchBar-Simulator
//
//  Created by Jeremy on 8/15/20.
//

@interface NSRemoteView : NSView
@property(nonatomic, copy) NSString *serviceSubclassName;
@property(nonatomic, copy) NSString *serviceName;
- (BOOL)advanceToRunPhaseIfNeeded:(void (^)(NSError*))arg1;
- (void)setSynchronizesImplicitAnimations:(BOOL)arg1;
- (void)setShouldMaskToBounds:(BOOL)arg1;

@end
