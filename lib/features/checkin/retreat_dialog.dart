import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 撤退を記録するか確かめる。記録するならメモ（空でもよい）、やめるならnullを返す。
Future<String?> showRetreatDialog(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _RetreatDialog(),
);

class _RetreatDialog extends StatefulWidget {
  const _RetreatDialog();

  @override
  State<_RetreatDialog> createState() => _RetreatDialogState();
}

class _RetreatDialogState extends State<_RetreatDialog> {
  final _memoController = TextEditingController();

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reasons = [
      l10n.retreatReasonSoldOut,
      l10n.retreatReasonClosed,
      l10n.retreatReasonNoTime,
    ];

    return AlertDialog(
      title: Text(l10n.retreatTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.retreatMessage),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final reason in reasons)
                  ActionChip(
                    label: Text(reason),
                    onPressed: () =>
                        setState(() => _memoController.text = reason),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.retreatMemoLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_memoController.text.trim()),
          child: Text(l10n.retreatConfirm),
        ),
      ],
    );
  }
}
