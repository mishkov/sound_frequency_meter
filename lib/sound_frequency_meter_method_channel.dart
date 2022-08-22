import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sound_frequency_meter_platform_interface.dart';

/// An implementation of [SoundFrequencyMeterPlatform] that uses method channels.
class MethodChannelSoundFrequencyMeter extends SoundFrequencyMeterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sound_frequency_meter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
