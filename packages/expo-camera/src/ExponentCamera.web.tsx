import React, { forwardRef } from 'react';
import { createElement, findNodeHandle, StyleSheet, View } from 'react-native';

import { CapturedPicture, MountError, NativeProps, PictureOptions } from './Camera.types';
import CameraModule, { CameraType } from './CameraModule/CameraModule';
import CameraManager from './ExponentCameraManager.web';

export default class ExponentCamera extends React.Component<NativeProps> {
  video?: number | null;
  camera?: CameraModule;
  state = { type: null };

  componentWillUnmount() {
    if (this.camera) {
      this.camera.stopAsync();
    }
  }

  componentWillReceiveProps(nextProps) {
    this.updateCameraProps(nextProps);
  }

  _updateCameraProps = async ({ type, pictureSize, ...webCameraSettings }: NativeProps) => {
    const { camera } = this;
    if (!camera) {
      return;
    }

    await camera.setTypeAsync(type as CameraType);

    await camera.updateWebCameraSettingsAsync(webCameraSettings);

    // await camera.setPictureSize(pictureSize as string);

    await camera.ensureCameraIsRunningAsync();

    const actualCameraType = camera.getActualCameraType();
    if (actualCameraType !== this.state.type) {
      this.setState({ type: actualCameraType });
    }
    this.updateScanner();
  };

  getCamera = (): CameraModule => {
    if (this.camera) {
      return this.camera;
    }
    throw new Error('Camera is not defined yet!');
  };

  getAvailablePictureSizes = async (ratio: string): Promise<string[]> => {
    const camera = this.getCamera();
    return camera.getAvailablePictureSizes(ratio);
  };

  takePicture = async (options: PictureOptions): Promise<CapturedPicture> => {
    const camera = this.getCamera();
    return camera.takePicture({
      ...options,
      // This will always be defined, the option gets added to a queue in the upper-level. We should replace the original so it isn't called twice.
      onPictureSaved: this.props.onPictureSaved,
    });
  };

  getAvailableCameraTypesAsync = async (): Promise<string[]> => {
    const camera = this.getCamera();
    return await camera.getAvailableCameraTypesAsync();
  };

  resumePreview = async (): Promise<void> => {
    const camera = this.getCamera();
    await camera.resumePreview();
  };

  pausePreview = async (): Promise<void> => {
    const camera = this.getCamera();
    await camera.stopAsync();
  };

  onCameraReady = () => {
    if (this.props.onCameraReady) {
      this.props.onCameraReady();
    }
  };

  onMountError = ({ nativeEvent }: { nativeEvent: MountError }) => {
    if (this.props.onMountError) {
      this.props.onMountError({ nativeEvent });
    }
  };

  private setRef = async ref => {
    if (!ref) {
      this.video = null;
      if (this.camera) {
        this.camera.stopAsync();
        this.camera = undefined;
      }
      return;
    }
    this.video = findNodeHandle(ref);

    (this.video as any).webkitPlaysinline = true;

    this.camera = new CameraModule(ref);
    this.camera.onCameraReady = this.onCameraReady;
    this.camera.onMountError = this.onMountError;
    this.updateCameraCanvas();
    this.updateCameraProps(this.props);
  };

  private updateScanner = () => {
    if (!this.camera) return;
    const { barCodeScannerSettings, onBarCodeScanned } = this.props;
    if (onBarCodeScanned && barCodeScannerSettings) {
      this.camera.startScanner(
        {
          // Default barcode scanning update interval, same as is defined in the API layer.
          // TODO: Bacon: Make this larger for low-end devices.
          interval: this.shouldRenderIndicator() ? -1 : 500,
          ...barCodeScannerSettings,
        },
        nativeEvent => {
          if (this.props.onBarCodeScanned) {
            this.props.onBarCodeScanned({ nativeEvent });
            return;
          }
          this.updateScanner();
        }
      );
    }
  };

  canvas?: HTMLCanvasElement;

  private setCanvasRef = ref => {
    this.canvas = ref;
    this.updateCameraCanvas();
  };

  private updateCameraCanvas() {
    if (this.camera) {
      this.camera.canvas = this.canvas;
    }
  }

  private shouldRenderIndicator = (): boolean => {
    if (this.props.barCodeScannerSettings) {
      return this.props.barCodeScannerSettings.shouldRenderIndicator || false;
    }
    return false;
  };

  render() {
    const { pointerEvents } = this.props;

    // TODO: Bacon: Create a universal prop, on native the microphone is only used when recording videos.
    // Because we don't support recording video in the browser we don't need the user to give microphone permissions.
    const isMuted = true;

    const isFrontFacingCamera = this.state.type === CameraManager.Type.front;
    const style = {
      // Flip the camera
      transform: isFrontFacingCamera ? [{ scaleX: -1 }] : undefined,
    };

    return (
      <View pointerEvents="box-none" style={[styles.videoWrapper, this.props.style]}>
        <Video
          autoPlay
          playsInline
          muted={isMuted}
          pointerEvents={pointerEvents}
          ref={this._setRef}
          style={[StyleSheet.absoluteFill, styles.video, style]}
        />
        {this.shouldRenderIndicator() && <canvas ref={this.setCanvasRef} style={canvasStyle} />}
        {this.props.children}
      </View>
    );
  }
}

const canvasStyle = {
  position: 'absolute',
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
  width: '100%',
  height: '100%',
};

const Video: any = forwardRef((props, ref) => createElement('video', { ...props, ref }));

const styles = StyleSheet.create({
  videoWrapper: {
    flex: 1,
    alignItems: 'stretch',
  },
  video: {
    width: '100%',
    height: '100%',
    objectFit: 'cover',
  },
});
