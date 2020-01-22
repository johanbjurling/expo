//  Copyright (c) Facebook, Inc. and its affiliates.
//
// This source code is licensed under the MIT license found in the
 // LICENSE file in the root directory of this source tree.

#pragma once

#include <folly/dynamic.h>
#include <ABI33_0_0jsi/ABI33_0_0jsi.h>

namespace ABI33_0_0facebook {
namespace jsi {

ABI33_0_0facebook::jsi::Value valueFromDynamic(
  ABI33_0_0facebook::jsi::Runtime& runtime, const folly::dynamic& dyn);

folly::dynamic dynamicFromValue(ABI33_0_0facebook::jsi::Runtime& runtime,
                                const ABI33_0_0facebook::jsi::Value& value);

}
}
