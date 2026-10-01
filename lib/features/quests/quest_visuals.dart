import 'package:flutter/material.dart';

import '../../theme/emblem.dart';
import 'quests.dart';

IconData questIcon(Quest quest) => switch (quest.id) {
  'bowls' => Icons.ramen_dining,
  'shops' => Icons.storefront,
  'queue' => Icons.groups,
  'limited' => Icons.local_offer,
  'retry' => Icons.replay,
  'boss' => Icons.shield,
  'styles' => Icons.explore,
  'first_bowl' => Icons.flag,
  'queue_60' => Icons.hourglass_bottom,
  'queue_90' => Icons.local_fire_department,
  'double_bowl' => Icons.restaurant,
  'third_time' => Icons.replay_circle_filled,
  'rare_shop' => Icons.auto_awesome,
  _ => Icons.emoji_events,
};

/// レベルが上がるほど豪華な色に。最高レベルは一番上の格にする。
EmblemTier questTier(Quest quest, int level) {
  if (level <= 0) return EmblemTier.locked;
  if (quest.kind == QuestKind.spot) return EmblemTier.gold;
  if (level >= quest.maxLevel) return EmblemTier.legend;
  return switch (level) {
    1 => EmblemTier.bronze,
    2 => EmblemTier.silver,
    3 => EmblemTier.gold,
    _ => EmblemTier.platinum,
  };
}
