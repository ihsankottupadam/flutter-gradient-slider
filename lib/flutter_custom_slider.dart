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
  final Gradient? activeTrackGradient;
  final Gradient? inactiveTrackGradient;
  final Color? inactiveTrackColor;

  const FlutterCustomSlider(
      {super.key,
      required this.slider,
      required this.imagePath,
      this.activeTrackGradient,
      this.thumbWidth = 50,
      this.thumbHeight = 50,
      this.trackHeight,
      this.inactiveTrackColor,
      this.inactiveTrackGradient});

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
      data: SliderThemeData(
          thumbShape: myShape,
          trackHeight: widget.trackHeight,
          inactiveTrackColor: widget.inactiveTrackColor,
          trackShape: GradientSliderTrackShape(
              activeTrackGradient:
                  widget.activeTrackGradient ?? _defaultAciveGradient,
              inactiveTrackGradient: widget.inactiveTrackGradient)),
      child: widget.slider,
    );
  }

  final _defaultAciveGradient =
      const LinearGradient(colors: [Colors.red, Colors.blue]);
}

class GradientSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  GradientSliderTrackShape({
    required this.activeTrackGradient,
    this.inactiveTrackGradient,
  });
  final Gradient activeTrackGradient;
  final Gradient? inactiveTrackGradient;
  @override
  void paint(
    PaintingContext context,
    ui.Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required ui.TextDirection textDirection,
    required ui.Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: inactiveTrackGradient != null
            ? Colors.white
            : sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()
      ..shader = activeTrackGradient.createShader(trackRect)
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    if (inactiveTrackGradient != null) {
      inactivePaint.shader = inactiveTrackGradient!.createShader(trackRect);
    }
    final Paint leftTrackPaint;
    final Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius =
        Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        (textDirection == TextDirection.ltr)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        thumbCenter.dx,
        (textDirection == TextDirection.ltr)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
        bottomLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
      ),
      leftTrackPaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        (textDirection == TextDirection.rtl)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        trackRect.right,
        (textDirection == TextDirection.rtl)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
        bottomRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
      ),
      rightTrackPaint,
    );
  }
}
