import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sound_frequency_meter/sound_frequency_meter_configuration.dart';

import 'sound_frequency_meter_platform_interface.dart';

/// An implementation of [SoundFrequencyMeterPlatform] that uses method
/// channels.
class MethodChannelSoundFrequencyMeter extends SoundFrequencyMeterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sound_frequency_meter');

  @visibleForTesting
  final frequencyChannel = const EventChannel('frequency_stream');

  @override
  void listenForFrequency(
    void Function(Float64List? data) listener, {
    SoundFrequencyMeterConfiguration config =
        const SoundFrequencyMeterConfiguration(),
  }) {
    void safeListener(event) {
      if (event is Float64List?) {
        listener(event);
      }
    }

    frequencyChannel
        .receiveBroadcastStream(config.toMap())
        .listen(safeListener);
  }
}
