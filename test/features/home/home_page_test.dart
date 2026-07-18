import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/features/home/presentation/home_page.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the active flavor from the injected config', (
    tester,
  ) async {
    await tester.pumpApp(const HomePage());

    expect(find.textContaining('dev'), findsOneWidget);
  });
}
