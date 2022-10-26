library flutter_custom_slider;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_slider/src/image_thumb_shape.dart';

class FlutterCustomSlider extends StatefulWidget {
  final String imagePath;
  final Widget slider;
  final int thumbWidth;
  final int thumbHeight;
  final double? trackHeight;

  const FlutterCustomSlider(
      {super.key,
      required this.slider,
      required this.imagePath,
      this.thumbWidth = 50,
      this.thumbHeight = 50,
      this.trackHeight});

  @override
  State<FlutterCustomSlider> createState() => _FlutterCustomSliderState();
}

class _FlutterCustomSliderState extends State<FlutterCustomSlider> {
  ImageThumbShape? myShape;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  _loadImage() async {
    ByteData byData = await rootBundle.load(widget.imagePath);
    final Uint8List bytes = Uint8List.view(byData.buffer);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes,
        targetWidth: widget.thumbWidth, targetHeight: widget.thumbHeight);
    ui.Image image = (await codec.getNextFrame()).image;
    myShape = ImageThumbShape(image: image);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data:
          SliderThemeData(thumbShape: myShape, trackHeight: widget.trackHeight),
      child: widget.slider,
    );
  }
}
