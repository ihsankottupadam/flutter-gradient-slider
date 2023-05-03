library gradient_slider;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gradient_slider/src/image_thumb_shape.dart';

class GradientSlider extends StatefulWidget {
  final String thumbAsset;
  final Widget slider;
  final int thumbWidth;
  final int thumbHeight;
  final double? trackHeight;
  final Gradient? activeTrackGradient;
  final Gradient? inactiveTrackGradient;
  final Color? inactiveTrackColor;
  final double? trackBorder;
  final Color? trackBorderColor;

  const GradientSlider(
      {super.key,
      required this.thumbAsset,
      required this.slider,
      this.activeTrackGradient,
      this.thumbWidth = 50,
      this.thumbHeight = 50,
      this.trackHeight,
      this.inactiveTrackColor,
      this.inactiveTrackGradient,
      this.trackBorder,
      this.trackBorderColor});

  @override
  State<GradientSlider> createState() => _GradientSliderState();
}

class _GradientSliderState extends State<GradientSlider> {
  ImageThumbShape? myShape;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  _loadImage() async {
    ByteData byData = await rootBundle.load(widget.thumbAsset);
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
          inactiveTrackGradient: widget.inactiveTrackGradient,
          trackBorder: widget.trackBorder,
          trackBorderColor: widget.trackBorderColor,
        ),
      ),
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
    this.trackBorder,
    this.trackBorderColor,
  });
  final Gradient activeTrackGradient;
  final Gradient? inactiveTrackGradient;
  final double? trackBorder;
  final Color? trackBorderColor;
  @override
  void paint(
    PaintingContext context,
    ui.Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required ui.TextDirection textDirection,
    required ui.Offset thumbCenter,
    ui.Offset? secondaryOffset,
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
        begin: sliderTheme.disabledActiveTrackColor, end: Colors.white);
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
    final canvas = context.canvas;
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

    canvas.drawRRect(
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
    canvas.drawRRect(
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
    if (trackBorder != null || trackBorderColor != null) {
      final strokePaint = Paint()
        ..color = trackBorderColor ?? Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackBorder != null
            ? trackBorder! < trackRect.height / 2
                ? trackBorder!
                : trackRect.height / 2
            : 1
        ..strokeCap = StrokeCap.round;
      canvas.drawRRect(
          RRect.fromLTRBAndCorners(
              trackRect.left, trackRect.top, trackRect.right, trackRect.bottom,
              topLeft: trackRadius,
              bottomLeft: trackRadius,
              bottomRight: trackRadius,
              topRight: trackRadius),
          strokePaint);
    }
  }
}
