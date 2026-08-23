import 'package:camera/camera.dart';

String cameraErrorMessage(CameraException error) {
  switch (error.code) {
    case 'CameraAccessDenied':
    case 'cameraPermission':
      return 'Camera permission denied. Please allow access in settings.';
    case 'CameraAccessDeniedWithoutPrompt':
      return 'Camera access denied without prompt. Open app settings.';
    case 'CameraAccessRestricted':
      return 'Camera access is restricted on this device.';
    default:
      return 'Camera error: ${error.description ?? error.code}';
  }
}
