import 'dart:io';

import 'package:brain_dev_business/controllers/business_controller.dart';
import 'package:brain_dev_business/entities/dao/properties/users_property.dart';
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
  Future<String?> addDevice({required String fcmNewToken}) async {
    try {
      logCat('FCM Token: $fcmNewToken');
      apiClient.fcmToken = fcmNewToken;
      String fcmOldToken = await getFcmToken();
      String identifierForVendor = apiClient.getDeviceId();
      UserModel user = Get.find<BusinessController>().userConnected;

      String userId = user.userName;
      String apiUrl = ApiConstantDev.apiUrlSetDeviceToken;
      //region attributs
      DeviceInfoModel deviceInfo = DeviceInfoModel.fromJson(apiClient.deiceInfo.data);
      deviceInfo.userName = userId;
      deviceInfo.fcmOldToken = fcmOldToken;
      deviceInfo.fcmNewToken = fcmNewToken;
      deviceInfo.identifierForVendor = identifierForVendor;
      deviceInfo.buildName = apiClient.packageInfo?.version ?? '';
      deviceInfo.buildNumber = apiClient.packageInfo?.buildNumber ?? '';
      var param = deviceInfo.toJson();
      //endregion
      var response = await apiClient.postData(
          apiUrl: apiUrl, data: param, fName: 'addDevice');
      if (response.statusCode == HttpStatus.ok) {
        setFcmToken(fcmNewToken);
        return response.body;
      }
    } catch (ex, trace) {
      logError(ex, trace: trace, position: 'addDevice');
    }
    return null;
  }

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

  @override
  Future<String?> refreshDeviceToken({required String fcmNewToken}) async {
    try {
      logCat('FCM newToken: $fcmNewToken');
      apiClient.fcmToken = fcmNewToken;
      String fcmOldToken = await getFcmToken();
      UserModel user = Get.find<BusinessController>().userConnected;
      String userId = user.userName;
      logCat(
          'addDevice:: userId: $userId \n| FCM OLD Token: $fcmNewToken \n| FCM NEW Token: $fcmNewToken');
      String apiUrl = ApiConstantDev.apiUrlRefreshDeviceToken;
      //region attributs
      Map<String, String> param = <String, String>{};
      param[UsersProperty.userName.columnName] = userId;
      param[UsersProperty.fcmOldToken.columnName] = fcmOldToken;
      param[UsersProperty.fcmNewToken.columnName] = fcmNewToken;
      //endregion
      var response = await apiClient.postData(
          apiUrl: apiUrl, data: param, fName: 'refreshDeviceToken');
      if (response.statusCode == HttpStatus.ok) {
        setFcmToken(fcmNewToken);
        return response.body;
      }
    } catch (ex, trace) {
      logError(ex, trace: trace, position: 'refreshDeviceToken');
    }
    return null;
  }

  //endregion
}