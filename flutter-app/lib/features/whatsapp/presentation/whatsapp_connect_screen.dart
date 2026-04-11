import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/whatsapp_status_provider.dart';
import '../data/whatsapp_api.dart';

class WhatsappConnectScreen extends ConsumerStatefulWidget {
  const WhatsappConnectScreen({super.key});

  @override
  ConsumerState<WhatsappConnectScreen> createState() =>
      _WhatsappConnectScreenState();
}

class _WhatsappConnectScreenState extends ConsumerState<WhatsappConnectScreen> {
  final _phoneCtrl = TextEditingController(text: '+');
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(whatsappLinkStatusProvider);
    await ref.read(whatsappLinkStatusProvider.future);
  }

  bool _isConnected(Map<String, dynamic> s) =>
      s['verified'] == true || s['connected'] == true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusAsync = ref.watch(whatsappLinkStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Optional: link WhatsApp to receive daily summaries and budget alerts on your phone. '
            'You can use the app fully without linking.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          statusAsync.when(
            data: (raw) {
              if (raw == null) {
                return const SizedBox.shrink();
              }
              final connected = _isConnected(raw);
              return Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        connected
                            ? Icons.check_circle_rounded
                            : Icons.chat_outlined,
                        color: connected
                            ? const Color(0xFF0D9F6E)
                            : cs.onSurface.withValues(alpha: 0.45),
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connected ? 'Connected' : 'Not connected',
                              style: GoogleFonts.manrope(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (connected && raw['phoneE164'] != null)
                              Text(
                                '${raw['phoneE164']}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (connected)
                        Icon(
                          Icons.verified_rounded,
                          color: const Color(0xFF0D9F6E).withValues(alpha: 0.9),
                          size: 26,
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object? error, StackTrace stackTrace) =>
                const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          statusAsync.maybeWhen(
            data: (raw) {
              if (raw != null && _isConnected(raw)) {
                return _PrefsToggles(
                  initialDaily: raw['dailySummary'] == true,
                  initialMonthly: raw['monthlyReport'] == true,
                  initialAlerts: raw['alerts'] == true,
                  phoneE164: raw['phoneE164']?.toString(),
                  onChanged: _refresh,
                );
              }
              return _LinkForm(
                phoneCtrl: _phoneCtrl,
                codeCtrl: _codeCtrl,
                loading: _loading,
                onRequestCode: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final phone = _phoneCtrl.text.trim();
                  if (phone.length < 10) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter a valid number in E.164 format (e.g. +9198…)',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _loading = true);
                  try {
                    final api = ref.read(whatsappApiProvider);
                    final res = await api.requestLink(phone);
                    final code = res['code']?.toString();
                    if (!context.mounted) return;
                    if (code != null && code.isNotEmpty) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Dev code: $code'),
                          duration: const Duration(seconds: 8),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Verification code sent — check your messages.',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Could not send code: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
                onVerify: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final phone = _phoneCtrl.text.trim();
                  final code = _codeCtrl.text.trim();
                  if (code.length != 6) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Enter the 6-digit code')),
                    );
                    return;
                  }
                  setState(() => _loading = true);
                  try {
                    final api = ref.read(whatsappApiProvider);
                    final res = await api.verify(phone, code);
                    final linked = res['linked'] == true;
                    if (!context.mounted) return;
                    if (linked) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('WhatsApp connected')),
                      );
                      await _refresh();
                    } else {
                      final err =
                          res['error']?.toString() ?? 'Verification failed';
                      messenger.showSnackBar(SnackBar(content: Text(err)));
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Verification failed: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LinkForm extends StatelessWidget {
  const _LinkForm({
    required this.phoneCtrl,
    required this.codeCtrl,
    required this.loading,
    required this.onRequestCode,
    required this.onVerify,
  });

  final TextEditingController phoneCtrl;
  final TextEditingController codeCtrl;
  final bool loading;
  final VoidCallback onRequestCode;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'WhatsApp number (E.164)',
            hintText: '+919876543210',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: loading ? null : onRequestCode,
          icon: const Icon(Icons.sms_outlined, size: 20),
          label: const Text('Send verification code'),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: '6-digit code',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: loading ? null : onVerify,
          icon: const Icon(Icons.verified_outlined, size: 20),
          label: const Text('Verify & connect'),
          style: OutlinedButton.styleFrom(foregroundColor: cs.primary),
        ),
      ],
    );
  }
}

class _PrefsToggles extends ConsumerStatefulWidget {
  const _PrefsToggles({
    required this.initialDaily,
    required this.initialMonthly,
    required this.initialAlerts,
    required this.phoneE164,
    required this.onChanged,
  });

  final bool initialDaily;
  final bool initialMonthly;
  final bool initialAlerts;
  final String? phoneE164;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_PrefsToggles> createState() => _PrefsTogglesState();
}

class _PrefsTogglesState extends ConsumerState<_PrefsToggles> {
  late bool _daily;
  late bool _monthly;
  late bool _alerts;

  @override
  void initState() {
    super.initState();
    _daily = widget.initialDaily;
    _monthly = widget.initialMonthly;
    _alerts = widget.initialAlerts;
  }

  Future<void> _patch({
    bool? dailySummary,
    bool? monthlyReport,
    bool? alerts,
  }) async {
    try {
      await ref
          .read(whatsappApiProvider)
          .updatePreferences(
            dailySummary: dailySummary,
            monthlyReport: monthlyReport,
            alerts: alerts,
            phoneE164: widget.phoneE164,
          );
      await widget.onChanged();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Notifications on WhatsApp',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily summary'),
          subtitle: const Text('Last 24 hours spend'),
          value: _daily,
          onChanged: (v) {
            setState(() => _daily = v);
            _patch(dailySummary: v);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Monthly report'),
          value: _monthly,
          onChanged: (v) {
            setState(() => _monthly = v);
            _patch(monthlyReport: v);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Budget & alerts'),
          subtitle: const Text('When a budget is exceeded'),
          value: _alerts,
          onChanged: (v) {
            setState(() => _alerts = v);
            _patch(alerts: v);
          },
        ),
      ],
    );
  }
}
