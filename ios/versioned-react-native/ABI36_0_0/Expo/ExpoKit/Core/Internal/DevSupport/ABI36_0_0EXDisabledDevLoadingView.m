// Copyright 2015-present 650 Industries. All rights reserved.

@import UIKit;

#import "ABI36_0_0EXDisabledDevLoadingView.h"

@implementation ABI36_0_0EXDisabledDevLoadingView {
  BOOL _isObserving;
}

+ (NSString *)moduleName { return @"ABI36_0_0RCTDevLoadingView"; }

ABI36_0_0RCT_EXPORT_METHOD(hide)
{
  if (_isObserving) {
    [self sendEventWithName:@"devLoadingView:hide" body:@{}];
  }
}

ABI36_0_0RCT_EXPORT_METHOD(showMessage:(NSString *)message color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor)
{
  if (_isObserving) {
    [self sendEventWithName:@"devLoadingView:showMessage" body:@{@"message":message}];
  }
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"devLoadingView:showMessage", @"devLoadingView:hide"];
}

- (void)startObserving
{
  _isObserving = YES;
}

- (void)stopObserving
{
  _isObserving = NO;
}

@end

