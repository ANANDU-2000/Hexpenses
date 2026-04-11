import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../application/insights_providers.dart';
import '../data/insights_api.dart';

/// Which tab to show first (e.g. [chat] when opened from Profile).
enum InsightsEntryTab { insights, chat }

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({
    super.key,
    this.initialTab = InsightsEntryTab.insights,
  });

  final InsightsEntryTab initialTab;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _ChatTurn {
  _ChatTurn({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageCtrl = TextEditingController();
  final _scrollInsights = ScrollController();
  final _scrollChat = ScrollController();
  final List<_ChatTurn> _chatBubbles = [];
  final List<Map<String, String>> _apiHistory = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == InsightsEntryTab.chat ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageCtrl.dispose();
    _scrollInsights.dispose();
    _scrollChat.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _chatBubbles.add(_ChatTurn(fromUser: true, text: trimmed));
      _messageCtrl.clear();
    });
    _scrollChatToBottom();

    try {
      final api = ref.read(insightsApiProvider);
      final result = await api.chat(
        trimmed,
        history: _apiHistory.isEmpty ? null : List.from(_apiHistory),
      );
      _apiHistory.add({'role': 'user', 'content': trimmed});
      _apiHistory.add({'role': 'assistant', 'content': result.reply});
      if (_apiHistory.length > 24) {
        _apiHistory.removeRange(0, _apiHistory.length - 24);
      }
      if (mounted) {
        setState(() {
          _chatBubbles.add(
            _ChatTurn(
              fromUser: false,
              text: result.reply.isEmpty ? '(No reply)' : result.reply,
            ),
          );
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _chatBubbles.add(
            _ChatTurn(
              fromUser: false,
              text:
                  e.response?.data?.toString() ?? e.message ?? 'Request failed',
            ),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollChatToBottom();
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollChat.hasClients) return;
      _scrollChat.animateTo(
        _scrollChat.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(aiInsightsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'AI & insights',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Insights'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InsightsTab(
            async: async,
            scrollController: _scrollInsights,
            onRefresh: () async {
              ref.invalidate(aiInsightsProvider);
              await ref.read(aiInsightsProvider.future);
            },
            onOpenChat: () => _tabController.animateTo(1),
          ),
          _ChatTab(
            messageCtrl: _messageCtrl,
            scrollController: _scrollChat,
            chatBubbles: _chatBubbles,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({
    required this.async,
    required this.scrollController,
    required this.onRefresh,
    required this.onOpenChat,
  });

  final AsyncValue<AiInsightsPayload> async;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: onRefresh,
      child: async.when(
        data: (data) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              MfSpace.xxl,
              MfSpace.md,
              MfSpace.xxl,
              MfSpace.xxl,
            ),
            children: [
              AppCard(
                glass: true,
                padding: const EdgeInsets.all(MfSpace.lg),
                onTap: onOpenChat,
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: cs.primary),
                    const SizedBox(width: MfSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ask the assistant',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: MfSpace.xs),
                          Text(
                            'Open the Chat tab for spending questions and tips.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MfSpace.xl),
              if (data.source == 'heuristic' || data.source == 'rule')
                const SizedBox.shrink()
              else if (data.source == 'ai')
                Chip(
                  label: const Text('AI'),
                  avatar: const Icon(Icons.auto_awesome, size: 12),
                  visualDensity: VisualDensity.compact,
                )
              else
                Text(
                  'Source: ${data.source ?? 'n/a'}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              const SizedBox(height: MfSpace.lg),
              _sectionTitle(context, 'Monthly summary'),
              const SizedBox(height: MfSpace.sm),
              _insightCard(
                context,
                data.monthlyFinancialSummary.isEmpty
                    ? 'No summary yet.'
                    : data.monthlyFinancialSummary,
              ),
              const SizedBox(height: MfSpace.xl),
              _sectionTitle(context, 'Spending warnings'),
              const SizedBox(height: MfSpace.sm),
              if (data.spendingWarnings.isEmpty)
                _insightCard(
                  context,
                  'No category spikes detected vs last month.',
                )
              else
                ...data.spendingWarnings.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: MfSpace.sm),
                    child: _insightCard(
                      context,
                      line,
                      accent: cs.error.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              const SizedBox(height: MfSpace.md),
              _sectionTitle(context, 'Saving suggestions'),
              const SizedBox(height: MfSpace.sm),
              ...data.savingSuggestions.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: MfSpace.sm),
                  child: _insightCard(context, line, accent: cs.tertiary),
                ),
              ),
              const SizedBox(height: MfSpace.md),
              _sectionTitle(context, 'Budget recommendations'),
              const SizedBox(height: MfSpace.sm),
              ...data.budgetRecommendations.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: MfSpace.sm),
                  child: _insightCard(context, line, accent: cs.primary),
                ),
              ),
              const SizedBox(height: MfSpace.xxl),
            ],
          );
        },
        loading: () => ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(MfSpace.xxl),
          children: [Text('$e')],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _insightCard(BuildContext context, String text, {Color? accent}) {
    final cs = Theme.of(context).colorScheme;
    return LedgerActionLayer(
      padding: const EdgeInsets.all(MfSpace.lg),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: accent ?? cs.onSurface,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({
    required this.messageCtrl,
    required this.scrollController,
    required this.chatBubbles,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController messageCtrl;
  final ScrollController scrollController;
  final List<_ChatTurn> chatBubbles;
  final bool sending;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              MfSpace.xxl,
              MfSpace.md,
              MfSpace.xxl,
              MfSpace.md,
            ),
            children: [
              Text(
                'Ask about your spending, budgets, or savings. Replies use your latest snapshot when the API is available.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: MfSpace.lg),
              Wrap(
                spacing: MfSpace.sm,
                runSpacing: MfSpace.sm,
                children: [
                  _suggestionChip(
                    context,
                    'How can I save more?',
                    () => onSend('How can I save more?'),
                    sending,
                  ),
                  _suggestionChip(
                    context,
                    'Where am I overspending?',
                    () => onSend('Where am I overspending?'),
                    sending,
                  ),
                ],
              ),
              const SizedBox(height: MfSpace.lg),
              ...chatBubbles.map((m) => _chatBubble(context, m)),
              if (sending)
                const Padding(
                  padding: EdgeInsets.all(MfSpace.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          color: cs.surfaceContainerLowest,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MfSpace.md,
                MfSpace.sm,
                MfSpace.md,
                MfSpace.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: onSend,
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(MfRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MfSpace.sm),
                  IconButton.filled(
                    onPressed: sending ? null : () => onSend(messageCtrl.text),
                    icon: const Icon(Icons.send_rounded, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionChip(
    BuildContext context,
    String label,
    VoidCallback onTap,
    bool disabled,
  ) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 13)),
      onPressed: disabled ? null : onTap,
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      backgroundColor: cs.surfaceContainerLow,
    );
  }

  Widget _chatBubble(BuildContext context, _ChatTurn m) {
    final cs = Theme.of(context).colorScheme;
    final align = m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = m.fromUser ? cs.primaryContainer : cs.surfaceContainerHigh;
    final fg = m.fromUser ? cs.onPrimaryContainer : cs.onSurface;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: MfSpace.sm + 2),
        padding: const EdgeInsets.symmetric(
          horizontal: MfSpace.md + 2,
          vertical: MfSpace.sm + 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(MfRadius.md),
            topRight: const Radius.circular(MfRadius.md),
            bottomLeft: Radius.circular(m.fromUser ? MfRadius.md : 4),
            bottomRight: Radius.circular(m.fromUser ? 4 : MfRadius.md),
          ),
        ),
        child: Text(
          m.text,
          style: GoogleFonts.inter(fontSize: 14, color: fg, height: 1.4),
        ),
      ),
    );
  }
}
