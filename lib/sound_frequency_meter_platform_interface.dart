import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sound_frequency_meter_method_channel.dart';

abstract class SoundFrequencyMeterPlatform extends PlatformInterface {
  /// Constructs a SoundFrequencyMeterPlatform.
  SoundFrequencyMeterPlatform() : super(token: _token);

  static final Object _token = Object();

  static SoundFrequencyMeterPlatform _instance = MethodChannelSoundFrequencyMeter();

  /// The default instance of [SoundFrequencyMeterPlatform] to use.
  ///
  /// Defaults to [MethodChannelSoundFrequencyMeter].
  static SoundFrequencyMeterPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SoundFrequencyMeterPlatform] when
  /// they register themselves.
  static set instance(SoundFrequencyMeterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}