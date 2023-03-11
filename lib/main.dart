import 'package:flutter/material.dart';
import 'package:sine_slider/sine_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sine Slider Demo',
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Builder(
          builder: (context) {
            return SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: const Center(
                  child: SizedBox(
                    width: 300,
                    child: _SineSlider(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SineSlider extends StatefulWidget {
  const _SineSlider();

  @override
  State<_SineSlider> createState() => __SineSliderState();
}

class __SineSliderState extends State<_SineSlider> {
  double _value = 0;

  @override
  Widget build(BuildContext context) {
    return SineSlider(
      value: _value,
      onChanged: (value) {
        setState(() => _value = value);
      },
      onChangeStart: (value) {},
      onChangeEnd: (value) {},
    );
  }
}
