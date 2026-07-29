import 'package:flutter_test/flutter_test.dart';
import 'package:gradient_slider/gradient_slider.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders all three thumb modes', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(GradientSlider), findsNWidgets(3));
    expect(find.text('Image thumb'), findsOneWidget);
    expect(find.text('Default Material thumb'), findsOneWidget);
    expect(find.text('No thumb'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
