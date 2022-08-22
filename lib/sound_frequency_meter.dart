// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'package:permission_handler/permission_handler.dart';

import 'sound_frequency_meter_configuration.dart';
import 'sound_frequency_meter_platform_interface.dart';

class SoundFrequencyMeter {
  final SoundFrequencyMeterConfiguration configuration;

  SoundFrequencyMeter(this.configuration);

  final _futureIsMicrophonePermissionGranted =
      Permission.microphone.request().then(
    (permissionStatus) {
      return permissionStatus.isGranted;
    },
  );

  void addFrequencyListener(void Function(double? frequency) listener) async {
    _futureIsMicrophonePermissionGranted.then(
      (isGranted) {
        if (isGranted) {
          SoundFrequencyMeterPlatform.instance.listenForFrequency(
            listener,
            config: configuration,
          );
        }
      },
    );
  }
}
