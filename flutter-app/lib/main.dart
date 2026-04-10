import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Avoid runtime fetch from fonts.gstatic.com when offline / blocked (web); falls back to bundled/system fonts.
  GoogleFonts.config.allowRuntimeFetching = false;

  final storage = await TokenStorage.create();

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
      ],
      child: const MoneyflowApp(),
    ),
  );
}
