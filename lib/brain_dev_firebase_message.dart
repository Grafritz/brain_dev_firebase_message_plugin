
import 'brain_dev_firebase_message_platform_interface.dart';
import 'package:brain_dev_firebase_message/config/dependencies_tools.dart';
import 'package:brain_dev_firebase_message/controllers/firebase_message_controller.dart';
import 'package:brain_dev_tools/config/app_config.dart';
import 'package:brain_dev_tools/tools/tools_log.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

/// init BrainDev FirebaseMessage
initBrainDevFirebaseMessage({ bool initializeApp= true }) async
{
  if( initializeApp ) {
    try {
      FirebaseOptions? firebaseOptions = EnvironmentVariable.firebaseOptions;
      await Firebase.initializeApp(options: firebaseOptions);
      //await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (ex, trace) {
      logError(
          ex, trace: trace, position: 'FirebaseMessage::initConfiguration:001');
    }
  }

  try {
    initFirebaseMessagingDependencies();
    await Get.find<FirebaseMessageController>().init();
  } catch (ex, trace) {
    logError(ex, trace: trace, position: ':initFirebaseMessagingDependencies');
  }

  try {
    Get.find<FirebaseMessageController>().onBackgroundMessageHandler();
  } catch (ex, trace) {
    logError(ex, trace: trace, position: ':initBrainDevFirebaseMessage');
  }
}
class BrainDevFirebaseMessage {
  Future<String?> getPlatformVersion() {
    return BrainDevFirebaseMessagePlatform.instance.getPlatformVersion();
  }
}
