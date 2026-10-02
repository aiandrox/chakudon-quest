import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../inkan/inkan_stamp.dart';
import '../journal/journal_view.dart';
import '../records/models.dart';
import '../records/visit_photo.dart';
import '../scoring/points.dart';

/// 共有用の1枚。印帳の1ページ（写真・印・縦書きの店名）に、道中記を添える。
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.entry,
    required this.scored,
    required this.journal,
    this.includePhoto = true,
    this.includeJournal = true,
    this.includePoints = true,
  });

  static const width = 360.0;

  final VisitWithShop entry;
  final ScoredVisit scored;
  final List<String> journal;
  final bool includePhoto;
  final bool includeJournal;
  final bool includePoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showPhoto = includePhoto && entry.visit.photoPath != null;
    final lines = includePoints
        ? journal
        : [for (final line in journal) withoutPoints(line)];

    return Container(
      width: width,
      color: Washi.page,
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: showPhoto
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 44),
                            child: PastedPhoto(
                              angle: -1.5 * math.pi / 180,
                              border: 6,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: VisitPhoto(
                                  photoPath: entry.visit.photoPath,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkanStamp(scored: scored, size: 110),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: InkanStamp(scored: scored, size: 160),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Washi.line)),
                ),
                child: VerticalText(
                  entry.shop.name,
                  maxChars: 10,
                  style: const TextStyle(
                    fontFamily: Washi.brush,
                    fontSize: 26,
                    color: Washi.ink,
                  ),
                ),
              ),
            ],
          ),
          if (includeJournal && lines.isNotEmpty) ...[
            const SizedBox(height: 16),
            JournalView(lines: lines),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.appName,
              style: const TextStyle(
                fontFamily: Washi.brush,
                fontSize: 13,
                color: Washi.faded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 道中記の文から修行点を除く（「醤油の一杯、修行点 85。」→「醤油の一杯。」）。
String withoutPoints(String line) => line.replaceAll(RegExp(r'、修行点 \d+'), '');
