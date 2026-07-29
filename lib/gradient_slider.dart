library gradient_slider;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gradient_slider/src/image_thumb_shape.dart';

class GradientSlider extends StatefulWidget {
  /// Asset path of the image used as the thumb.
  ///
  /// Leave this null to fall back to the default Material thumb.
  final String? thumbAsset;
  final Widget slider;

  /// Set to false to hide the thumb (and its overlay) entirely, leaving a
  /// bare gradient track that can still be dragged.
  final bool showThumb;

  /// A fully custom thumb shape. Takes precedence over [thumbAsset], and is
  /// ignored when [showThumb] is false.
  final SliderComponentShape? thumbShape;

  /// A custom overlay shape. When null, the overlay is hidden if [showThumb]
  /// is false, and left to the Material default otherwise.
  final SliderComponentShape? overlayShape;

  /// Only used when [thumbAsset] is provided.
  final double thumbWidth;

  /// Only used when [thumbAsset] is provided.
  final double thumbHeight;
  final double? trackHeight;
  final Gradient? activeTrackGradient;
  final Gradient? inactiveTrackGradient;
  final Color? inactiveTrackColor;
  final double? trackBorder;
  final Color? trackBorderColor;

  const GradientSlider(
      {super.key,
      this.thumbAsset,
      required this.slider,
      this.showThumb = true,
      this.thumbShape,
      this.overlayShape,
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
  ui.Image? thumbImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(GradientSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.thumbAsset != widget.thumbAsset) {
      // Covers null -> asset, asset -> null and asset -> other asset.
      _loadImage();
      return;
    }

    if (thumbImage != null &&
        (oldWidget.thumbWidth != widget.thumbWidth ||
            oldWidget.thumbHeight != widget.thumbHeight)) {
      _updateThumbShape();
    }
  }

  _loadImage() async {
    final asset = widget.thumbAsset;
    if (asset == null) {
      _clearThumb();
      return;
    }
    try {
      ByteData byData = await rootBundle.load(asset);
      final Uint8List bytes = Uint8List.view(byData.buffer);
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      // Bail out if the asset changed again while this load was in flight.
      if (!mounted || widget.thumbAsset != asset) return;
      thumbImage = image;
      _updateThumbShape();
    } catch (_) {
      // A missing or undecodable asset falls back to the default Material
      // thumb instead of throwing across the async gap.
      _clearThumb();
    }
  }

  void _clearThumb() {
    thumbImage = null;
    if (myShape == null) return;
    if (!mounted) {
      myShape = null;
      return;
    }
    setState(() => myShape = null);
  }

  void _updateThumbShape() {
    if (thumbImage == null) {
      _clearThumb();
      return;
    }
    if (!mounted) return;
    setState(() {
      myShape = ImageThumbShape(
        image: thumbImage!,
        width: widget.thumbWidth.toDouble(),
        height: widget.thumbHeight.toDouble(),
      );
    });
  }

  /// Null means "let Slider fall back to the Material default thumb".
  SliderComponentShape? get _resolvedThumbShape {
    if (!widget.showThumb) return SliderComponentShape.noThumb;
    return widget.thumbShape ?? myShape;
  }

  /// Null means "let Slider fall back to the Material default overlay".
  SliderComponentShape? get _resolvedOverlayShape {
    if (widget.overlayShape != null) return widget.overlayShape;
    if (!widget.showThumb) return SliderComponentShape.noOverlay;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        thumbShape: _resolvedThumbShape,
        overlayShape: _resolvedOverlayShape,
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
