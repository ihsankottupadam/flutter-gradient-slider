import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradient_slider/gradient_slider.dart';

void main() {
  const boundaryKey = ValueKey('boundary');

  /// Samples pixels at each given fraction across the rendered slider.
  Future<List<List<int>>> sample(
    WidgetTester tester, {
    required Widget child,
    required List<double> at,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(width: 400, child: child),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    late List<List<int>> out;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      final y = image.height ~/ 2;
      out = at.map((f) {
        final x = (image.width * f).round();
        final i = (y * image.width + x) * 4;
        return [bytes[i], bytes[i + 1], bytes[i + 2]];
      }).toList();
    });
    return out;
  }

  int distance(List<int> a, List<int> b) =>
      (a[0] - b[0]).abs() + (a[1] - b[1]).abs() + (a[2] - b[2]).abs();

  GradientSlider buffered({
    double? secondary,
    Gradient? secondaryGradient,
  }) =>
      GradientSlider(
        showThumb: false,
        trackHeight: 12,
        secondaryTrackGradient: secondaryGradient,
        activeTrackGradient:
            const LinearGradient(colors: [Colors.red, Colors.red]),
        inactiveTrackColor: Colors.black,
        slider: Slider(
          value: 0.3,
          secondaryTrackValue: secondary,
          onChanged: (_) {},
        ),
      );

  testWidgets('the buffer region is painted distinctly from the inactive track',
      (tester) async {
    // Thumb at 0.3, buffer to 0.7: 0.5 is inside the buffer, 0.85 beyond it.
    final withBuffer =
        await sample(tester, child: buffered(secondary: 0.7), at: [0.5, 0.85]);

    expect(distance(withBuffer[0], withBuffer[1]), greaterThan(30),
        reason: 'buffered region should differ from the plain inactive track');
  });

  testWidgets('without a secondary value nothing extra is painted',
      (tester) async {
    final none = await sample(tester, child: buffered(), at: [0.5, 0.85]);

    expect(distance(none[0], none[1]), lessThan(20),
        reason: 'both samples are plain inactive track');
  });

  testWidgets('a secondary value behind the thumb paints nothing',
      (tester) async {
    // Material only draws the buffer ahead of the thumb; 0.1 is behind it.
    final behind =
        await sample(tester, child: buffered(secondary: 0.1), at: [0.5, 0.85]);
    final none = await sample(tester, child: buffered(), at: [0.5, 0.85]);

    expect(distance(behind[0], none[0]), lessThan(20));
  });

  testWidgets('secondaryTrackGradient overrides the theme colour',
      (tester) async {
    final themed =
        await sample(tester, child: buffered(secondary: 0.7), at: [0.5]);
    final gradient = await sample(
      tester,
      child: buffered(
        secondary: 0.7,
        secondaryGradient:
            const LinearGradient(colors: [Colors.green, Colors.green]),
      ),
      at: [0.5],
    );

    expect(gradient[0][1], greaterThan(themed[0][1]),
        reason: 'an explicit green buffer should be greener than the default');
  });

  testWidgets('RTL paints the buffer on the other side of the thumb',
      (tester) async {
    // Mirrored, the buffer runs leftwards from the thumb, so the sample that
    // was buffered in LTR is now beyond it and vice versa.
    final rtl = await sample(
      tester,
      child: buffered(secondary: 0.7),
      at: [0.5, 0.15],
      textDirection: TextDirection.rtl,
    );

    expect(distance(rtl[0], rtl[1]), greaterThan(30));
  });
}
