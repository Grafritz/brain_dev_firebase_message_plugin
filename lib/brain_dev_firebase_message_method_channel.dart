import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'brain_dev_firebase_message_platform_interface.dart';

/// An implementation of [BrainDevFirebaseMessagePlatform] that uses method channels.
class MethodChannelBrainDevFirebaseMessage extends BrainDevFirebaseMessagePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('brain_dev_firebase_message');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
