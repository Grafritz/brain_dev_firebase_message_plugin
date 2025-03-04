import 'package:brain_dev_business/services/sender_firebase_message_service.dart';
import 'package:brain_dev_firebase_message/controllers/firebase_message_controller.dart';
import 'package:brain_dev_firebase_message/repository/firebase_message_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

/*Future<Map<String, Map<String, String>>>*/
initFirebaseMessagingDependencies() async
{
  //TODO: Very important to implement the dependencies  [ brain_dev_tools ] before
  //TODO: Very important to implement the dependencies  [ brain_dev_business ] before
  //TODO: Very important to implement the dependencies  [ brain_dev_notification ] before

  //region [ Firebase Messaging ]
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  Get.lazyPut(() => firebaseMessaging);
  //endregion

  //region [ Repository ]
  // Si tu utilises toujours FirebaseMessageRepository via son interface, supprime cette partie.
  //Get.lazyPut(() => FirebaseMessageRepository(apiClient: Get.find(), sharedPreferences: Get.find(), firebaseMessaging: Get.find()), fenix: true);
  Get.lazyPut<SenderFirebaseMessageService>(() => FirebaseMessageRepository(
    apiClient: Get.find(),
    sharedPreferences: Get.find(),
    firebaseMessaging: Get.find(),
  ), fenix: true);
  //endregion

  //region [ Controller ]
  Get.lazyPut(() => FirebaseMessageController(
    senderFirebaseMessageService: Get.find(),
    firebaseMessaging: Get.find(),
    senderNotificationLocalService: Get.find(),
  ), fenix: true);
  //endregion
}
