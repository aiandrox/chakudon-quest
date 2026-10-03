import '../../l10n/app_localizations.dart';
import '../inkan/inkan.dart';
import 'ranks.dart';

String adventurerRankLabel(AppLocalizations l10n, AdventurerRank rank) =>
    switch (rank) {
      AdventurerRank.apprentice => l10n.rankApprentice,
      AdventurerRank.dan1 => l10n.rankFirstDan,
      AdventurerRank.master => l10n.rankMaster,
      AdventurerRank.grandmaster => l10n.rankGrandmaster,
      // 二段〜九段。段の数は列挙の順番（初段が1）と同じ。
      _ => l10n.rankDan(kanjiNumber(rank.index)),
    };

String shopRankLabel(AppLocalizations l10n, ShopRank rank) => switch (rank) {
  ShopRank.s => l10n.shopRankS,
  ShopRank.a => l10n.shopRankA,
  ShopRank.b => l10n.shopRankB,
  ShopRank.c => l10n.shopRankC,
};
