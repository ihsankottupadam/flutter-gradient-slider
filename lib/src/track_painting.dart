import 'package:flutter/material.dart';

/// The paints needed to draw one gradient track at a given enabled state.
///
/// [activeBase] and [inactiveBase] are painted *underneath* their respective
/// gradients, and are null when the slider is fully enabled.
class TrackPaints {
  TrackPaints({
    required this.active,
    required this.inactive,
    this.activeBase,
    this.inactiveBase,
  });

  /// Paint for the portion of the track considered active.
  final Paint active;

  /// Paint for the remainder of the track.
  final Paint inactive;

  /// Solid disabled colour drawn beneath [active], or null when enabled.
  final Paint? activeBase;

  /// Solid disabled colour drawn beneath [inactive], or null when enabled or
  /// when the inactive track is a flat colour rather than a gradient.
  final Paint? inactiveBase;
}

/// Dims a shader-backed paint towards transparent.
///
/// A [Paint]'s `color` is ignored once a `shader` is set, so a gradient can
/// only be dimmed through a colour filter. Modulating by white at alpha [t]
/// scales the gradient's alpha to [t] while leaving its hues untouched.
ColorFilter? fadeFilter(double t) => t >= 1.0
    ? null
    : ColorFilter.mode(Color.fromRGBO(255, 255, 255, t), BlendMode.modulate);

/// Builds the paints for a gradient track.
///
/// [enabledT] is 0 when fully disabled and 1 when fully enabled; anything in
/// between is mid-animation.
///
/// Shared by the single-thumb and range track shapes so their disabled
/// behaviour cannot drift apart.
TrackPaints buildTrackPaints({
  required Gradient activeTrackGradient,
  required Gradient? inactiveTrackGradient,
  required SliderThemeData sliderTheme,
  required Rect trackRect,
  required double enabledT,
}) {
  final Paint active = Paint()
    ..shader = activeTrackGradient.createShader(trackRect)
    ..colorFilter = fadeFilter(enabledT);

  final Paint inactive = Paint();
  if (inactiveTrackGradient != null) {
    inactive
      ..shader = inactiveTrackGradient.createShader(trackRect)
      ..colorFilter = fadeFilter(enabledT);
  } else {
    // No shader here, so a plain colour lerp is enough.
    inactive.color = Color.lerp(sliderTheme.disabledInactiveTrackColor,
        sliderTheme.inactiveTrackColor, enabledT)!;
  }

  // Painted beneath the faded gradients so the disabled colour shows through
  // instead of whatever happens to be behind the slider.
  final Paint? activeBase = enabledT >= 1.0
      ? null
      : (Paint()..color = sliderTheme.disabledActiveTrackColor!);
  final Paint? inactiveBase = (enabledT >= 1.0 || inactiveTrackGradient == null)
      ? null
      : (Paint()..color = sliderTheme.disabledInactiveTrackColor!);

  return TrackPaints(
    active: active,
    inactive: inactive,
    activeBase: activeBase,
    inactiveBase: inactiveBase,
  );
}

/// Draws [rrect] with [base] underneath [paint], skipping the base when null.
void paintSegment(Canvas canvas, RRect rrect, Paint paint, Paint? base) {
  if (base != null) {
    canvas.drawRRect(rrect, base);
  }
  canvas.drawRRect(rrect, paint);
}

/// Strokes the track outline when a border was requested.
///
/// The stroke width is clamped to half the track height so a wide border can
/// never swallow the track.
void paintTrackBorder(
  Canvas canvas,
  Rect trackRect,
  Radius trackRadius,
  double? trackBorder,
  Color? trackBorderColor,
) {
  if (trackBorder == null && trackBorderColor == null) {
    return;
  }
  final Paint strokePaint = Paint()
    ..color = trackBorderColor ?? Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = trackBorder != null
        ? (trackBorder < trackRect.height / 2
            ? trackBorder
            : trackRect.height / 2)
        : 1
    ..strokeCap = StrokeCap.round;
  canvas.drawRRect(
    RRect.fromLTRBAndCorners(
      trackRect.left,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
      topLeft: trackRadius,
      bottomLeft: trackRadius,
      bottomRight: trackRadius,
      topRight: trackRadius,
    ),
    strokePaint,
  );
}
