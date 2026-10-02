import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';

/// 道中記の文。見出しは筆文字、本文は明朝で1文ずつ並べる。
class JournalView extends StatelessWidget {
  const JournalView({super.key, required this.lines, this.color});

  final List<String> lines;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = this.color ?? Washi.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.journalTitle,
          style: TextStyle(fontFamily: Washi.brush, fontSize: 20, color: color),
        ),
        const SizedBox(height: 6),
        for (final line in lines)
          Text(
            line,
            style: TextStyle(
              fontFamily: Washi.mincho,
              fontSize: 15,
              height: 1.8,
              color: color,
            ),
          ),
      ],
    );
  }
}
