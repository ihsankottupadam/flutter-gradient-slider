import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws an image as both thumbs of a [RangeSlider].
///
/// The range counterpart of `ImageThumbShape`; [RangeSliderThumbShape] is a
/// separate base class, so the single-thumb shape cannot be reused here.
class ImageRangeThumbShape extends RangeSliderThumbShape {
  /// Creates an image range thumb shape.
  ImageRangeThumbShape({
    required this.image,
    required this.width,
    required this.height,
  });

  /// The decoded image drawn for each thumb.
  final ui.Image image;

  /// Width the image is drawn at.
  final double width;

  /// Height the image is drawn at.
  final double height;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;

    final Rect destRect = Rect.fromLTWH(
      center.dx - (width / 2),
      center.dy - (height / 2),
      width,
      height,
    );

    final Paint paint = Paint()
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
