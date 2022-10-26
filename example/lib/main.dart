import 'package:flutter/material.dart';
import 'package:flutter_custom_slider/flutter_custom_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Slider',
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
  final textcontroller = TextEditingController();
  double sliderValue = 5;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Slider'),
      ),
      body: Column(
        children: [
          FlutterCustomSlider(
            imagePath: 'assets/vert_thumb.png',
            thumbHeight: 30,
            thumbWidth: 30,
            slider: Slider(
                value: sliderValue,
                min: 0,
                max: 10,
                onChanged: (val) {
                  setState(() {
                    sliderValue = val;
                  });
                }),
          ),
          TextField(
            controller: textcontroller,
            keyboardType: TextInputType.number,
            maxLength: 2,
          ),
          ElevatedButton(
              onPressed: () {
                double val = double.parse(textcontroller.text);
                if (val >= 0 && val <= 10) {
                  setState(() {
                    sliderValue = val;
                  });
                }
              },
              child: const Text('change value'))
        ],
      ),
    );
  }
}
