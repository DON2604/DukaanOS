import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

InputImage? inputImageFromCameraImage({
  required CameraImage image,
  required CameraDescription camera,
}) {
  final sensorOrientation = camera.sensorOrientation;

  InputImageRotation? rotation = InputImageRotationValue.fromRawValue(
    sensorOrientation,
  );
  rotation ??= InputImageRotation.rotation0deg;

  // On Android, ML Kit fromBytes only supports NV21 / YV12.
  // On iOS, it supports BGRA8888.
  final InputImageFormat format;
  if (Platform.isAndroid) {
    format = InputImageFormat.nv21;
  } else {
    format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.bgra8888;
  }

  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  final size = Size(image.width.toDouble(), image.height.toDouble());

  final metadata = InputImageMetadata(
    size: size,
    rotation: rotation,
    format: format,
    bytesPerRow: image.planes[0].bytesPerRow,
  );

  return InputImage.fromBytes(bytes: bytes, metadata: metadata);
}
