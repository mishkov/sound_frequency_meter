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

enum Encoding { pcm8Bit, pcm16Bit }

extension on Encoding {
  int toInt() {
    if (this == Encoding.pcm8Bit) {
      return 8;
    } else if (this == Encoding.pcm16Bit) {
      return 16;
    } else {
      throw UnsopportedEncodingRateException(
        'Given value: $this. Supported values: ${Encoding.pcm8Bit}, ${Encoding.pcm16Bit}',
      );
    }
  }
}

class SoundFrequencyMeterConfiguration {
  final SampleRate sampleRate;
  final Encoding encoding;

  const SoundFrequencyMeterConfiguration({
    this.sampleRate = SampleRate.k16000,
    this.encoding = Encoding.pcm8Bit,
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleRate': sampleRate.toInt(),
      'encoding': encoding.toInt(),
    };
  }
}

class UnsopportedSampleRateException implements Exception {
  final String message;

  UnsopportedSampleRateException(this.message);
}

class UnsopportedEncodingRateException implements Exception {
  final String message;

  UnsopportedEncodingRateException(this.message);
}
