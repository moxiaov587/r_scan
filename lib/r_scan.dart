// Copyright 2019 The rhyme_lph Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
export 'package:r_scan/src/r_scan_camera.dart';

/// Qr code scan
class RScan {
  static const MethodChannel _channel = MethodChannel('com.rhyme_lph/r_scan');

  /// Scan qr image in path
  ///
  /// [path] your qr image path
  ///
  /// It will return your scan result.
  /// If not found qr, will return null.
  static Future<RScanResult?> scanImagePath(String path) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      'scanImagePath',
      <String, dynamic>{'path': path},
    );
    if (result != null) {
      return RScanResult.formMap(result);
    } else {
      return null;
    }
  }

  /// scan qr image in url
  ///
  /// [url] your qr image url
  ///
  /// It will return your scan result.
  /// If not found qr, will return null.
  static Future<RScanResult?> scanImageUrl(String url) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      'scanImageUrl',
      <String, dynamic>{'url': url},
    );
    if (result != null) {
      return RScanResult.formMap(result);
    } else {
      return null;
    }
  }

  /// scan qr image in memory
  ///
  /// [uint8list] your qr image memory
  ///
  /// It will return your scan result.
  /// If not found qr, will return null.
  static Future<RScanResult?> scanImageMemory(Uint8List uint8list) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      'scanImageMemory',
      <String, dynamic>{'uint8list': uint8list},
    );
    if (result != null) {
      return RScanResult.formMap(result);
    } else {
      return null;
    }
  }
}

/// Barcode point
@immutable
class RScanPoint {
  const RScanPoint(this.x, this.y);

  /// barcode point x
  final double x;

  /// barcode point y
  final double y;

  @override
  String toString() => 'RScanPoint {x: $x, y: $y}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RScanPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// scan result
@immutable
class RScanResult {
  const RScanResult({this.type, this.message, this.points});

  factory RScanResult.formMap(Map<dynamic, dynamic> map) {
    return RScanResult(
      type:
          map['type'] != null ? RScanBarType.values[map['type'] as int] : null,
      message: map['message'] as String,
      points: map['points'] != null
          ? (map['points'] as List<dynamic>)
              .map(
                (dynamic data) => RScanPoint(
                  data['X'] as double,
                  data['Y'] as double,
                ),
              )
              .toList()
          : null,
    );
  }

  /// barcode type
  final RScanBarType? type;

  ///barcode message
  final String? message;

  ///barcode points
  final List<RScanPoint>? points;

  @override
  String toString() {
    return 'RScanResult {type: $type, message: $message, points: $points}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RScanResult &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          points == other.points;

  @override
  int get hashCode => type.hashCode ^ message.hashCode ^ points.hashCode;
}

/// barcode type
enum RScanBarType {
  azetc,
  codabar, // ios not found
  code_39,
  code_93,
  code_128,
  data_matrix,
  ean_8,
  ean_13, // ios include upc_a
  itf,
  maxicode, // ios not found
  pdf_417,
  qr_code,
  rss_14, // ios not found
  rss_expanded, // ios not found
  upc_a, // ios not found
  upc_e,
  upc_ean_extension, // ios not found
}
