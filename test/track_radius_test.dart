import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradient_slider/gradient_slider.dart';
import 'package:gradient_slider/src/track_painting.dart';

void main() {
  group('resolveTrackRadius', () {
    test('null keeps the fully-rounded default', () {
      expect(resolveTrackRadius(null, 12), const Radius.circular(6));
    });

    test('0 gives square corners', () {
      expect(resolveTrackRadius(0, 12), Radius.zero);
    });

    test('an over-large radius is clamped to half the height', () {
      expect(resolveTrackRadius(100, 12), const Radius.circular(6));
    });

    test('a negative radius is clamped to zero', () {
      expect(resolveTrackRadius(-5, 12), Radius.zero);
    });

    test('a value in range is used as-is', () {
      expect(resolveTrackRadius(2, 12), const Radius.circular(2));
    });
  });

  group('painting', () {
    const boundaryKey = ValueKey('boundary');

    /// Samples the pixel at the very start of the track, vertically centred on
    /// the track's top edge — the corner that rounding carves away.
    Future<int> cornerAlpha(WidgetTester tester, {double? trackRadius}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 400,
                child: GradientSlider(
                  showThumb: false,
                  trackHeight: 20,
                  trackRadius: trackRadius,
                  activeTrackGradient:
                      const LinearGradient(colors: [Colors.red, Colors.red]),
                  slider: Slider(value: 1, onChanged: (_) {}),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
      late int alpha;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final bytes = data!.buffer.asUint8List();
        // Track spans the full width with no thumb; its top-left corner is the
        // first painted pixel. A rounded corner leaves it transparent.
        final y = (image.height / 2).round() - 9;
        const x = 1;
        final i = (y * image.width + x) * 4;
        alpha = bytes[i + 3];
      });
      return alpha;
    }

    testWidgets('a square track paints its corner', (tester) async {
      expect(await cornerAlpha(tester, trackRadius: 0), greaterThan(200));
    });

    testWidgets('a rounded track leaves its corner clear', (tester) async {
      expect(await cornerAlpha(tester), lessThan(50));
    });
  });

  testWidgets('trackRadius reaches the range track shape too', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GradientSlider(
          trackRadius: 0,
          slider: RangeSlider(
            values: const RangeValues(0.3, 0.7),
            onChanged: (_) {},
          ),
        ),
      ),
    ));

    final sliderTheme = tester.widget<SliderTheme>(find.descendant(
      of: find.byType(GradientSlider),
      matching: find.byType(SliderTheme),
    ));
    final shape =
        sliderTheme.data.rangeTrackShape! as GradientRangeSliderTrackShape;
    expect(shape.trackRadius, 0);
    expect(tester.takeException(), isNull);
  });
}
