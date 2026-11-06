import 'dart:io';

import 'package:brain_dev_business/controllers/business_controller.dart';
import 'package:brain_dev_business/models/users_model.dart';
import 'package:brain_dev_business/services/sender_firebase_message_service.dart';
import 'package:brain_dev_tools/config/api/api_client.dart';
import 'package:brain_dev_tools/config/api/api_constant.dart';
import 'package:brain_dev_tools/models/security/device_info_model.dart';
import 'package:brain_dev_tools/tools/constant.dart';
import 'package:brain_dev_tools/tools/tools_log.dart';
import 'package:brain_dev_tools/tools/validation/type_safe_conversion.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class FirebaseMessageRepository implements SenderFirebaseMessageService
{
  ApiClient apiClient;
  SharedPreferences sharedPreferences;
  FirebaseMessaging firebaseMessaging;

  FirebaseMessageRepository({
    required this.apiClient,
    required this.sharedPreferences,
    required this.firebaseMessaging
  });

  @override
  void iOSPermission() {
    //if (GetPlatform.isIOS) {
    firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    //}
  }

  //region [ FcmToken ]
  @override
  Future<String> getFcmToken() async {
    String fcmToken = sharedPreferences.getString(Constant.TOKEN) ?? "";
    logCat('getFcmToken :$fcmToken');
    if (fcmToken == "") {
      fcmToken = await firebaseMessaging.getToken() ?? '';
      logCat('get.FCM Token :$fcmToken');
      setFcmToken(fcmToken);
    }
    return fcmToken;
  }
  @override
  setFcmToken(String fcmToken) async {
    logCat('set FcmToken: $fcmToken');
    sharedPreferences.setString(Constant.TOKEN, fcmToken);
  }
  //endregion

  //region [ Device Token ]
  @override
  Future<String?> addDevice({required String fcmNewToken}) => _registerDevice(fcmNewToken, fName: 'addDevice');

  @override
  Future<String?> refreshDeviceToken({required String fcmNewToken}) => _registerDevice(fcmNewToken, fName: 'refreshDeviceToken');

  /// Enregistre le jeton FCM de l'appareil dans LyricStream (`PUT api/notifications/devices`). L'utilisateur est celui du
  /// jeton d'accès : aucun nom d'utilisateur n'est envoyé. Un appareil sans utilisateur connecté garde son jeton en
  /// local ; il est enregistré à la prochaine connexion (voir `updateToken`).
  Future<String?> _registerDevice(String fcmNewToken, {required String fName}) async {
    try {
      logCat('FCM Token: $fcmNewToken');
      apiClient.fcmToken = fcmNewToken;
      final String fcmOldToken = sharedPreferences.getString(Constant.TOKEN) ?? '';
      UserModel user = Get.find<BusinessController>().userConnected;
      if (!user.connecterYN || ApiConstantDev.urlMiddleware.isEmpty) {
        setFcmToken(fcmNewToken);
        return null;
      }

      DeviceInfoModel deviceInfo = DeviceInfoModel.fromJson(apiClient.deiceInfo.data);
      final body = <String, dynamic>{
        'token': fcmNewToken,
        if (fcmOldToken.isNotEmpty && fcmOldToken != fcmNewToken) 'previousToken': fcmOldToken,
        'platform': GetPlatform.isIOS ? 'ios' : 'android',
        if (deviceInfo.model.isNotEmpty) 'model': deviceInfo.model,
        if ((apiClient.packageInfo?.packageName ?? '').isNotEmpty) 'appPackage': apiClient.packageInfo!.packageName,
      };
      var response = await apiClient.putData(apiUrl: ApiConstantDev.urlMiddlewareDevices, data: body, fName: fName);
      if (response.statusCode == HttpStatus.ok) {
        setFcmToken(fcmNewToken);
        return response.body;
      }
    } catch (ex, trace) {
      logError(ex, trace: trace, position: fName);
    }
    return null;
  }

  //endregion

  @override
  Future updateToken() async {
    iOSPermission();
    await getDeviceToken();
    if (GetPlatform.isIOS) {
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true, announcement: false, badge: true, carPlay: false,
        criticalAlert: false, provisional: false, sound: true,
      );
      if(settings.authorizationStatus == AuthorizationStatus.authorized) {
        firebaseMessaging.subscribeToTopic(Constant.ALL);
        firebaseMessaging.subscribeToTopic(Constant.USERS);
      }
    }else {
      if(!GetPlatform.isWeb) {
        firebaseMessaging.subscribeToTopic(Constant.ALL);
        firebaseMessaging.subscribeToTopic(Constant.USERS);
      }
    }
  }

  @override
  Future<String> getDeviceToken() async {
    String? deviceToken = '';
    iOSPermission();
    if(!GetPlatform.isWeb) {
      await firebaseMessaging.getToken().then((token) async {
        String newToken = TypeSafeConversion.nullSafeString(token);
        await addDevice(fcmNewToken: newToken );
        return token;
      }, onError: (error) {
        logCat("FCM token refresh failed with error $error");
      });
    }
    return deviceToken;
  }

  //endregion
}