import 'package:flutter/material.dart';
import 'package:gradient_slider/src/track_painting.dart';

/// A rounded [RangeSlider] track painted with a [Gradient], with an optional
/// border.
///
/// The gradient fills the span *between* the two thumbs; the segments outside
/// them are drawn inactive.
///
/// [GradientSlider] installs this for you; use it directly only when you want
/// the gradient track inside a [SliderTheme] of your own.
///
/// Unlike the single-thumb track, the active span cannot be drawn taller than
/// the rest: [RangeSliderTrackShape.paint] has no `additionalActiveTrackHeight`
/// parameter.
class GradientRangeSliderTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  /// Creates a gradient range track shape.
  GradientRangeSliderTrackShape({
    required this.activeTrackGradient,
    this.inactiveTrackGradient,
    this.trackBorder,
    this.trackBorderColor,
    this.gradientSpansTrack = true,
    this.trackRadius,
    this.additionalActiveTrackHeight,
  });

  /// Gradient painted across the span between the two thumbs.
  final Gradient activeTrackGradient;

  /// Gradient painted on the segments outside the thumbs.
  ///
  /// When null those segments fall back to
  /// [SliderThemeData.inactiveTrackColor].
  final Gradient? inactiveTrackGradient;

  /// Stroke width of the border drawn around the track.
  final double? trackBorder;

  /// Colour of the track border. Defaults to [Colors.black] when only
  /// [trackBorder] is given.
  final Color? trackBorderColor;

  /// Whether [activeTrackGradient] spans the whole track.
  ///
  /// When false it is compressed into the span between the thumbs, so the full
  /// ramp is visible however narrow that span is.
  final bool gradientSpansTrack;

  /// Corner radius of the track. Null keeps the fully-rounded default;
  /// 0 gives square corners.
  final double? trackRadius;

  /// How much taller the span between the thumbs is drawn than the rest of the
  /// track.
  ///
  /// Null keeps Material's range default of 0, matching
  /// [RoundedRectRangeSliderTrackShape]. [RangeSliderTrackShape.paint] has no
  /// such parameter, so this is implemented here rather than inherited.
  final double? additionalActiveTrackHeight;

  @override
  bool get isRounded => true;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
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

    // In RTL the start thumb sits on the right, so resolve which thumb is
    // which on screen before slicing the track up.
    final Offset leftThumbOffset;
    final Offset rightThumbOffset;
    switch (textDirection) {
      case TextDirection.ltr:
        leftThumbOffset = startThumbCenter;
        rightThumbOffset = endThumbCenter;
        break;
      case TextDirection.rtl:
        leftThumbOffset = endThumbCenter;
        rightThumbOffset = startThumbCenter;
        break;
    }

    // 0 = fully disabled, 1 = fully enabled.
    final double enabledT = enableAnimation.value.clamp(0.0, 1.0);
    final TrackPaints paints = buildTrackPaints(
      activeTrackGradient: activeTrackGradient,
      inactiveTrackGradient: inactiveTrackGradient,
      sliderTheme: sliderTheme,
      trackRect: trackRect,
      enabledT: enabledT,
      activeGradientRect: gradientSpansTrack
          ? null
          : Rect.fromLTRB(leftThumbOffset.dx, trackRect.top,
              rightThumbOffset.dx, trackRect.bottom),
    );

    final Radius radius = resolveTrackRadius(trackRadius, trackRect.height);
    final Canvas canvas = context.canvas;

    // Outer left segment: rounded on its outer edge only.
    final RRect leftRRect = RRect.fromLTRBAndCorners(
      trackRect.left,
      trackRect.top,
      leftThumbOffset.dx,
      trackRect.bottom,
      topLeft: radius,
      bottomLeft: radius,
    );

    // The active span between the thumbs: square on both ends, and optionally
    // taller than the segments outside it.
    final double extraHeight = additionalActiveTrackHeight ?? 0;
    final RRect middleRRect = RRect.fromLTRBAndCorners(
      leftThumbOffset.dx,
      trackRect.top - (extraHeight / 2),
      rightThumbOffset.dx,
      trackRect.bottom + (extraHeight / 2),
    );

    // Outer right segment.
    final RRect rightRRect = RRect.fromLTRBAndCorners(
      rightThumbOffset.dx,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
      topRight: radius,
      bottomRight: radius,
    );

    paintSegment(canvas, leftRRect, paints.inactive, paints.inactiveBase);
    paintSegment(canvas, rightRRect, paints.inactive, paints.inactiveBase);
    paintSegment(canvas, middleRRect, paints.active, paints.activeBase);

    paintTrackBorder(canvas, trackRect, radius, trackBorder, trackBorderColor);
  }
}
