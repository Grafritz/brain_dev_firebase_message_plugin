import 'package:flutter_test/flutter_test.dart';
import 'package:brain_dev_firebase_message/brain_dev_firebase_message.dart';
import 'package:brain_dev_firebase_message/brain_dev_firebase_message_platform_interface.dart';
import 'package:brain_dev_firebase_message/brain_dev_firebase_message_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBrainDevFirebaseMessagePlatform
    with MockPlatformInterfaceMixin
    implements BrainDevFirebaseMessagePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BrainDevFirebaseMessagePlatform initialPlatform = BrainDevFirebaseMessagePlatform.instance;

  test('$MethodChannelBrainDevFirebaseMessage is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBrainDevFirebaseMessage>());
  });

  test('getPlatformVersion', () async {
    BrainDevFirebaseMessage brainDevFirebaseMessagePlugin = BrainDevFirebaseMessage();
    MockBrainDevFirebaseMessagePlatform fakePlatform = MockBrainDevFirebaseMessagePlatform();
    BrainDevFirebaseMessagePlatform.instance = fakePlatform;

    expect(await brainDevFirebaseMessagePlugin.getPlatformVersion(), '42');
  });
}
