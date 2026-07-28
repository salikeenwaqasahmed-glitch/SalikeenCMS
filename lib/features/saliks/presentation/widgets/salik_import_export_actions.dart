import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/reference_data.dart';
import '../../../../core/export/salik_csv_export.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/salik.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';
import '../screens/salik_message_queue_screen.dart';

Future<void> exportSaliksFromSettings(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final saliks = ref.read(saliksStreamProvider).valueOrNull ?? [];
  if (saliks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('export_empty'))),
    );
    return;
  }

  final areas = ref.read(areasProvider).valueOrNull ?? kAreas;
  final lookup = buildAreaLookup(areas);
  await shareSalikCsv(saliks, areaLookup: lookup);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.t('export_success'))),
  );
}

/// Channel/template sheet then message queue. Selection happens on Saliks list.
Future<void> continueMessageWithSelected(
  BuildContext context,
  List<Salik> selected,
) async {
  if (selected.isEmpty) return;

  final config = await showModalBottomSheet<_MessageConfig>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _ChannelTemplateSheet(),
  );
  if (!context.mounted || config == null) return;

  context.push(
    '/saliks/message-queue',
    extra: SalikMessageQueueArgs(
      saliks: selected,
      channel: config.channel,
      message: config.message,
    ),
  );
}

class _MessageConfig {
  const _MessageConfig({required this.channel, required this.message});

  final SalikMessageChannel channel;
  final String message;
}

class _ChannelTemplateSheet extends StatefulWidget {
  const _ChannelTemplateSheet();

  @override
  State<_ChannelTemplateSheet> createState() => _ChannelTemplateSheetState();
}

class _ChannelTemplateSheetState extends State<_ChannelTemplateSheet> {
  SalikMessageChannel _channel = SalikMessageChannel.whatsapp;
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.t('message_saliks'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              RadioListTile<SalikMessageChannel>(
                value: SalikMessageChannel.whatsapp,
                groupValue: _channel,
                title: Text(l10n.t('channel_whatsapp')),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _channel = v);
                },
              ),
              RadioListTile<SalikMessageChannel>(
                value: SalikMessageChannel.sms,
                groupValue: _channel,
                title: Text(l10n.t('channel_sms')),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _channel = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _message,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.t('message_template'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _MessageConfig(
                      channel: _channel,
                      message: _message.text.trim(),
                    ),
                  );
                },
                child: Text(l10n.t('next_step')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
