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

  Widget wrap(GradientSlider slider) =>
      MaterialApp(home: Scaffold(body: slider));

  Slider plainSlider() => Slider(value: 0.5, onChanged: (_) {});

  testWidgets('without thumbAsset it defers to the Material default thumb',
      (tester) async {
    await tester.pumpWidget(wrap(GradientSlider(slider: plainSlider())));

    // A null thumbShape makes Slider fall back to defaults.thumbShape.
    expect(themeOf(tester).thumbShape, isNull);
    expect(themeOf(tester).overlayShape, isNull);
  });

  testWidgets('showThumb: false hides both the thumb and the overlay',
      (tester) async {
    await tester.pumpWidget(
      wrap(GradientSlider(showThumb: false, slider: plainSlider())),
    );

    expect(themeOf(tester).thumbShape, same(SliderComponentShape.noThumb));
    expect(themeOf(tester).overlayShape, same(SliderComponentShape.noOverlay));
  });

  testWidgets('showThumb: false still paints the gradient track',
      (tester) async {
    await tester.pumpWidget(
      wrap(GradientSlider(showThumb: false, slider: plainSlider())),
    );

    expect(themeOf(tester).trackShape, isA<GradientSliderTrackShape>());
    // No assert should have fired while painting without a thumb.
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicit thumbShape wins over the default', (tester) async {
    final custom = SliderComponentShape.noThumb;
    await tester.pumpWidget(
      wrap(GradientSlider(thumbShape: custom, slider: plainSlider())),
    );

    expect(themeOf(tester).thumbShape, same(custom));
  });

  testWidgets('showThumb: false overrides a supplied thumbShape',
      (tester) async {
    await tester.pumpWidget(
      wrap(GradientSlider(
        showThumb: false,
        thumbShape: const RoundSliderThumbShape(),
        slider: plainSlider(),
      )),
    );

    expect(themeOf(tester).thumbShape, same(SliderComponentShape.noThumb));
  });

  testWidgets('a missing asset falls back to the default thumb, not a throw',
      (tester) async {
    await tester.pumpWidget(
      wrap(GradientSlider(
        thumbAsset: 'assets/does_not_exist.png',
        slider: plainSlider(),
      )),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(themeOf(tester).thumbShape, isNull);
  });

  testWidgets('dropping thumbAsset reverts to the default thumb',
      (tester) async {
    await tester.pumpWidget(
      wrap(GradientSlider(
        thumbAsset: 'assets/does_not_exist.png',
        slider: plainSlider(),
      )),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(GradientSlider(slider: plainSlider())));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(themeOf(tester).thumbShape, isNull);
  });

  testWidgets('keeps settings from an inherited SliderTheme', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SliderTheme(
          data: const SliderThemeData(
            valueIndicatorColor: Color(0xFF00FF00),
            activeTickMarkColor: Color(0xFF0000FF),
            overlayColor: Color(0xFFFF0000),
          ),
          child: GradientSlider(slider: plainSlider()),
        ),
      ),
    ));

    // Fields GradientSlider does not set must survive the merge.
    final data = themeOf(tester);
    expect(data.valueIndicatorColor, const Color(0xFF00FF00));
    expect(data.activeTickMarkColor, const Color(0xFF0000FF));
    expect(data.overlayColor, const Color(0xFFFF0000));
    // ...while the ones it does set still win.
    expect(data.trackShape, isA<GradientSliderTrackShape>());
  });

  group('disabled state', () {
    const boundaryKey = ValueKey('boundary');

    /// Renders a gradient-on-both-tracks slider and samples one pixel from
    /// the middle of the active (left) half of the track.
    Future<List<int>> sampleActiveTrack(WidgetTester tester,
        {required bool enabled}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 300,
                child: GradientSlider(
                  // No thumb, so only track painting can differ.
                  showThumb: false,
                  trackHeight: 10,
                  activeTrackGradient:
                      const LinearGradient(colors: [Colors.pink, Colors.blue]),
                  inactiveTrackGradient: const LinearGradient(
                      colors: [Colors.orange, Colors.green]),
                  slider: Slider(
                    value: 0.5,
                    onChanged: enabled ? (_) {} : null,
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
      late List<int> rgb;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final bytes = data!.buffer.asUint8List();
        // Well inside the active half, away from any antialiased edge.
        final x = image.width ~/ 4;
        final y = image.height ~/ 2;
        final i = (y * image.width + x) * 4;
        rgb = [bytes[i], bytes[i + 1], bytes[i + 2]];
      });
      return rgb;
    }

    int distance(List<int> a, List<int> b) =>
        (a[0] - b[0]).abs() + (a[1] - b[1]).abs() + (a[2] - b[2]).abs();

    /// Gap between the strongest and weakest channel: high for a saturated
    /// gradient colour, near zero for grey.
    int spread(List<int> c) {
      final sorted = [...c]..sort();
      return sorted.last - sorted.first;
    }

    testWidgets('dims the gradient when the slider is disabled',
        (tester) async {
      final enabled = await sampleActiveTrack(tester, enabled: true);
      final disabled = await sampleActiveTrack(tester, enabled: false);

      // Regression guard: Paint.color is ignored once Paint.shader is set, so
      // before the colorFilter fix an interior track pixel was identical in
      // both states. Sampling an interior pixel (not whole-image bytes) is
      // deliberate — edge antialiasing differs for unrelated reasons.
      expect(distance(enabled, disabled), greaterThan(30),
          reason: 'disabled track should not paint the full-strength gradient');
    });

    testWidgets('a disabled track desaturates to the disabled base colour',
        (tester) async {
      final enabled = await sampleActiveTrack(tester, enabled: true);
      final disabled = await sampleActiveTrack(tester, enabled: false);

      // The gradient fades out entirely, leaving the grey disabled base.
      expect(spread(enabled), greaterThan(40),
          reason: 'enabled track should show a saturated gradient colour');
      expect(spread(disabled), lessThan(20),
          reason: 'disabled track should be grey, not tinted by the gradient');
    });
  });
}
