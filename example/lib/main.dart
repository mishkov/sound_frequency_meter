import 'dart:math' as math;
import 'dart:typed_data';

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
      readsNumber: 2048,
    ),
  );

  Float64List _data = Float64List(0);
  final _lastData = List<num>.filled(8, 0.0);

  @override
  void initState() {
    super.initState();
    intFrequencyListener();
  }

  void intFrequencyListener() {
    _soundFrequencyMeter.addFrequencyListener((data) {
      if (data == null) return;
      if (!mounted) return;

      setState(() {
        _data = data;
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
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: DataPainter(_data, _lastData),
            ),
          ),
        ),
      ),
    );
  }
}

class DataPainter extends CustomPainter {
  List<num> data;

  List<num> lastData;

  DataPainter(this.data, this.lastData);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    _drawData(data, size, canvas);
  }

  void _drawData(Iterable<num> data, Size size, Canvas canvas) {
    final columnWidth = size.width / data.length;
    final maxColumnHeight = size.height;

    // num topValue = data.first;
    // num bottomValue = data.first;
    // for (int i = 1; i < data.length; i++) {
    //   final value = data.elementAt(i);
    //   topValue = math.max(value, topValue);
    //   bottomValue = math.min(value, bottomValue);
    // }
    const maxValue = 8; //math.max(topValue.abs(), bottomValue.abs());

    for (int i = 0; i < data.length; i++) {
      num value;
      if (data.elementAt(i) > lastData.elementAt(i)) {
        value = data.elementAt(i);
      } else {
        value = math.max(lastData.elementAt(i) - 0.5, 0);
      }

     //value = math.max(value, 1.0);

      lastData[i] = value.toDouble();

      final columnHeigt = (value / maxValue) * maxColumnHeight;

      final columnPaint = Paint()..color = Colors.blue;

      final left = i * columnWidth;
      final top = maxColumnHeight - columnHeigt;
      final column = Rect.fromLTWH(left, top, columnWidth, columnHeigt);

      canvas.drawRect(column, columnPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
