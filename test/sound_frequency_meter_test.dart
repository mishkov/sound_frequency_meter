import 'package:flutter_test/flutter_test.dart';
import 'package:sound_frequency_meter/sound_frequency_meter.dart';
import 'package:sound_frequency_meter/sound_frequency_meter_platform_interface.dart';
import 'package:sound_frequency_meter/sound_frequency_meter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSoundFrequencyMeterPlatform 
    with MockPlatformInterfaceMixin
    implements SoundFrequencyMeterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SoundFrequencyMeterPlatform initialPlatform = SoundFrequencyMeterPlatform.instance;

  test('$MethodChannelSoundFrequencyMeter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSoundFrequencyMeter>());
  });

  test('getPlatformVersion', () async {
    SoundFrequencyMeter soundFrequencyMeterPlugin = SoundFrequencyMeter();
    MockSoundFrequencyMeterPlatform fakePlatform = MockSoundFrequencyMeterPlatform();
    SoundFrequencyMeterPlatform.instance = fakePlatform;
  
    expect(await soundFrequencyMeterPlugin.getPlatformVersion(), '42');
  });
}
