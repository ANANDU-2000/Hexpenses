import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_config.dart';
import 'core/application/theme_mode_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/session_notifier.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/shell/presentation/app_shell.dart';

class MoneyflowApp extends ConsumerStatefulWidget {
  const MoneyflowApp({super.key});

  @override
  ConsumerState<MoneyflowApp> createState() => _MoneyflowAppState();
}

class _MoneyflowAppState extends ConsumerState<MoneyflowApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(sessionProvider);
    final showShell = kNoApiMode || loggedIn;
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'MoneyFlow AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: themeMode,
      home: showShell ? const AppShell() : const LoginScreen(),
    );
  }
}
