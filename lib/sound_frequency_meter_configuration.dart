class SoundFrequencyMeterConfiguration {
  /// Default to native device sample rate.
  final int? sampleRate;
  final int readsNumber;

  const SoundFrequencyMeterConfiguration({
    this.sampleRate,
    this.readsNumber = 4096
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleRate': sampleRate,
      'readsNumber': readsNumber
    };
  }
}