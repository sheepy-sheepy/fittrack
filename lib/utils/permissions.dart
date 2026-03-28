import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
  
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  static Future<bool> requestPhotosPermission() async {
    if (await Permission.photos.isGranted) {
      return true;
    }
    final status = await Permission.photos.request();
    return status.isGranted;
  }
  
  static Future<bool> checkPermissions() async {
    final storage = await Permission.storage.status;
    final photos = await Permission.photos.status;
    
    if (!storage.isGranted || !photos.isGranted) {
      return false;
    }
    return true;
  }
}