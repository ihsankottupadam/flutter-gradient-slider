library gradient_slider;

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gradient_slider/src/gradient_range_track_shape.dart';
import 'package:gradient_slider/src/image_range_thumb_shape.dart';
import 'package:gradient_slider/src/image_thumb_shape.dart';
import 'package:gradient_slider/src/track_painting.dart';

export 'package:gradient_slider/src/gradient_range_track_shape.dart';
export 'package:gradient_slider/src/image_range_thumb_shape.dart';
export 'package:gradient_slider/src/image_thumb_shape.dart';

/// Wraps a [Slider] or [RangeSlider] so its track is painted with a gradient,
/// with an optional image thumb.
///
/// For a [RangeSlider] the gradient fills the span between the two thumbs.
///
/// The thumb has three modes:
///
/// * pass [thumbAsset] or [thumbImage] for an image thumb,
/// * pass nothing for the default Material thumb,
/// * pass `showThumb: false` for no thumb at all.
///
/// ```dart
/// GradientSlider(
///   thumbAsset: 'assets/thumb.png',
///   activeTrackGradient: const LinearGradient(
///     colors: [Colors.pink, Colors.blue],
///   ),
///   slider: Slider(value: value, onChanged: (v) => setState(() => value = v)),
/// )
/// ```
///
/// Settings from an inherited [SliderTheme] are preserved, so anything this
/// widget does not set itself can still be themed from above it.
class GradientSlider extends StatefulWidget {
  /// Asset path of the image used as the thumb.
  ///
  /// Leave this and [thumbImage] null to fall back to the default Material
  /// thumb.
  final String? thumbAsset;

  /// Any [ImageProvider] to use as the thumb — [NetworkImage], [FileImage],
  /// [MemoryImage], or an [AssetImage] from another package.
  ///
  /// Takes precedence over [thumbAsset].
  ///
  /// ```dart
  /// GradientSlider(
  ///   thumbImage: const NetworkImage('https://example.com/thumb.png'),
  ///   slider: Slider(value: value, onChanged: onChanged),
  /// )
  /// ```
  final ImageProvider? thumbImage;

  /// The [Slider] or [RangeSlider] to apply the gradient track and thumb to.
  final Widget slider;

  /// Set to false to hide the thumb (and its overlay) entirely, leaving a
  /// bare gradient track that can still be dragged.
  ///
  /// Applies to [Slider] only. A [RangeSlider] always keeps its thumbs, since
  /// without them there is no cue as to which end is being dragged.
  final bool showThumb;

  /// A fully custom thumb shape. Takes precedence over [thumbAsset] and
  /// [thumbImage], and is ignored when [showThumb] is false.
  final SliderComponentShape? thumbShape;

  /// A fully custom thumb shape for a [RangeSlider].
  ///
  /// The range counterpart of [thumbShape]; takes precedence over
  /// [thumbAsset] and [thumbImage].
  final RangeSliderThumbShape? rangeThumbShape;

  /// A custom overlay shape. When null, the overlay is hidden if [showThumb]
  /// is false, and left to the Material default otherwise.
  ///
  /// [Slider] and [RangeSlider] share this field, so it applies to both.
  final SliderComponentShape? overlayShape;

  /// Only used when [thumbAsset] or [thumbImage] is provided.
  final double thumbWidth;

  /// Only used when [thumbAsset] or [thumbImage] is provided.
  final double thumbHeight;

  /// Height of the track. Falls back to the inherited theme when null.
  final double? trackHeight;

  /// Gradient painted before the thumb. Defaults to red-to-blue.
  final Gradient? activeTrackGradient;

  /// Gradient painted after the thumb.
  ///
  /// Takes precedence over [inactiveTrackColor].
  final Gradient? inactiveTrackGradient;

  /// Flat colour for the track after the thumb, used when
  /// [inactiveTrackGradient] is null.
  final Color? inactiveTrackColor;

  /// Stroke width of the track border. Clamped to half the track height.
  final double? trackBorder;

  /// Colour of the track border. Defaults to [Colors.black].
  final Color? trackBorderColor;

  const GradientSlider(
      {super.key,
      this.thumbAsset,
      this.thumbImage,
      required this.slider,
      this.showThumb = true,
      this.thumbShape,
      this.rangeThumbShape,
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
  ImageRangeThumbShape? myRangeShape;

  /// The decoded thumb, once [_loadImage] has resolved it.
  ui.Image? decodedThumb;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(GradientSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.thumbAsset != widget.thumbAsset ||
        oldWidget.thumbImage != widget.thumbImage) {
      // Covers null -> source, source -> null and source -> other source.
      _loadImage();
      return;
    }

    if (decodedThumb != null &&
        (oldWidget.thumbWidth != widget.thumbWidth ||
            oldWidget.thumbHeight != widget.thumbHeight)) {
      _updateThumbShape();
    }
  }

  /// True when the widget's thumb source changed while a load was in flight.
  bool _sourceChanged(String? asset, ImageProvider? provider) =>
      widget.thumbAsset != asset || widget.thumbImage != provider;

  Future<void> _loadImage() async {
    final asset = widget.thumbAsset;
    final provider = widget.thumbImage;
    if (asset == null && provider == null) {
      _clearThumb();
      return;
    }
    try {
      // An explicit provider wins; otherwise decode the asset path directly.
      final ui.Image image = provider != null
          ? await _resolveProvider(provider)
          : await _decodeAsset(asset!);
      // Bail out if the source changed again while this load was in flight.
      if (!mounted || _sourceChanged(asset, provider)) return;
      decodedThumb = image;
      _updateThumbShape();
    } catch (_) {
      // A missing or undecodable image falls back to the default Material
      // thumb instead of throwing across the async gap.
      _clearThumb();
    }
  }

  Future<ui.Image> _decodeAsset(String asset) async {
    final ByteData byData = await rootBundle.load(asset);
    final Uint8List bytes = Uint8List.view(byData.buffer);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  }

  Future<ui.Image> _resolveProvider(ImageProvider provider) {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(error);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  void _clearThumb() {
    decodedThumb = null;
    if (myShape == null && myRangeShape == null) return;
    if (!mounted) {
      myShape = null;
      myRangeShape = null;
      return;
    }
    setState(() {
      myShape = null;
      myRangeShape = null;
    });
  }

  void _updateThumbShape() {
    if (decodedThumb == null) {
      _clearThumb();
      return;
    }
    if (!mounted) return;
    setState(() {
      myShape = ImageThumbShape(
        image: decodedThumb!,
        width: widget.thumbWidth.toDouble(),
        height: widget.thumbHeight.toDouble(),
      );
      myRangeShape = ImageRangeThumbShape(
        image: decodedThumb!,
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

  /// Null means "let RangeSlider fall back to the Material default thumb".
  ///
  /// [GradientSlider.showThumb] is deliberately not honoured here: a range
  /// slider with no thumbs gives no clue which end is being dragged.
  RangeSliderThumbShape? get _resolvedRangeThumbShape =>
      widget.rangeThumbShape ?? myRangeShape;

  /// Null means "let Slider fall back to the Material default overlay".
  SliderComponentShape? get _resolvedOverlayShape {
    if (widget.overlayShape != null) return widget.overlayShape;
    if (!widget.showThumb) return SliderComponentShape.noOverlay;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Merge onto the inherited theme rather than replacing it, so any
    // SliderTheme above this widget (tick marks, value indicator, overlay
    // color, ...) still applies. A null field means "keep what was inherited".
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: _resolvedThumbShape,
        overlayShape: _resolvedOverlayShape,
        trackHeight: widget.trackHeight,
        inactiveTrackColor: widget.inactiveTrackColor,
        trackShape: GradientSliderTrackShape(
          activeTrackGradient:
              widget.activeTrackGradient ?? _defaultActiveGradient,
          inactiveTrackGradient: widget.inactiveTrackGradient,
          trackBorder: widget.trackBorder,
          trackBorderColor: widget.trackBorderColor,
        ),
        // RangeSlider reads its own pair of fields; a plain Slider ignores
        // these, so setting both keeps one widget working for either child.
        rangeThumbShape: _resolvedRangeThumbShape,
        rangeTrackShape: GradientRangeSliderTrackShape(
          activeTrackGradient:
              widget.activeTrackGradient ?? _defaultActiveGradient,
          inactiveTrackGradient: widget.inactiveTrackGradient,
          trackBorder: widget.trackBorder,
          trackBorderColor: widget.trackBorderColor,
        ),
      ),
      child: widget.slider,
    );
  }

  static const _defaultActiveGradient =
      LinearGradient(colors: [Colors.red, Colors.blue]);
}

/// A rounded slider track painted with a [Gradient] instead of a flat colour,
/// with an optional border.
///
/// [GradientSlider] installs this for you; use it directly only when you want
/// the gradient track inside a [SliderTheme] of your own.
///
/// Both tracks fade towards the theme's disabled colours as the slider is
/// disabled.
class GradientSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  /// Creates a gradient track shape.
  GradientSliderTrackShape({
    required this.activeTrackGradient,
    this.inactiveTrackGradient,
    this.trackBorder,
    this.trackBorderColor,
  });

  /// Gradient painted across the portion of the track before the thumb.
  final Gradient activeTrackGradient;

  /// Gradient painted after the thumb.
  ///
  /// When null the track falls back to [SliderThemeData.inactiveTrackColor].
  final Gradient? inactiveTrackGradient;

  /// Stroke width of the border drawn around the track.
  ///
  /// Clamped to half the track height. Null draws no border unless
  /// [trackBorderColor] is set, in which case it defaults to 1.
  final double? trackBorder;

  /// Colour of the track border. Defaults to [Colors.black] when only
  /// [trackBorder] is given.
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
    // 0 = fully disabled, 1 = fully enabled.
    final double enabledT = enableAnimation.value.clamp(0.0, 1.0);
    final TrackPaints paints = buildTrackPaints(
      activeTrackGradient: activeTrackGradient,
      inactiveTrackGradient: inactiveTrackGradient,
      sliderTheme: sliderTheme,
      trackRect: trackRect,
      enabledT: enabledT,
    );
    final Paint activePaint = paints.active;
    final Paint inactivePaint = paints.inactive;
    final Paint? activeBasePaint = paints.activeBase;
    final Paint? inactiveBasePaint = paints.inactiveBase;

    final canvas = context.canvas;
    final Paint leftTrackPaint;
    final Paint rightTrackPaint;
    final Paint? leftBasePaint;
    final Paint? rightBasePaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        leftBasePaint = activeBasePaint;
        rightBasePaint = inactiveBasePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        leftBasePaint = inactiveBasePaint;
        rightBasePaint = activeBasePaint;
        break;
    }

    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius =
        Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    final RRect leftTrackRRect = RRect.fromLTRBAndCorners(
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
    );
    final RRect rightTrackRRect = RRect.fromLTRBAndCorners(
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
    );

    paintSegment(canvas, leftTrackRRect, leftTrackPaint, leftBasePaint);
    paintSegment(canvas, rightTrackRRect, rightTrackPaint, rightBasePaint);
    paintTrackBorder(
        canvas, trackRect, trackRadius, trackBorder, trackBorderColor);
  }
}
