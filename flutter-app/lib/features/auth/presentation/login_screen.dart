import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/dio_errors.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../application/session_notifier.dart';
import '../data/auth_api.dart';

/// Email/password sign in and sign up — Architectural Ledger layout (DESIGN.md).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _authPage = 0;

  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();

  final _upName = TextEditingController();
  final _upEmail = TextEditingController();
  final _upPassword = TextEditingController();
  final _upConfirm = TextEditingController();
  final _upPhone = TextEditingController();

  bool _signInPasswordVisible = false;
  bool _upPasswordVisible = false;
  bool _upConfirmVisible = false;
  bool _loading = false;

  static const double _splitBreakpoint = 880;

  @override
  void dispose() {
    _signInEmail.dispose();
    _signInPassword.dispose();
    _upName.dispose();
    _upEmail.dispose();
    _upPassword.dispose();
    _upConfirm.dispose();
    _upPhone.dispose();
    super.dispose();
  }

  Future<void> _saveSession(
    ({String access, String refresh, String? sessionId}) tokens, {
    String? userEmail,
  }) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
      sessionId: tokens.sessionId,
    );
    if (userEmail != null && userEmail.isNotEmpty) {
      await storage.setUserEmail(userEmail);
    }
    ref.read(sessionProvider.notifier).setLoggedIn(true);
  }

  Future<void> _signInWithEmail() async {
    final email = _signInEmail.text.trim();
    if (email.isEmpty || _signInPassword.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }
    setState(() => _loading = true);
    try {
      final tokens = await ref
          .read(authApiProvider)
          .login(email, _signInPassword.text);
      await _saveSession(tokens, userEmail: email);
    } on DioException catch (e) {
      if (mounted) _showErr(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (_upName.text.trim().isEmpty || _upEmail.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter name and email')));
      return;
    }
    if (_upPassword.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    if (_upPassword.text != _upConfirm.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _loading = true);
    try {
      final tokens = await ref
          .read(authApiProvider)
          .register(
            name: _upName.text,
            email: _upEmail.text.trim(),
            password: _upPassword.text,
            phone: _upPhone.text.trim().isEmpty ? null : _upPhone.text.trim(),
          );
      await _saveSession(tokens, userEmail: _upEmail.text.trim());
    } on DioException catch (e) {
      if (mounted) _showErr(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErr(DioException e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(dioErrorMessage(e)),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: MfPalette.canvas,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _splitBreakpoint;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 46, child: _BrandPanel(cs: cs)),
                Expanded(
                  flex: 54,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _AuthCard(
                          cs: cs,
                          authPage: _authPage,
                          onAuthPage: (i) => setState(() => _authPage = i),
                          loading: _loading,
                          signInBody: _buildSignInFields(context),
                          signUpBody: _buildSignUpFields(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandHeader(cs: cs),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _AuthCard(
                    cs: cs,
                    authPage: _authPage,
                    onAuthPage: (i) => setState(() => _authPage = i),
                    loading: _loading,
                    signInBody: _buildSignInFields(context),
                    signUpBody: _buildSignUpFields(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignInFields(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Email & password',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signInEmail,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signInPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _signInPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: MfPalette.textMuted,
              ),
              onPressed: () => setState(
                () => _signInPasswordVisible = !_signInPasswordVisible,
              ),
            ),
          ),
          obscureText: !_signInPasswordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signInWithEmail(),
        ),
        const SizedBox(height: 20),
        LedgerPrimaryGradientButton(
          onPressed: _signInWithEmail,
          loading: _loading,
          child: const Text('Sign in'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _authPage = 1),
            child: const Text('Need an account? Register'),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _upName,
          decoration: const InputDecoration(labelText: 'Full name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _upEmail,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _upPassword,
          decoration: InputDecoration(
            labelText: 'Password (min 8 characters)',
            suffixIcon: IconButton(
              icon: Icon(
                _upPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: MfPalette.textMuted,
              ),
              onPressed: () =>
                  setState(() => _upPasswordVisible = !_upPasswordVisible),
            ),
          ),
          obscureText: !_upPasswordVisible,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _upConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            suffixIcon: IconButton(
              icon: Icon(
                _upConfirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: MfPalette.textMuted,
              ),
              onPressed: () =>
                  setState(() => _upConfirmVisible = !_upConfirmVisible),
            ),
          ),
          obscureText: !_upConfirmVisible,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _upPhone,
          decoration: const InputDecoration(labelText: 'Mobile (optional)'),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _register(),
        ),
        const SizedBox(height: 22),
        LedgerPrimaryGradientButton(
          onPressed: _register,
          loading: _loading,
          child: const Text('Create account'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _authPage = 0),
            child: const Text('Already have an account? Sign in'),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF000B60), Color(0xFF142283), Color(0xFF0A1740)],
        ),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 56, 40, 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: cs.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MoneyFlow',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                'Your finances,\nclearer than ever.',
                style: GoogleFonts.dmSans(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track spending, understand patterns,\nand build better money habits.',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 48),
              const _FeaturePill(
                icon: Icons.offline_bolt_outlined,
                label: 'Works offline',
              ),
              const SizedBox(height: 10),
              const _FeaturePill(
                icon: Icons.bar_chart,
                label: 'AI-powered insights',
              ),
              const SizedBox(height: 10),
              const _FeaturePill(
                icon: Icons.lock_outline,
                label: 'Your data stays private',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF000B60), cs.primaryContainer],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'MONEYFLOW AI',
                style: GoogleFonts.dmMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                  color: MfPalette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your financial\nprivate office',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.cs,
    required this.authPage,
    required this.onAuthPage,
    required this.loading,
    required this.signInBody,
    required this.signUpBody,
  });

  final ColorScheme cs;
  final int authPage;
  final ValueChanged<int> onAuthPage;
  final bool loading;
  final Widget signInBody;
  final Widget signUpBody;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ledgerAmbientFabShadows(cs),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            authPage == 0 ? 'Welcome back' : 'Create your workspace',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            authPage == 0
                ? 'Sign in to continue'
                : 'Set up your account in a minute',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 22),
          _AuthPills(
            cs: cs,
            selected: authPage,
            onChanged: onAuthPage,
            busy: loading,
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey<int>(authPage),
              child: authPage == 0 ? signInBody : signUpBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPills extends StatelessWidget {
  const _AuthPills({
    required this.cs,
    required this.selected,
    required this.onChanged,
    this.busy = false,
  });

  final ColorScheme cs;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    Widget pill(int index, String label) {
      final on = selected == index;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: on ? cs.primary.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: busy ? null : () => onChanged(index),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    color: on
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [pill(0, 'Sign in'), pill(1, 'Sign up')]),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
