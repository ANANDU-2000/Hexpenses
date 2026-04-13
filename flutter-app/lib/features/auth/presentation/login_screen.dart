import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/neon_glass_card.dart';
import '../../../core/dio_errors.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../application/session_notifier.dart';
import '../data/auth_api.dart';

/// Dark premium fintech auth: glass card, neon accent, email/password + register.
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

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _signInEmail.text.trim().isEmpty
              ? 'Enter your email above, then tap Forgot password again.'
              : 'If this email is registered, a reset link would be sent.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _socialStub(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name sign-in is not connected yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MfPalette.canvasGradientTop,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _splitBreakpoint;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 46, child: _AuthBrandPanel()),
                Expanded(
                  flex: 54,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _AuthColumn(
                          authPage: _authPage,
                          loading: _loading,
                          signInBody: _buildSignInForm(context),
                          signUpBody: _buildSignUpForm(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              const _LoginAmbientBackdrop(),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    MfSpace.xxl,
                    MfSpace.lg,
                    MfSpace.xxl,
                    MfSpace.xxl + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: _AuthColumn(
                    authPage: _authPage,
                    loading: _loading,
                    signInBody: _buildSignInForm(context),
                    signUpBody: _buildSignUpForm(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumAuthField(
          controller: _signInEmail,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: MfSpace.md),
        _PremiumAuthField(
          controller: _signInPassword,
          label: 'Password',
          obscureText: !_signInPasswordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signInWithEmail(),
          suffix: IconButton(
            onPressed: () => setState(
              () => _signInPasswordVisible = !_signInPasswordVisible,
            ),
            icon: Icon(
              _signInPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 22,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(height: MfSpace.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading ? null : _forgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: MfPalette.neonGreen,
              padding: const EdgeInsets.symmetric(horizontal: MfSpace.sm),
            ),
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: MfSpace.lg),
        _NeonGlowButton(
          label: 'Login',
          loading: _loading,
          onPressed: _signInWithEmail,
        ),
        const SizedBox(height: MfSpace.md),
        _SecondaryNeonOutlineButton(
          label: 'Create Account',
          onPressed: _loading ? null : () => setState(() => _authPage = 1),
        ),
        const SizedBox(height: MfSpace.xl),
        const _OrDivider(),
        const SizedBox(height: MfSpace.lg),
        Row(
          children: [
            Expanded(
              child: _SocialLoginTile(
                label: 'Google',
                onTap: _loading ? null : () => _socialStub('Google'),
                child: Text(
                  'G',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: MfSpace.md),
            Expanded(
              child: _SocialLoginTile(
                label: 'Apple',
                onTap: _loading ? null : () => _socialStub('Apple'),
                child: Icon(
                  Icons.apple,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumAuthField(
          controller: _upName,
          label: 'Full name',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: MfSpace.md),
        _PremiumAuthField(
          controller: _upEmail,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: MfSpace.md),
        _PremiumAuthField(
          controller: _upPassword,
          label: 'Password (min 8 characters)',
          obscureText: !_upPasswordVisible,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          suffix: IconButton(
            onPressed: () =>
                setState(() => _upPasswordVisible = !_upPasswordVisible),
            icon: Icon(
              _upPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 22,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(height: MfSpace.md),
        _PremiumAuthField(
          controller: _upConfirm,
          label: 'Confirm password',
          obscureText: !_upConfirmVisible,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          suffix: IconButton(
            onPressed: () =>
                setState(() => _upConfirmVisible = !_upConfirmVisible),
            icon: Icon(
              _upConfirmVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 22,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(height: MfSpace.md),
        _PremiumAuthField(
          controller: _upPhone,
          label: 'Mobile (optional)',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _register(),
        ),
        const SizedBox(height: MfSpace.xl),
        _NeonGlowButton(
          label: 'Create account',
          loading: _loading,
          onPressed: _register,
        ),
        const SizedBox(height: MfSpace.md),
        Center(
          child: TextButton(
            onPressed: _loading ? null : () => setState(() => _authPage = 0),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.65),
            ),
            child: Text(
              'Already have an account? Sign in',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginAmbientBackdrop extends StatelessWidget {
  const _LoginAmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MfPalette.canvasGradientTop,
            MfPalette.canvasGradientBottom,
            MfPalette.canvasGradientTop,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MfPalette.accentSoftPurple.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MfPalette.neonGreen.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MfPalette.darkBgElevated,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MfPalette.accentSoftPurple.withValues(alpha: 0.08),
                    Colors.transparent,
                    MfPalette.darkBgElevated,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 56, 40, 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AppLogoMark(size: 44),
                  const SizedBox(height: MfSpace.xl),
                  Text(
                    'MoneyFlow',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: MfSpace.md),
                  Text(
                    'Secure, minimal finance\ntracking for real life.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: MfSpace.xxxl),
                  const _BrandBullet(
                    icon: Icons.lock_outline_rounded,
                    label: 'Bank-grade mindset',
                  ),
                  const SizedBox(height: MfSpace.sm),
                  const _BrandBullet(
                    icon: Icons.blur_on_rounded,
                    label: 'Privacy-first by design',
                  ),
                  const SizedBox(height: MfSpace.sm),
                  const _BrandBullet(
                    icon: Icons.show_chart_rounded,
                    label: 'Insights that matter',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBullet extends StatelessWidget {
  const _BrandBullet({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MfPalette.neonGreen.withValues(alpha: 0.9)),
        const SizedBox(width: MfSpace.md),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _AppLogoMark extends StatelessWidget {
  const _AppLogoMark({this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: MfPalette.neonGreen.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: MfPalette.neonGreen.withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: size * 0.48,
        color: MfPalette.neonGreen,
      ),
    );
  }
}

class _AuthColumn extends StatelessWidget {
  const _AuthColumn({
    required this.authPage,
    required this.loading,
    required this.signInBody,
    required this.signUpBody,
  });

  final int authPage;
  final bool loading;
  final Widget signInBody;
  final Widget signUpBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _AppLogoMark()),
        SizedBox(height: authPage == 0 ? MfSpace.xl : MfSpace.lg),
        if (authPage == 0) ...[
          Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'Manage your finances smartly',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ] else ...[
          Text(
            'Create your account',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'Start tracking in under a minute',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
        const SizedBox(height: MfSpace.xl),
        NeonGlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.fromLTRB(
            MfSpace.xl,
            MfSpace.xl,
            MfSpace.xl,
            MfSpace.xl + 4,
          ),
          child: AnimatedSwitcher(
            duration: MfMotion.medium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey<int>(authPage),
              child: IgnorePointer(
                ignoring: loading,
                child: authPage == 0 ? signInBody : signUpBody,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumAuthField extends StatefulWidget {
  const _PremiumAuthField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final Widget? suffix;

  @override
  State<_PremiumAuthField> createState() => _PremiumAuthFieldState();
}

class _PremiumAuthFieldState extends State<_PremiumAuthField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final f = _focusNode.hasFocus;
    if (f != _focused) setState(() => _focused = f);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? MfPalette.neonGreen.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.12);
    final labelColor = _focused
        ? MfPalette.neonGreen.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.45);

    return AnimatedContainer(
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: MfPalette.neonGreen.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 0),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autocorrect: widget.autocorrect,
        textCapitalization: widget.textCapitalization,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.95),
        ),
        cursorColor: MfPalette.neonGreen,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          suffixIcon: widget.suffix,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          labelText: widget.label,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
          floatingLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MfPalette.neonGreen.withValues(alpha: 0.9),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MfSpace.lg,
            vertical: MfSpace.lg,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: MfPalette.neonGreen.withValues(alpha: 0.95),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: MfPalette.expenseRed.withValues(alpha: 0.8),
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: MfPalette.expenseRed),
          ),
        ),
      ),
    );
  }
}

class _NeonGlowButton extends StatelessWidget {
  const _NeonGlowButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return AnimatedOpacity(
      duration: MfMotion.fast,
      opacity: disabled ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: MfPalette.neonGreen.withValues(alpha: 0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: MfPalette.neonGreen.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(18),
            splashColor: MfPalette.onNeonGreen.withValues(alpha: 0.12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MfPalette.neonGreen,
                    MfPalette.neonGreenSoft,
                  ],
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: MfSpace.lg),
                alignment: Alignment.center,
                child: loading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: MfPalette.onNeonGreen.withValues(alpha: 0.9),
                        ),
                      )
                    : Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MfPalette.onNeonGreen,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryNeonOutlineButton extends StatelessWidget {
  const _SecondaryNeonOutlineButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: MfPalette.neonGreen.withValues(alpha: 0.55),
              width: 1.25,
            ),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: MfSpace.lg),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: MfPalette.neonGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Colors.white.withValues(alpha: 0.14);
    return Row(
      children: [
        Expanded(child: Divider(color: line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MfSpace.md),
          child: Text(
            'or',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ),
        Expanded(child: Divider(color: line, thickness: 1)),
      ],
    );
  }
}

class _SocialLoginTile extends StatelessWidget {
  const _SocialLoginTile({
    required this.label,
    required this.child,
    required this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: MfSpace.md,
              horizontal: MfSpace.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 28, height: 28, child: Center(child: child)),
                const SizedBox(width: MfSpace.sm),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
