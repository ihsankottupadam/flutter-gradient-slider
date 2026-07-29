import 'package:flutter/material.dart';
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
}
