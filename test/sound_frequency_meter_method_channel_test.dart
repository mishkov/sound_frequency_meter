import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_frequency_meter/sound_frequency_meter_method_channel.dart';

void main() {
  MethodChannelSoundFrequencyMeter platform = MethodChannelSoundFrequencyMeter();
  const MethodChannel channel = MethodChannel('sound_frequency_meter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
