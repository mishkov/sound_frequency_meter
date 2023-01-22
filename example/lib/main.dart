import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sound_frequency_meter/sound_frequency_meter.dart';

void main() {
  runApp(const TunerApp());
}

class TunerApp extends StatefulWidget {
  const TunerApp({super.key});

  @override
  State<TunerApp> createState() => _TunerAppState();
}

class _TunerAppState extends State<TunerApp> {
  final _soundFrequencyMeter = SoundFrequencyMeter();
  Stream<double>? _frequencyStream;

  List<double> _lastFrequencies = [];

  @override
  void initState() {
    super.initState();

    _lastFrequencies = List.generate(
      100,
      (index) => 0.0,
    );

    intFrequencyMeter();
  }

  @override
  void dispose() {
    _soundFrequencyMeter.dispose();
    super.dispose();
  }

  void intFrequencyMeter() {
    _frequencyStream = _soundFrequencyMeter.frequencyStream;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple Tuner'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<double>(
                  stream: _frequencyStream,
                  builder: (context, snapshot) {
                    const textStyle =
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
                    if (snapshot.hasData) {
                      final frequency = snapshot.data!;
                      _lastFrequencies.removeAt(0);
                      _lastFrequencies.add(frequency);
                      return Text(
                        '${frequency.toStringAsFixed(2)} Hz',
                        style: textStyle,
                      );
                    } else {
                      return const Text(
                        '0.0 Hz',
                        style: textStyle,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                // SizedBox(
                //   width: double.infinity,
                //   height: double.infinity,
                //   child: CustomPaint(
                //     painter: DataPainter(_lastFrequencies),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class DataPainter extends CustomPainter {
//   List<double> data;

//   DataPainter(this.data);

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (data.isEmpty) return;

//     _drawData(data, size, canvas);
//   }

//   void _drawData(Iterable<num> data, Size size, Canvas canvas) {
//     final columnWidth = size.width / data.length;
//     final maxColumnHeight = size.height;

//     // num topValue = data.first;
//     // num bottomValue = data.first;
//     // for (int i = 1; i < data.length; i++) {
//     //   final value = data.elementAt(i);
//     //   topValue = math.max(value, topValue);
//     //   bottomValue = math.min(value, bottomValue);
//     // }
//     const maxValue = 8; //math.max(topValue.abs(), bottomValue.abs());

//     for (int i = 0; i < data.length; i++) {
//       num value;
//       if (data.elementAt(i) > data.elementAt(i)) {
//         value = data.elementAt(i);
//       } else {
//         value = math.max(data.elementAt(i) - 0.5, 0);
//       }

//       //value = math.max(value, 1.0);

//       data[i] = value.toDouble();

//       final columnHeigt = (value / maxValue) * maxColumnHeight;

//       final columnPaint = Paint()..color = Colors.blue;

//       final left = i * columnWidth;
//       final top = maxColumnHeight - columnHeigt;
//       final column = Rect.fromLTWH(left, top, columnWidth, columnHeigt);

//       canvas.drawRect(column, columnPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
