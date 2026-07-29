import 'dart:typed_data';
import 'dart:ui' as ui;

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

  /// Encodes a solid-colour PNG so a real [MemoryImage] can decode it.
  Future<Uint8List> makePng(Color color) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
        .drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint()..color = color);
    final ui.Image image = await recorder.endRecording().toImage(8, 8);
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Pumps [child] with real async available, so image decoding can finish.
  ///
  /// Decoding an [ImageProvider] needs genuine asynchrony; inside the default
  /// fake-async zone the stream listener never fires.
  Future<void> pumpAndDecode(WidgetTester tester, Widget child) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }

  Slider plainSlider() => Slider(value: 0.5, onChanged: (_) {});

  testWidgets('an ImageProvider thumb resolves to an image thumb shape',
      (tester) async {
    late Uint8List png;
    await tester.runAsync(() async => png = await makePng(Colors.red));

    await pumpAndDecode(
      tester,
      GradientSlider(thumbImage: MemoryImage(png), slider: plainSlider()),
    );

    expect(themeOf(tester).thumbShape, isA<ImageThumbShape>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('an ImageProvider also feeds the range thumb', (tester) async {
    late Uint8List png;
    await tester.runAsync(() async => png = await makePng(Colors.green));

    await pumpAndDecode(
      tester,
      GradientSlider(
        thumbImage: MemoryImage(png),
        slider: RangeSlider(
          values: const RangeValues(0.3, 0.7),
          onChanged: (_) {},
        ),
      ),
    );

    expect(themeOf(tester).rangeThumbShape, isA<ImageRangeThumbShape>());
  });

  testWidgets('thumbImage takes precedence over thumbAsset', (tester) async {
    late Uint8List png;
    await tester.runAsync(() async => png = await makePng(Colors.blue));

    // The asset does not exist; if it were used, the load would fail and fall
    // back to the default thumb instead of producing an image shape.
    await pumpAndDecode(
      tester,
      GradientSlider(
        thumbAsset: 'assets/does_not_exist.png',
        thumbImage: MemoryImage(png),
        slider: plainSlider(),
      ),
    );

    expect(themeOf(tester).thumbShape, isA<ImageThumbShape>());
  });

  testWidgets('a failing provider falls back to the default thumb',
      (tester) async {
    // Not a valid image payload, so decoding throws.
    await pumpAndDecode(
      tester,
      GradientSlider(
        thumbImage: MemoryImage(Uint8List.fromList([1, 2, 3, 4])),
        slider: plainSlider(),
      ),
    );

    expect(themeOf(tester).thumbShape, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropping thumbImage reverts to the default thumb',
      (tester) async {
    late Uint8List png;
    await tester.runAsync(() async => png = await makePng(Colors.red));

    await pumpAndDecode(
      tester,
      GradientSlider(thumbImage: MemoryImage(png), slider: plainSlider()),
    );
    expect(themeOf(tester).thumbShape, isA<ImageThumbShape>());

    await pumpAndDecode(tester, GradientSlider(slider: plainSlider()));

    expect(themeOf(tester).thumbShape, isNull);
    expect(tester.takeException(), isNull);
  });
}
