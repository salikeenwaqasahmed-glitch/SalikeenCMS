import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/salik.dart';

enum SalikMessageChannel { whatsapp, sms }

class SalikMessageQueueArgs {
  const SalikMessageQueueArgs({
    required this.saliks,
    required this.channel,
    this.message = '',
  });

  final List<Salik> saliks;
  final SalikMessageChannel channel;
  final String message;
}

class SalikMessageQueueScreen extends StatefulWidget {
  const SalikMessageQueueScreen({required this.args, super.key});

  final SalikMessageQueueArgs args;

  @override
  State<SalikMessageQueueScreen> createState() =>
      _SalikMessageQueueScreenState();
}

class _SalikMessageQueueScreenState extends State<SalikMessageQueueScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  int _sent = 0;
  int _skipped = 0;
  bool _opening = false;
  bool _expectResume = false;
  bool _didBackground = false;
  bool _stopped = false;

  List<Salik> get _saliks => widget.args.saliks;

  bool get _done => _index >= _saliks.length;

  Salik? get _current => _done ? null : _saliks[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openCurrent();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_stopped) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_expectResume) _didBackground = true;
      return;
    }
    if (state == AppLifecycleState.resumed &&
        _expectResume &&
        _didBackground) {
      _expectResume = false;
      _didBackground = false;
      _advanceAfterOpen();
    }
  }

  Future<void> _openCurrent() async {
    final salik = _current;
    if (salik == null || _opening || _stopped) return;

    setState(() => _opening = true);
    _expectResume = true;
    _didBackground = false;

    final text = widget.args.message.trim();
    try {
      if (widget.args.channel == SalikMessageChannel.whatsapp) {
        final phone = ContactLauncher.whatsappPhoneForSalik(
          mobileNumber: salik.mobileNumber,
          whatsappNumber: salik.whatsappNumber,
        );
        await ContactLauncher.whatsappMessage(
          phone,
          text: text.isEmpty ? null : text,
        );
      } else {
        await ContactLauncher.sms(
          salik.mobileNumber,
          body: text.isEmpty ? null : text,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }

    // External app never opened — advance after short wait so queue not stuck.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _stopped) return;
    if (_expectResume && !_didBackground) {
      _expectResume = false;
      _advanceAfterOpen();
    }
  }

  void _advanceAfterOpen() {
    if (!mounted || _stopped || _done) return;
    setState(() {
      _sent++;
      _index++;
    });
    if (_done) {
      _finishIfNeeded();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_stopped) _openCurrent();
    });
  }

  void _skip() {
    if (_done || _stopped) return;
    _expectResume = false;
    _didBackground = false;
    setState(() {
      _skipped++;
      _index++;
    });
    if (_done) {
      _finishIfNeeded();
      return;
    }
    _openCurrent();
  }

  void _finishIfNeeded() {
    if (!_done || !mounted) return;
    _showSummaryAndPop();
  }

  void _stopEarly() {
    _stopped = true;
    _expectResume = false;
    _didBackground = false;
    _showSummaryAndPop();
  }

  void _showSummaryAndPop() {
    final l10n = context.l10n;
    final summary = l10n
        .t('message_queue_summary')
        .replaceAll('{sent}', '$_sent')
        .replaceAll('{skipped}', '$_skipped');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(summary)),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final salik = _current;
    final total = _saliks.length;
    final progress = l10n
        .t('message_queue_progress')
        .replaceAll('{current}', '${_done ? total : _index + 1}')
        .replaceAll('{total}', '$total');

    return AppScaffold(
      title: l10n.t('message_saliks'),
      showBackButton: true,
      onBack: _stopEarly,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              progress,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.t('message_auto_hint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (salik != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_opening)
                        const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      Text(
                        salik.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (salik.fatherName.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(salik.fatherName),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.args.channel == SalikMessageChannel.whatsapp
                            ? ContactLauncher.whatsappPhoneForSalik(
                                mobileNumber: salik.mobileNumber,
                                whatsappNumber: salik.whatsappNumber,
                              )
                            : salik.mobileNumber,
                      ),
                      if (widget.args.message.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.t('message_template'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(widget.args.message.trim()),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _opening ? null : _skip,
                child: Text(l10n.t('skip')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _stopEarly,
                child: Text(l10n.t('message_queue_done')),
              ),
            ] else
              Expanded(
                child: Center(child: Text(l10n.t('message_queue_done'))),
              ),
          ],
        ),
      ),
    );
  }
}
