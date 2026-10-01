import '../../l10n/app_localizations.dart';
import 'ranks.dart';

String adventurerRankLabel(AppLocalizations l10n, AdventurerRank rank) =>
    switch (rank) {
      AdventurerRank.apprentice => l10n.rankApprentice,
      AdventurerRank.traveler => l10n.rankTraveler,
      AdventurerRank.hero => l10n.rankHero,
      AdventurerRank.legend => l10n.rankLegend,
    };

String shopRankLabel(AppLocalizations l10n, ShopRank rank) => switch (rank) {
  ShopRank.s => l10n.shopRankS,
  ShopRank.a => l10n.shopRankA,
  ShopRank.b => l10n.shopRankB,
  ShopRank.c => l10n.shopRankC,
};
