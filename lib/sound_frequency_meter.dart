
import 'sound_frequency_meter_platform_interface.dart';

class SoundFrequencyMeter {
  Future<String?> getPlatformVersion() {
    return SoundFrequencyMeterPlatform.instance.getPlatformVersion();
  }
}
