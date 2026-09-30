import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, required this.onChanged});

  final int? rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var stars = 1; stars <= 5; stars++)
          IconButton(
            iconSize: 44,
            tooltip: l10n.ratingStar(stars),
            color: color,
            isSelected: (rating ?? 0) >= stars,
            icon: const Icon(Icons.star_border),
            selectedIcon: const Icon(Icons.star),
            onPressed: () => onChanged(stars),
          ),
      ],
    );
  }
}
