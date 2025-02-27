// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'enum_util.dart';
import 'find.dart';
import 'message.dart';

/// Offset types that can be requested by [GetOffset].
enum OffsetType {
  /// The top left point.
  topLeft,

  /// The top right point.
  topRight,

  /// The bottom left point.
  bottomLeft,

  /// The bottom right point.
  bottomRight,

  /// The center point.
  center,
}

EnumIndex<OffsetType> _offsetTypeIndex = EnumIndex<OffsetType>(OffsetType.values);

/// A Flutter Driver command that returns the [offsetType] from the RenderObject
/// identified by [finder].
///
/// The requested offset is returned in logical pixels, which can be translated
/// to device pixels via [dart:ui.FlutterView.devicePixelRatio].
class GetOffset extends CommandWithTarget {
  /// The `finder` looks for an element to get its rect.
  GetOffset(super.finder, this.offsetType, {super.timeout});

  /// Deserializes this command from the value generated by [serialize].
  GetOffset.deserialize(super.json, super.finderFactory)
    : offsetType = _offsetTypeIndex.lookupBySimpleName(json['offsetType']!),
      super.deserialize();

  @override
  Map<String, String> serialize() =>
      super.serialize()
        ..addAll(<String, String>{'offsetType': _offsetTypeIndex.toSimpleName(offsetType)});

  /// The type of the requested offset.
  final OffsetType offsetType;

  @override
  String get kind => 'get_offset';
}

/// The result of the [GetOffset] command.
///
/// The offset is provided in logical pixels, which can be translated
/// to device pixels via [dart:ui.FlutterView.devicePixelRatio].
class GetOffsetResult extends Result {
  /// Creates a result with the offset defined by [dx] and [dy].
  const GetOffsetResult({this.dx = 0.0, this.dy = 0.0});

  /// The x component of the offset in logical pixels.
  ///
  /// The value can be translated to device pixels via
  /// [dart:ui.FlutterView.devicePixelRatio].
  final double dx;

  /// The y component of the offset in logical pixels.
  ///
  /// The value can be translated to device pixels via
  /// [dart:ui.FlutterView.devicePixelRatio].
  final double dy;

  /// Deserializes the result from JSON.
  static GetOffsetResult fromJson(Map<String, dynamic> json) {
    return GetOffsetResult(dx: json['dx'] as double, dy: json['dy'] as double);
  }

  @override
  Map<String, dynamic> toJson() => <String, double>{'dx': dx, 'dy': dy};
}
