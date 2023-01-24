import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:async/async.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:sound_frequency_meter/range_equal.dart';

class SoundFrequencyMeter {
  /// Sample rate uses to initialize mic stream and calculate
  final int sampleRate;

  /// How many frequancies will be stored to calculate average value
  final int frequenciesBufferSize;

  /// How many samples will be taken to calculate every lag
  final int windowSize;

  final _frequencyStreamController = StreamController<double>.broadcast();

  /// Provides frequency in Hz
  Stream<double> get frequencyStream => _frequencyStreamController.stream;

  Stream<List<int>>? _microphoneStream;
  StreamSubscription<List<int>>? _microphoneListener;
  Future<void>? _initMicrophoneFuture;

  bool _isAudioProcessing = false;

  List<double> _nsdfFrequencies = [];
  List<double> _autocorrelationFrequencies = [];

  SendPort? _sendPort;
  StreamQueue? _frequenciesFromIsolate;

  SoundFrequencyMeter({
    this.sampleRate = 44100,
    this.frequenciesBufferSize = 100,
    this.windowSize = 1150,
  }) {
    _nsdfFrequencies = List.generate(frequenciesBufferSize, (index) {
      return 0.0;
    });
    _autocorrelationFrequencies = List.generate(frequenciesBufferSize, (index) {
      return 0.0;
    });

    _initMicrophoneFuture = _initMicrophoneStream();

    _initIsolate();
  }

  Future<void> _initMicrophoneStream() async {
    _microphoneStream = await MicStream.microphone(
      sampleRate: sampleRate,
      audioFormat: AudioFormat.ENCODING_PCM_8BIT,
    );

    _microphoneListener = _microphoneStream!.listen(_processAudio);
  }

  Future<void> _initIsolate() async {
    final p = ReceivePort();
    await Isolate.spawn(_processAudioConcurrently, p.sendPort);

    _frequenciesFromIsolate = StreamQueue<dynamic>(p);

    _sendPort = await _frequenciesFromIsolate!.next;
  }

  void dispose() {
    _sendPort?.send(null);
    _frequenciesFromIsolate?.cancel();

    _initMicrophoneFuture?.whenComplete(() {
      _microphoneListener?.cancel();
    });
    _microphoneListener?.cancel();
  }

  void _processAudioConcurrently(SendPort sendPort) async {
    final commandPort = ReceivePort();
    sendPort.send(commandPort.sendPort);

    await for (final message in commandPort) {
      if (message is List<int>) {
        final frequency = _calculateFrequency(message, sampleRate);

        sendPort.send(frequency);
      } else if (message == null) {
        break;
      }
    }

    Isolate.exit();
  }

  double _calculateFrequency(List<int> samples, int sampleRate) {
    List<double> autocorrelation = [];
    List<double> normalizedSquareDifference = [];
    List<double> audioSamples = [];

    for (int i = 0; i < samples.length; i++) {
      autocorrelation.add(0.0);
      normalizedSquareDifference.add(0.0);

      audioSamples.add(samples[i].toDouble() - 128.0);
    }

    double highestNsdPeak = -1;
    double? maxAutocorrelation;
    int? maxAutocorrelationLocation;
    int? highestNsdPeakLocation;

    bool isFirstZeroCrossed = false;

    for (int lag = 0; lag < audioSamples.length; lag++) {
      double mDash = 0;

      bool canContinueFor(int i) {
        return i + lag < audioSamples.length && (i < windowSize - 1 - lag);
      }

      for (int i = 0; canContinueFor(i); i++) {
        final sample = audioSamples[i];
        final shiftedSample = audioSamples[i + lag];

        autocorrelation[lag] += sample * shiftedSample;
        mDash += math.pow(sample, 2) + math.pow(shiftedSample, 2);
      }

      if (mDash == 0) {
        normalizedSquareDifference[lag] = 0;
      } else {
        normalizedSquareDifference[lag] = (2 * autocorrelation[lag]) / mDash;
      }

      if (normalizedSquareDifference[lag] < 0.0) {
        isFirstZeroCrossed = true;
      }

      if (isFirstZeroCrossed) {
        if (maxAutocorrelation != null) {
          if (autocorrelation[lag] > maxAutocorrelation) {
            maxAutocorrelation = autocorrelation[lag];
            maxAutocorrelationLocation = lag;
          }
        } else {
          maxAutocorrelation = autocorrelation[lag];
        }

        final isNotLastLags = lag < windowSize - 200;
        if (normalizedSquareDifference[lag] > highestNsdPeak && isNotLastLags) {
          highestNsdPeak = normalizedSquareDifference[lag];
          highestNsdPeakLocation = lag;
        }
      }
    }

    if (highestNsdPeakLocation == null) {
      return 0.0;
    }
    if (maxAutocorrelationLocation == null) {
      return 0.0;
    }

    final nsdFrequency = sampleRate / (highestNsdPeakLocation);
    final autocorrelationFrequency = sampleRate / maxAutocorrelationLocation;

    _nsdfFrequencies.removeAt(0);
    _nsdfFrequencies.add(nsdFrequency);

    _autocorrelationFrequencies.removeAt(0);
    _autocorrelationFrequencies.add(autocorrelationFrequency);

    if (_isFrequencyJumping(_nsdfFrequencies)) {
      return _averageFrequency(_autocorrelationFrequencies);
    } else {
      return _averageFrequency(_nsdfFrequencies);
    }
  }

  double _averageFrequency(List<double> frequencies) {
    final sum = frequencies.reduce((value, element) => value + element);

    return sum / frequencies.length;
  }

  bool _isFrequencyJumping(List<double> frequencies) {
    final Map<double, int> frequencyToAmount = {};
    frequencyToAmount[frequencies.first] = 1;

    for (int i = 1; i < frequencies.length; i++) {
      final frequency = frequencies[i];

      final entry = frequencyToAmount.entries.firstWhere(
        (element) {
          const padding = 4;
          return element.key.equalsInRange(frequency, padding);
        },
        orElse: () {
          final entry = MapEntry(frequency, 0);
          frequencyToAmount.addEntries([entry]);
          return entry;
        },
      );

      frequencyToAmount[entry.key] = frequencyToAmount[entry.key]! + 1;
    }
    const idealFrequencyAmount = 1;
    const suspiciousFrequencyAmount = 2;
    if (frequencyToAmount.length == idealFrequencyAmount) {
      return false;
    } else if (frequencyToAmount.length == suspiciousFrequencyAmount) {
      final entries = frequencyToAmount.entries.toList();

      final min = math.min(entries[0].value, entries[1].value);
      final max = math.max(entries[0].value, entries[1].value);

      const threshold = 0.2;

      if (min / max > threshold) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  void _processAudio(List<int> samples) {
    if (_isAudioProcessing) {
      return;
    }
    if (_sendPort == null) {
      return;
    }
    if (_frequenciesFromIsolate == null) {
      return;
    }

    _isAudioProcessing = true;

    _sendPort!.send(samples);

    _frequenciesFromIsolate!.next.then((frequency) {
      if (frequency is double) {
        _frequencyStreamController.add(frequency);
      }
      _isAudioProcessing = false;
    });
  }
}
