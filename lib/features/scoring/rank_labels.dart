import '../../l10n/app_localizations.dart';
import 'ranks.dart';

String adventurerRankLabel(AppLocalizations l10n, AdventurerRank rank) =>
    switch (rank) {
      AdventurerRank.apprentice => l10n.rankApprentice,
      AdventurerRank.traveler => l10n.rankTraveler,
      AdventurerRank.hero => l10n.rankHero,
      AdventurerRank.legend => l10n.rankLegend,
    };

String shopRankLabel(ShopRank rank) => rank.name.toUpperCase();
