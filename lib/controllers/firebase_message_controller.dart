import 'dart:convert';

import 'package:brain_dev_business/services/sender_firebase_message_service.dart';
import 'package:brain_dev_business/services/sender_notification_local_service.dart';
import 'package:brain_dev_tools/tools/check_platform.dart';
import 'package:brain_dev_tools/tools/constant.dart';
import 'package:brain_dev_tools/tools/tools_log.dart';
import 'package:brain_dev_tools/tools/validation/type_safe_conversion.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FirebaseMessageController extends GetxController implements GetxService
{
  final FirebaseMessaging firebaseMessaging;
  final SenderFirebaseMessageService senderFirebaseMessageService;
  final SenderNotificationLocalService senderNotificationLocalService;

  bool _started = false;
  //var userConnected = Get.find<BusinessController>().userConnected;

  FirebaseMessageController({
    required this.firebaseMessaging,
    required this.senderFirebaseMessageService,
    required this.senderNotificationLocalService,
  }){
    if (!_started) {
      initFirebaseMessaging();
      //updateToken();
      _started = true;
    }
  }

  init(){
    if (!_started) {
      initFirebaseMessaging();
      _started = true;
    }
  }

//region [ Firebase ]
  initFirebaseMessaging() async {
    logCat('ON initFirebaseMessaging() ');
    senderFirebaseMessageService.iOSPermission();

    /// App in foreground -> [onMessage] callback will be called
    /// App terminated -> Notification is delivered to system tray. When the user clicks on it to open app [onLaunch] fires
    /// App in background -> Notification is delivered to system tray. When the user clicks on it to open app [onResume] fires

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logCat('initFirebaseMessaging().::. onMessage: ${message.data['title']}');
      onMessage(message);
      //handleNotification( message.data, false);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logCat('initFirebaseMessaging().::. onMessageOpenedApp: $message');
      onLaunch(message);
    });

    firebaseMessaging.onTokenRefresh.listen((fcmToken) {
      logCat('initFirebaseMessaging().::. onTokenRefresh: $fcmToken');
      tokenRefresh(fcmToken);
    }).onError((err) {
      // Error getting token.
    });

    //onBackgroundMessageHandler();
  }

  //region [ FIREBASE TOKEN ]
  getFcmToken() async {
    await senderFirebaseMessageService.getFcmToken();
  }
  /// This method will be called when device token get refreshed
  void tokenRefresh(String newToken) async {
    senderFirebaseMessageService.refreshDeviceToken(fcmNewToken: newToken );
  }

  Future updateToken() async {
    senderFirebaseMessageService.iOSPermission();
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

  Future<String> getDeviceToken() async {
    String? deviceToken = '';
    senderFirebaseMessageService.iOSPermission();
    if(!GetPlatform.isWeb) {
      await firebaseMessaging.getToken().then((token) async {
        String newToken = TypeSafeConversion.nullSafeString(token);
        await senderFirebaseMessageService.addDevice(fcmNewToken: newToken );
        return token;
      }, onError: (error) {
        logCat("FCM token refresh failed with error $error");
      });
    }
    return deviceToken;
  }
  //endregion
//endregion

//region [ Firebase ]
  /// This method will be called on tap of the notification which came when app was in foreground
  ///
  /// Firebase messaging does not push notification in notification panel when app is in foreground.
  /// To send the notification when app is in foreground we will use flutter_local_notification
  /// to send notification which will behave similar to firebase notification
  Future<void> onMessage(RemoteMessage message) async {
    logCat('IN onMessage');
    senderNotificationLocalService.showNotification(message: message);//, data:true);
  }

  /// This method will be called on tap of the notification which came when app was closed
  Future<void>? onLaunch(RemoteMessage message) {
    logCat('onLaunch: $message');
    try {
      if (checkPlatform.isIOS) {
        message = modifyNotificationJson(message.data);
      }
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'onLaunch');
    }
    performActionOnNotification(message);
    return null;
  }
  void onBackgroundMessageHandler() {
    logCat('IN onBackgroundMessageHandler');
    try {
      if (GetPlatform.isMobile) {
        FirebaseMessaging.onBackgroundMessage(
            senderNotificationLocalService.myBackgroundMessageHandler);
      }
    }catch(ex, trace){
      logError(ex, trace: trace, position: 'onBackgroundMessageHandler');
    }
  }

  handleNotification( data, bool push) {
    var messageJson = json.decode(data['message']);
    logCat('decoded message: $messageJson');
    //var message = m.Message.fromJson(messageJson);
    // Provider.of<ConversationProvider>(context, listen: false).addMessageToConversation(message.conversationId, message);
  }

  /// This method will modify the message format of iOS Notification Data
  RemoteMessage modifyNotificationJson(message) {
    message['data'] = Map.from(message ?? {});
    message['notification'] = message['aps']['alert'];
    logCat(message);
    return message;
  }

  /// We want to perform same action of the click of the notification. So this common method will be called on
  /// tap of any notification (onLaunch / onMessage / onResume)
  void performActionOnNotification(message) {
    //NotificationsBloc.instance.newNotification(message);
    logCat(message);
  }
//endregion

  void onDidReceiveLocalNotificationIos(int id, String? title, String? body, String? payload) async
  {
    // display a dialog with the notification details, tap ok to go to another page
    logCat( 'NotificationController: IN onDidReceiveLocalNotification Ios' );
    logCat('NotificationController:  id: $id / $title / $body / $payload');
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title??''),
        content: Text(body??''),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();

            },
          )
        ],
      ),
    );
  }

}