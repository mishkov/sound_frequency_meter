import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';

class SoundFrequencyMeter {
  SoundFrequencyMeter();

  final _futureIsMicrophonePermissionGranted =
      Permission.microphone.request().then(
    (permissionStatus) {
      return permissionStatus.isGranted;
    },
  );

  void addFrequencyListener(void Function(Float64List? data) listener) async {
    _futureIsMicrophonePermissionGranted.then(
      (isGranted) {
        if (isGranted) {}
      },
    );
  }
}
