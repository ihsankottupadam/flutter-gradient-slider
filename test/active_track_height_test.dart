import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradient_slider/gradient_slider.dart';

void main() {
  const boundaryKey = ValueKey('boundary');

  /// Counts how many pixels tall the painted track is at [fraction] across.
  ///
  /// The active side is drawn taller than the inactive side, so measuring a
  /// column on each side shows the difference directly.
  Future<int> trackHeightAt(
    WidgetTester tester, {
    required Widget child,
    required double fraction,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(width: 400, child: child),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    late int painted;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      final x = (image.width * fraction).round();
      painted = 0;
      for (int y = 0; y < image.height; y++) {
        final i = (y * image.width + x) * 4;
        if (bytes[i + 3] > 128) painted++;
      }
    });
    return painted;
  }

  GradientSlider slider({double? extra}) => GradientSlider(
        showThumb: false,
        trackHeight: 10,
        additionalActiveTrackHeight: extra,
        activeTrackGradient:
            const LinearGradient(colors: [Colors.red, Colors.red]),
        inactiveTrackColor: Colors.green,
        slider: Slider(value: 0.5, onChanged: (_) {}),
      );

  group('Slider', () {
    testWidgets('by default the active side is taller', (tester) async {
      final active =
          await trackHeightAt(tester, child: slider(), fraction: 0.25);
      final inactive =
          await trackHeightAt(tester, child: slider(), fraction: 0.75);

      expect(active, greaterThan(inactive),
          reason: "Material's default adds 2 to the active side");
    });

    testWidgets('0 makes both sides the same height', (tester) async {
      final active =
          await trackHeightAt(tester, child: slider(extra: 0), fraction: 0.25);
      final inactive =
          await trackHeightAt(tester, child: slider(extra: 0), fraction: 0.75);

      expect(active, inactive);
    });

    testWidgets('a larger value makes the active side taller still',
        (tester) async {
      final normal =
          await trackHeightAt(tester, child: slider(), fraction: 0.25);
      final fat =
          await trackHeightAt(tester, child: slider(extra: 12), fraction: 0.25);

      expect(fat, greaterThan(normal));
    });
  });

  group('RangeSlider', () {
    GradientSlider rangeSlider({double? extra}) => GradientSlider(
          trackHeight: 10,
          additionalActiveTrackHeight: extra,
          activeTrackGradient:
              const LinearGradient(colors: [Colors.red, Colors.red]),
          inactiveTrackColor: Colors.green,
          slider: RangeSlider(
            values: const RangeValues(0.25, 0.75),
            onChanged: (_) {},
          ),
        );

    testWidgets('defaults to a uniform track, matching Material',
        (tester) async {
      final between =
          await trackHeightAt(tester, child: rangeSlider(), fraction: 0.5);
      final outside =
          await trackHeightAt(tester, child: rangeSlider(), fraction: 0.1);

      expect(between, outside);
    });

    testWidgets('an explicit value raises the span between the thumbs',
        (tester) async {
      final between = await trackHeightAt(tester,
          child: rangeSlider(extra: 12), fraction: 0.5);
      final outside = await trackHeightAt(tester,
          child: rangeSlider(extra: 12), fraction: 0.1);

      expect(between, greaterThan(outside),
          reason: 'set explicitly, range sliders honour it too');
    });
  });
}
