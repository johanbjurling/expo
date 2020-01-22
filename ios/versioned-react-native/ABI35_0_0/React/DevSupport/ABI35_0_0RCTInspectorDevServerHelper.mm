// Copyright (c) Facebook, Inc. and its affiliates.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

#import "ABI35_0_0RCTInspectorDevServerHelper.h"

#if ABI35_0_0RCT_DEV

#import <UIKit/UIKit.h>
#import <ReactABI35_0_0/ABI35_0_0RCTLog.h>

#import "ABI35_0_0RCTDefines.h"
#import "ABI35_0_0RCTInspectorPackagerConnection.h"

static NSString *const kDebuggerMsgDisable = @"{ \"id\":1,\"method\":\"Debugger.disable\" }";

static NSString *getServerHost(NSURL *bundleURL, NSNumber *port)
{
  NSString *host = [bundleURL host];
  if (!host) {
    host = @"localhost";
  }

  // this is consistent with the Android implementation, where http:// is the
  // hardcoded implicit scheme for the debug server. Note, packagerURL
  // technically looks like it could handle schemes/protocols other than HTTP,
  // so rather than force HTTP, leave it be for now, in case someone is relying
  // on that ability when developing against iOS.
  return [NSString stringWithFormat:@"%@:%@", host, port];
}

static NSURL *getInspectorDeviceUrl(NSURL *bundleURL)
{
  NSNumber *inspectorProxyPort = @8082;
  NSString *escapedDeviceName = [[[UIDevice currentDevice] name] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
  NSString *escapedAppName = [[[NSBundle mainBundle] bundleIdentifier] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
  return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/inspector/device?name=%@&app=%@",
                                                        getServerHost(bundleURL, inspectorProxyPort),
                                                        escapedDeviceName,
                                                        escapedAppName]];
}

static NSURL *getAttachDeviceUrl(NSURL *bundleURL, NSString *title)
{
  NSNumber *metroBundlerPort = @8081;
  NSString *escapedDeviceName = [[[UIDevice currentDevice] name] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet];
  NSString *escapedAppName = [[[NSBundle mainBundle] bundleIdentifier] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet];
  return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/attach-debugger-nuclide?title=%@&device=%@&app=%@",
                               getServerHost(bundleURL, metroBundlerPort),
                               title,
                               escapedDeviceName,
                               escapedAppName]];
}

@implementation ABI35_0_0RCTInspectorDevServerHelper

ABI35_0_0RCT_NOT_IMPLEMENTED(- (instancetype)init)

static NSMutableDictionary<NSString *, ABI35_0_0RCTInspectorPackagerConnection *> *socketConnections = nil;

static void sendEventToAllConnections(NSString *event)
{
  for (NSString *socketId in socketConnections) {
    [socketConnections[socketId] sendEventToAllConnections:event];
  }
}

static void displayErrorAlert(UIViewController *view, NSString *message) {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:nil
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [view presentViewController:alert animated:YES completion:nil];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 2.5),
      dispatch_get_main_queue(),
      ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
      });
}

+ (void)attachDebugger:(NSString *)owner
         withBundleURL:(NSURL *)bundleURL
              withView:(UIViewController *)view
{
  NSURL *url = getAttachDeviceUrl(bundleURL, owner);

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];

  __weak UIViewController *viewCapture = view;
  [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
    ^(NSData *_Nullable data,
      NSURLResponse *_Nullable response,
      NSError *_Nullable error) {
      UIViewController *viewCaptureStrong = viewCapture;
      if (error != nullptr && viewCaptureStrong != nullptr) {
        displayErrorAlert(viewCaptureStrong, @"The request to attach Nuclide couldn't reach Metro Bundler!");
      }
    }] resume];
}

+ (void)disableDebugger
{
  sendEventToAllConnections(kDebuggerMsgDisable);
}

+ (ABI35_0_0RCTInspectorPackagerConnection *)connectWithBundleURL:(NSURL *)bundleURL
{
  NSURL *inspectorURL = getInspectorDeviceUrl(bundleURL);

  // Note, using a static dictionary isn't really the greatest design, but
  // the packager connection does the same thing, so it's at least consistent.
  // This is a static map that holds different inspector clients per the inspectorURL
  if (socketConnections == nil) {
    socketConnections = [NSMutableDictionary new];
  }

  NSString *key = [inspectorURL absoluteString];
  ABI35_0_0RCTInspectorPackagerConnection *connection = socketConnections[key];
  if (!connection) {
    connection = [[ABI35_0_0RCTInspectorPackagerConnection alloc] initWithURL:inspectorURL];
    socketConnections[key] = connection;
    [connection connect];
  }

  return connection;
}

@end

#endif
