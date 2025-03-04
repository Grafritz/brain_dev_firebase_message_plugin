import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'brain_dev_firebase_message_method_channel.dart';

abstract class BrainDevFirebaseMessagePlatform extends PlatformInterface {
  /// Constructs a BrainDevFirebaseMessagePlatform.
  BrainDevFirebaseMessagePlatform() : super(token: _token);

  static final Object _token = Object();

  static BrainDevFirebaseMessagePlatform _instance = MethodChannelBrainDevFirebaseMessage();

  /// The default instance of [BrainDevFirebaseMessagePlatform] to use.
  ///
  /// Defaults to [MethodChannelBrainDevFirebaseMessage].
  static BrainDevFirebaseMessagePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BrainDevFirebaseMessagePlatform] when
  /// they register themselves.
  static set instance(BrainDevFirebaseMessagePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
