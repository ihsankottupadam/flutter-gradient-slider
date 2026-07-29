import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradient_slider/gradient_slider.dart';

void main() {
  const boundaryKey = ValueKey('boundary');

  /// Renders a slider and samples one pixel at [fraction] across the image.
  Future<List<int>> sampleAt(
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
    late List<int> rgb;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      final x = (image.width * fraction).round();
      final y = image.height ~/ 2;
      final i = (y * image.width + x) * 4;
      rgb = [bytes[i], bytes[i + 1], bytes[i + 2]];
    });
    return rgb;
  }

  // Pink -> blue: red dominates at the ramp's start, blue at its end.
  const gradient = LinearGradient(colors: [Colors.pink, Colors.blue]);

  GradientSlider slider({required bool spans}) => GradientSlider(
        showThumb: false,
        trackHeight: 12,
        gradientSpansTrack: spans,
        activeTrackGradient: gradient,
        slider: Slider(value: 0.5, onChanged: (_) {}),
      );

  group('Slider', () {
    testWidgets('anchored to the track, the active half stops mid-ramp',
        (tester) async {
      // Just left of the thumb at 50%: only half the ramp has been traversed.
      final rgb =
          await sampleAt(tester, child: slider(spans: true), fraction: 0.45);

      expect(rgb[2], lessThan(200),
          reason: 'blue should not yet be at full strength mid-track');
    });

    testWidgets('compressed, the active half reaches the end of the ramp',
        (tester) async {
      final rgb =
          await sampleAt(tester, child: slider(spans: false), fraction: 0.45);

      expect(rgb[2], greaterThan(200),
          reason: 'the whole ramp should fit inside the active portion');
    });

    testWidgets('both modes still start from the same colour', (tester) async {
      // At the very start of the track the ramp has barely begun either way.
      final anchored =
          await sampleAt(tester, child: slider(spans: true), fraction: 0.08);
      final compressed =
          await sampleAt(tester, child: slider(spans: false), fraction: 0.08);

      expect((anchored[0] - compressed[0]).abs(), lessThan(60));
    });
  });

  group('RangeSlider', () {
    GradientSlider rangeSlider({required bool spans}) => GradientSlider(
          trackHeight: 12,
          gradientSpansTrack: spans,
          activeTrackGradient: gradient,
          slider: RangeSlider(
            values: const RangeValues(0.4, 0.6),
            onChanged: (_) {},
          ),
        );

    testWidgets('a narrow span shows the whole ramp when compressed',
        (tester) async {
      // The thumbs sit at roughly 0.42 and 0.55 of the rendered width, so
      // 0.44 is just inside the start of the active span.
      final anchored = await sampleAt(tester,
          child: rangeSlider(spans: true), fraction: 0.44);
      final compressed = await sampleAt(tester,
          child: rangeSlider(spans: false), fraction: 0.44);

      // Anchored, the span only ever shows the middle of the ramp. Compressed,
      // the ramp restarts at the first thumb, so its start is pink again.
      expect(compressed[0], greaterThan(anchored[0] + 30),
          reason: 'compressed should restart the ramp inside the span');
      expect(compressed[2], lessThan(anchored[2]),
          reason: 'and therefore be less far into the blue end');
    });
  });
}
