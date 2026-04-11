import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use fonts from `assets/google_fonts/` (see pubspec) so web works when fonts.gstatic.com is blocked or slow.
  GoogleFonts.config.allowRuntimeFetching = false;

  final storage = await TokenStorage.create();

  runApp(
    ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
      child: const MoneyflowApp(),
    ),
  );
}
