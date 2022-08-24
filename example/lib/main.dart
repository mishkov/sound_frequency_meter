import 'package:flutter/material.dart';

import 'package:sound_frequency_meter/sound_frequency_meter.dart';
import 'package:sound_frequency_meter/sound_frequency_meter_configuration.dart';

void main() {
  runApp(const TunerApp());
}

class TunerApp extends StatefulWidget {
  const TunerApp({super.key});

  @override
  State<TunerApp> createState() => _TunerAppState();
}

class _TunerAppState extends State<TunerApp> {
  final _soundFrequencyMeter = SoundFrequencyMeter(
    const SoundFrequencyMeterConfiguration(
      readsNumber: 30720,
    ),
  );

  double _frequency = 0.0;

  @override
  void initState() {
    super.initState();
    intFrequencyListener();
  }

  void intFrequencyListener() {
    _soundFrequencyMeter.addFrequencyListener((frequency) {
      if (frequency == null) return;
      if (!mounted) return;

      setState(() {
        _frequency = frequency;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tuner'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$_frequency Hz'),
              const SizedBox(height: 30),
              const Text(
                'Take your 🎸 and tune it!!!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
