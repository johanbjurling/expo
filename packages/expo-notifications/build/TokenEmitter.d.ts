import { Subscription } from '@unimodules/core';
import { DevicePushToken } from './getDevicePushTokenAsync';
export declare type PushTokenListener = (token: DevicePushToken) => void;
export declare function addPushTokenListener(listener: PushTokenListener): Subscription;
export declare function removePushTokenSubscription(subscription: Subscription): void;
export declare function removeAllPushTokenListeners(): void;
