import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moneyflow_ai/app.dart';
import 'package:moneyflow_ai/core/providers.dart';
import 'package:moneyflow_ai/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shows branded login when logged out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await TokenStorage.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(storage)],
        child: const MoneyflowApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MoneyFlow AI'), findsOneWidget);
  });
}
