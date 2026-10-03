import '../../l10n/app_localizations.dart';
import '../inkan/inkan.dart';
import 'ranks.dart';

String adventurerRankLabel(AppLocalizations l10n, AdventurerRank rank) =>
    switch (rank) {
      AdventurerRank.apprentice => l10n.rankApprentice,
      AdventurerRank.dan1 => l10n.rankFirstDan,
      AdventurerRank.master => l10n.rankMaster,
      AdventurerRank.grandmaster => l10n.rankGrandmaster,
      // 五級〜一級は、一級から数えた順番。
      _ when rank.isKyu => l10n.rankKyu(
        kanjiNumber(AdventurerRank.kyu1.index - rank.index + 1),
      ),
      // 二段〜九段は、初段から数えた順番。
      _ => l10n.rankDan(
        kanjiNumber(rank.index - AdventurerRank.dan1.index + 1),
      ),
    };

String shopRankLabel(AppLocalizations l10n, ShopRank rank) => switch (rank) {
  ShopRank.s => l10n.shopRankS,
  ShopRank.a => l10n.shopRankA,
  ShopRank.b => l10n.shopRankB,
  ShopRank.c => l10n.shopRankC,
};
