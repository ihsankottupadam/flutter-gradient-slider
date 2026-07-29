import 'package:flutter/material.dart';
import 'package:gradient_slider/gradient_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gradient Slider',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double sliderValue = 5;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gradient Slider'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Image thumb'),
            GradientSlider(
              thumbAsset: 'assets/vert_thumb.png',
              thumbHeight: 30,
              thumbWidth: 30,
              trackHeight: 10,
              trackBorder: 1,
              trackBorderColor: Colors.black,
              activeTrackGradient: _activeGradient,
              inactiveTrackGradient: _inactiveGradient,
              inactiveTrackColor: Colors.black,
              slider: _buildSlider(),
            ),
            const SizedBox(height: 32),
            const Text('Default Material thumb'),
            GradientSlider(
              // No thumbAsset -> the standard round Material thumb.
              trackHeight: 10,
              trackBorder: 1,
              trackBorderColor: Colors.black,
              activeTrackGradient: _activeGradient,
              inactiveTrackGradient: _inactiveGradient,
              // Thumb styling belongs on the Slider itself, not on an outer
              // SliderTheme (which GradientSlider's own theme would shadow).
              slider: _buildSlider(thumbColor: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text('No thumb'),
            GradientSlider(
              showThumb: false,
              trackHeight: 10,
              trackBorder: 1,
              trackBorderColor: Colors.black,
              activeTrackGradient: _activeGradient,
              inactiveTrackGradient: _inactiveGradient,
              slider: _buildSlider(),
            ),
          ],
        ),
      ),
    );
  }

  Slider _buildSlider({Color? thumbColor}) => Slider(
      value: sliderValue,
      min: 0,
      max: 10,
      thumbColor: thumbColor,
      onChanged: (val) {
        setState(() {
          sliderValue = val;
        });
      });

  static const _activeGradient = LinearGradient(colors: [
    Colors.pink,
    Colors.blue,
    Colors.pink,
  ]);

  static final _inactiveGradient = LinearGradient(colors: [
    Colors.grey.shade800,
    Colors.grey.shade300,
    Colors.grey.shade800
  ]);
}
