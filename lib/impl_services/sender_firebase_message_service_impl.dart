import 'package:brain_dev_business/services/sender_firebase_message_service.dart';

class SenderFirebaseMessageServiceImpl implements SenderFirebaseMessageService
{
  @override
  Future<String?> addDevice({required String fcmNewToken}) {
    // TODO: implement addDevice
    throw UnimplementedError();
  }

  @override
  Future<String> getDeviceToken() {
    // TODO: implement getDeviceToken
    throw UnimplementedError();
  }

  @override
  Future<String> getFcmToken() {
    // TODO: implement getFcmToken
    throw UnimplementedError();
  }

  @override
  void iOSPermission() {
    // TODO: implement iOSPermission
  }

  @override
  Future<String?> refreshDeviceToken({required String fcmNewToken}) {
    // TODO: implement refreshDeviceToken
    throw UnimplementedError();
  }

  @override
  setFcmToken(String fcmToken) {
    // TODO: implement setFcmToken
    throw UnimplementedError();
  }

  @override
  Future updateToken() {
    // TODO: implement updateToken
    throw UnimplementedError();
  }

}