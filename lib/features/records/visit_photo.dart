import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'photo_storage.dart';

/// 記録の写真。写真が無い・読めないときは丼のアイコンを出す。
class VisitPhoto extends ConsumerWidget {
  const VisitPhoto({super.key, required this.photoPath, this.cacheWidth});

  final String? photoPath;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.ramen_dining, color: colors.onSurfaceVariant),
      ),
    );
    final path = photoPath;
    if (path == null) return placeholder;
    return Image.file(
      ref.watch(photoStorageProvider).fileFor(path),
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
