//
//  NSRemoteViewService.h
//  TouchBar Simulator
//
//  Created by Jeremy on 8/15/20.
//

@class NSRemoteViewController;
typedef void (^NSRemoteViewControllerConnectionHandler)(NSRemoteViewController *);

@interface NSRemoteViewController : NSViewController

+ (void)requestViewController:(NSString *)className
fromServiceWithBundleIdentifier:(NSString *)bundleIdentifier
            connectionHandler:(NSRemoteViewControllerConnectionHandler)connectionHandler;

@property (readonly) NSString *serviceViewControllerClassName;
@property (readonly) NSString *serviceBundleIdentifier;
@property (readonly) NSString *remoteViewIdentifier;

- (void)disconnect;

- (id)exportedObject;
- (NSXPCInterface *)exportedInterface;
- (NSXPCInterface *)serviceViewControllerInterface;
- (id)serviceViewControllerProxyWithErrorHandler:(void (^)(NSError *error))errorHandler;
- (id)serviceViewControllerProxy;

- (void)setServiceViewControllerClassName:(NSString *)className;
- (void)setServiceBundleIdentifier:(NSString *)bundleIdentifier;
- (void)setServiceListenerEndpoint:(NSXPCListenerEndpoint *)listenerEndpoint;
@end
