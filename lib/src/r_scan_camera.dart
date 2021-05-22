// Copyright 2019 The rhyme_lph Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:r_scan/r_scan.dart';

const String _scanType = 'com.rhyme_lph/r_scan_camera';
const MethodChannel _channel = MethodChannel('$_scanType/method');

Future<List<RScanCameraDescription>> availableRScanCameras() async {
  try {
    final List<Map<dynamic, dynamic>> cameras =
        (await _channel.invokeListMethod<Map<dynamic, dynamic>>(
      'availableCameras',
    ))!;
    return cameras.map((Map<dynamic, dynamic> camera) {
      return RScanCameraDescription(
        name: camera['name'] as String,
        lensDirection:
            _parseCameraLensDirection(camera['lensFacing'] as String),
      );
    }).toList();
  } on PlatformException catch (e) {
    throw RScanCameraException(e.code, e.message);
  }
}

class RScanCameraController extends ValueNotifier<RScanCameraValue> {
  RScanCameraController(
    this.description,
    this.resolutionPreset,
  ) : super(const RScanCameraValue.uninitialized());

  final RScanCameraDescription description;
  final RScanCameraResolutionPreset resolutionPreset;

  /// Qr code result.
  RScanResult? result;

  /// Init finish will return id.
  int? _textureId;

  /// When the widget dispose will set true.
  bool _isDisposed = false;

  /// When the camera create finish
  late Completer<void> _creatingCompleter;

  /// The result subscription
  StreamSubscription<Map<String, dynamic>>? _resultSubscription;

  Future<void> initialize() async {
    if (_isDisposed) {
      return;
    }

    _creatingCompleter = Completer<void>();

    try {
      final Map<String, dynamic> reply =
          (await _channel.invokeMapMethod<String, dynamic>(
        'initialize',
        <String, dynamic>{
          'cameraName': description.name,
          'resolutionPreset': _serializeResolutionPreset(resolutionPreset),
        },
      ))!;
      _textureId = reply['textureId'] as int;
      value = value.copyWith(
        isInitialized: true,
        previewSize: Size(
          (reply['previewWidth'] as num).toDouble(),
          (reply['previewHeight'] as num).toDouble(),
        ),
      );
      _resultSubscription = EventChannel('${_scanType}_$_textureId/event')
          .receiveBroadcastStream()
          .cast<Map<String, dynamic>>()
          .listen(_handleResult);
    } on PlatformException catch (e) {
      // 当发生权限问题的异常时会抛出
      throw RScanCameraException(e.code, e.message);
    }
    _creatingCompleter.complete();
    return _creatingCompleter.future;
  }

  /// 处理返回值
  void _handleResult(Map<String, dynamic> event) {
    if (_isDisposed) {
      return;
    }
    result = RScanResult.formMap(event);
    notifyListeners();
  }

  /// 开始扫描
  Future<void> startScan() => _channel.invokeMethod('startScan');

  /// 停止扫描
  Future<void> stopScan() => _channel.invokeMethod<void>('stopScan');

  /// flash mode open or close.
  ///
  /// [isOpen] if false will close flash mode.
  ///
  /// It will return is success.
  Future<bool?> setFlashMode(bool isOpen) => _channel.invokeMethod(
        'setFlashMode',
        <String, dynamic>{'isOpen': isOpen},
      );

  /// flash mode open or close.
  ///
  /// [isOpen] if false will close flash mode.
  ///
  /// It will return is success.
  Future<bool?> getFlashMode() => _channel.invokeMethod('getFlashMode');

  /// flash auto open when brightness value less then 600.
  ///
  /// [isAuto] auto
  Future<bool?> setAutoFlashMode(bool isAuto) => _channel.invokeMethod(
        'setAutoFlashMode',
        <String, dynamic>{'isAuto': isAuto},
      );

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    super.dispose();
    await _creatingCompleter.future;
    await _channel.invokeMethod<dynamic>('dispose', <String, dynamic>{
      'textureId': _textureId,
    });
    await _resultSubscription?.cancel();
  }
}

/// camera value info
class RScanCameraValue {
  const RScanCameraValue({
    required this.isInitialized,
    this.errorDescription,
    this.previewSize,
  });

  const RScanCameraValue.uninitialized() : this(isInitialized: false);

  /// True after [RScanCameraController.initialize] has completed successfully.
  final bool isInitialized;

  /// Description of an error state.
  ///
  /// This is null while the controller is not in an error state.
  /// When [hasError] is true this contains the error description.
  final String? errorDescription;

  /// The size of the preview in pixels.
  ///
  /// Is `null` until [isInitialized] is `true`.
  final Size? previewSize;

  /// Convenience getter for `previewSize.width / previewSize.height`.
  ///
  /// Can only be called when [initialize] is done.
  double get aspectRatio => previewSize!.width / previewSize!.height;

  bool get hasError => errorDescription != null;

  RScanCameraValue copyWith({
    bool? isInitialized,
    String? errorDescription,
    Size? previewSize,
  }) {
    return RScanCameraValue(
      isInitialized: isInitialized ?? this.isInitialized,
      errorDescription: errorDescription ?? this.errorDescription,
      previewSize: previewSize ?? this.previewSize,
    );
  }

  @override
  String toString() {
    return '$runtimeType ('
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription, '
        'previewSize: $previewSize'
        ')';
  }
}

class RScanCamera extends StatelessWidget {
  const RScanCamera(
    this.controller, {
    Key? key,
  }) : super(key: key);

  final RScanCameraController controller;

  @override
  Widget build(BuildContext context) {
    return controller.value.isInitialized
        ? Texture(textureId: controller._textureId!)
        : const SizedBox.shrink();
  }
}

/// Camera description
@immutable
class RScanCameraDescription {
  const RScanCameraDescription({
    required this.name,
    required this.lensDirection,
  });

  final String name;
  final RScanCameraLensDirection lensDirection;

  @override
  bool operator ==(Object other) {
    return other is RScanCameraDescription &&
        other.name == name &&
        other.lensDirection == lensDirection;
  }

  @override
  int get hashCode => hashValues(name, lensDirection);

  @override
  String toString() => '$runtimeType($name, $lensDirection)';
}

/// Camera lens direction
enum RScanCameraLensDirection { front, back, external }

RScanCameraLensDirection _parseCameraLensDirection(String string) {
  switch (string) {
    case 'front':
      return RScanCameraLensDirection.front;
    case 'back':
      return RScanCameraLensDirection.back;
    case 'external':
      return RScanCameraLensDirection.external;
  }
  throw ArgumentError('Unknown CameraLensDirection value');
}

/// Affect the quality of video recording and image capture:
///
/// If a preset is not available on the camera being used a preset of lower quality will be selected automatically.
enum RScanCameraResolutionPreset {
  /// 352x288 on iOS, 240p (320x240) on Android
  low,

  /// 480p (640x480 on iOS, 720x480 on Android)
  medium,

  /// 720p (1280x720)
  high,

  /// 1080p (1920x1080)
  veryHigh,

  /// 2160p (3840x2160)
  ultraHigh,

  /// The highest resolution available.
  max,
}

/// Returns the resolution preset as a String.
String _serializeResolutionPreset(
  RScanCameraResolutionPreset resolutionPreset,
) {
  switch (resolutionPreset) {
    case RScanCameraResolutionPreset.max:
      return 'max';
    case RScanCameraResolutionPreset.ultraHigh:
      return 'ultraHigh';
    case RScanCameraResolutionPreset.veryHigh:
      return 'veryHigh';
    case RScanCameraResolutionPreset.high:
      return 'high';
    case RScanCameraResolutionPreset.medium:
      return 'medium';
    case RScanCameraResolutionPreset.low:
      return 'low';
  }
}

/// Exception
@immutable
class RScanCameraException implements Exception {
  const RScanCameraException(this.code, this.description);

  final String code;
  final String? description;

  @override
  String toString() => '$runtimeType ($code, $description)';
}
