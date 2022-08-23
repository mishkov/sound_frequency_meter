enum SampleRate { k16000, k32000 }

extension on SampleRate {
  int toInt() {
    if (this == SampleRate.k16000) {
      return 16000;
    } else if (this == SampleRate.k32000) {
      return 32000;
    } else {
      throw UnsopportedSampleRateException(
        'Given value: $this. Supported values: ${SampleRate.k16000}, ${SampleRate.k32000}',
      );
    }
  }
}

class SoundFrequencyMeterConfiguration {
  final SampleRate sampleRate;

  const SoundFrequencyMeterConfiguration({
    this.sampleRate = SampleRate.k16000,
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleRate': sampleRate.toInt(),
    };
  }
}

class UnsopportedSampleRateException implements Exception {
  final String message;

  UnsopportedSampleRateException(this.message);
}
