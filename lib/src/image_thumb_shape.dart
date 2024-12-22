import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ImageThumbShape extends SliderComponentShape {
  final ui.Image image;
  final double width;
  final double height;

  ImageThumbShape({
    required this.image,
    required this.width,
    required this.height,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, height);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required Size sizeWithOverflow,
      required double textScaleFactor}) {
    final canvas = context.canvas;

    final imageOffset =
        Offset(center.dx - (width / 2), center.dy - (height / 2));

    final destRect = Rect.fromLTWH(
      imageOffset.dx,
      imageOffset.dy,
      width,
      height,
    );

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destRect,
      paint,
    );
  }
}
