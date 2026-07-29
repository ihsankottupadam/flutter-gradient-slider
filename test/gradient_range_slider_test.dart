import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradient_slider/gradient_slider.dart';

void main() {
  /// Reads the [SliderThemeData] that [GradientSlider] installs for its child.
  SliderThemeData themeOf(WidgetTester tester) {
    final sliderTheme = tester.widget<SliderTheme>(
      find.descendant(
        of: find.byType(GradientSlider),
        matching: find.byType(SliderTheme),
      ),
    );
    return sliderTheme.data;
  }

  RangeSlider plainRange({ValueChanged<RangeValues>? onChanged}) => RangeSlider(
        values: const RangeValues(0.3, 0.7),
        onChanged: onChanged ?? (_) {},
      );

  Widget wrap(GradientSlider slider) =>
      MaterialApp(home: Scaffold(body: slider));

  testWidgets('installs a gradient range track shape', (tester) async {
    await tester.pumpWidget(wrap(GradientSlider(slider: plainRange())));

    expect(
        themeOf(tester).rangeTrackShape, isA<GradientRangeSliderTrackShape>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('without thumbAsset it defers to the Material range thumb',
      (tester) async {
    await tester.pumpWidget(wrap(GradientSlider(slider: plainRange())));

    expect(themeOf(tester).rangeThumbShape, isNull);
  });

  testWidgets('an explicit rangeThumbShape wins over the default',
      (tester) async {
    const custom = RoundRangeSliderThumbShape(enabledThumbRadius: 14);
    await tester.pumpWidget(
      wrap(GradientSlider(rangeThumbShape: custom, slider: plainRange())),
    );

    expect(themeOf(tester).rangeThumbShape, same(custom));
  });

  testWidgets('keeps settings from an inherited SliderTheme', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SliderTheme(
          data: const SliderThemeData(
            valueIndicatorColor: Color(0xFF00FF00),
            activeTickMarkColor: Color(0xFF0000FF),
          ),
          child: GradientSlider(slider: plainRange()),
        ),
      ),
    ));

    final data = themeOf(tester);
    expect(data.valueIndicatorColor, const Color(0xFF00FF00));
    expect(data.activeTickMarkColor, const Color(0xFF0000FF));
    expect(data.rangeTrackShape, isA<GradientRangeSliderTrackShape>());
  });

  testWidgets('a plain Slider is unaffected by the range fields',
      (tester) async {
    await tester.pumpWidget(
      wrap(GradientSlider(slider: Slider(value: 0.5, onChanged: (_) {}))),
    );

    expect(themeOf(tester).trackShape, isA<GradientSliderTrackShape>());
    expect(tester.takeException(), isNull);
  });

  /// Drags near the start thumb and reports the resulting values.
  Future<RangeValues> dragStartThumb(WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: StatefulBuilder(
              builder: (context, setState) => GradientSlider(
                slider: RangeSlider(
                  values: values,
                  onChanged: (v) => setState(() => values = v),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final Rect box = tester.getRect(find.byType(RangeSlider));
    final Offset startThumb = Offset(box.left + box.width * 0.3, box.center.dy);
    await tester.dragFrom(startThumb, const Offset(-60, 0));
    await tester.pumpAndSettle();
    return values;
  }

  testWidgets('range thumbs are draggable with the default thumb',
      (tester) async {
    final values = await dragStartThumb(tester);

    expect(values.start, lessThan(0.3),
        reason: 'start thumb should have moved');
    expect(values.end, 0.7, reason: 'end thumb should be untouched');
  });

  group('painting', () {
    const boundaryKey = ValueKey('boundary');

    /// Renders a range slider and samples the three track segments:
    /// outside-left, between the thumbs, and outside-right.
    Future<List<List<int>>> sampleSegments(
      WidgetTester tester, {
      bool enabled = true,
      TextDirection textDirection = TextDirection.ltr,
      RangeValues values = const RangeValues(0.3, 0.7),
      List<double> at = const [0.12, 0.5, 0.88],
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 400,
                  child: GradientSlider(
                    trackHeight: 12,
                    activeTrackGradient: const LinearGradient(
                        colors: [Colors.pink, Colors.blue]),
                    inactiveTrackGradient: const LinearGradient(
                        colors: [Colors.grey, Colors.grey]),
                    slider: RangeSlider(
                      values: values,
                      onChanged: enabled ? (_) {} : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
      late List<List<int>> samples;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final bytes = data!.buffer.asUint8List();
        final y = image.height ~/ 2;
        List<int> pixelAt(double fraction) {
          final x = (image.width * fraction).round();
          final i = (y * image.width + x) * 4;
          return [bytes[i], bytes[i + 1], bytes[i + 2]];
        }

        samples = at.map(pixelAt).toList();
      });
      return samples;
    }

    int spread(List<int> c) {
      final sorted = [...c]..sort();
      return sorted.last - sorted.first;
    }

    int distance(List<int> a, List<int> b) =>
        (a[0] - b[0]).abs() + (a[1] - b[1]).abs() + (a[2] - b[2]).abs();

    testWidgets('the gradient fills only the span between the thumbs',
        (tester) async {
      final s = await sampleSegments(tester);
      final outsideLeft = s[0], middle = s[1], outsideRight = s[2];

      // Middle is the saturated gradient; both outer segments are grey.
      expect(spread(middle), greaterThan(40),
          reason: 'span between thumbs should show the active gradient');
      expect(spread(outsideLeft), lessThan(20),
          reason: 'left of the start thumb should be inactive');
      expect(spread(outsideRight), lessThan(20),
          reason: 'right of the end thumb should be inactive');
    });

    // Deliberately asymmetric: RangeValues(0.3, 0.7) is symmetric about the
    // centre, so LTR and RTL render identically and cannot tell the two apart.
    const asymmetric = RangeValues(0.2, 0.5);

    testWidgets('LTR puts the active span on the low-value side',
        (tester) async {
      // Active span covers screen 0.2-0.5, so 0.35 is inside it.
      final s = await sampleSegments(tester,
          values: asymmetric, at: const [0.35, 0.65]);

      expect(spread(s[0]), greaterThan(40), reason: '0.35 is between thumbs');
      expect(spread(s[1]), lessThan(20), reason: '0.65 is outside them');
    });

    testWidgets('RTL mirrors the active span', (tester) async {
      // With the axis reversed the same values cover screen 0.5-0.8, so the
      // saturated and grey samples swap compared with LTR.
      final s = await sampleSegments(tester,
          textDirection: TextDirection.rtl,
          values: asymmetric,
          at: const [0.35, 0.65]);

      expect(spread(s[1]), greaterThan(40),
          reason: 'RTL active span should sit on the mirrored side');
      expect(spread(s[0]), lessThan(20),
          reason: 'the LTR-active position should now be inactive');
    });

    testWidgets('a disabled range track desaturates', (tester) async {
      final enabled = await sampleSegments(tester);
      final disabled = await sampleSegments(tester, enabled: false);

      expect(distance(enabled[1], disabled[1]), greaterThan(30),
          reason: 'disabled track should not paint the full-strength gradient');
      expect(spread(disabled[1]), lessThan(20),
          reason: 'disabled active span should be grey');
    });
  });
}
