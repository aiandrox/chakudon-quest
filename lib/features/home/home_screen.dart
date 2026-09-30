import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../record/photo_picker.dart';
import '../record/record_screen.dart';
import '../records/date_format.dart';
import '../records/models.dart';
import '../records/record_repository.dart';
import '../records/visit_photo.dart';
import '../visit_detail/visit_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPhoto());
  }

  Future<void> _recoverLostPhoto() async {
    final path = await ref.read(photoPickerProvider).retrieveLostPhoto();
    if (path == null || !mounted) return;
    await _openRecord(recoveredPhotoPath: path);
  }

  Future<void> _openRecord({String? recoveredPhotoPath}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordScreen(recoveredPhotoPath: recoveredPhotoPath),
      ),
    );
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).recordSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visits = ref.watch(visitsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: switch (visits) {
        AsyncData(:final value) when value.isEmpty => Center(
          child: Text(l10n.homeEmpty, textAlign: TextAlign.center),
        ),
        AsyncData(:final value) => GridView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: value.length,
          itemBuilder: (context, index) => _VisitTile(entry: value[index]),
        ),
        AsyncError() => Center(child: Text(l10n.homeLoadFailed)),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.large(
        tooltip: l10n.addRecord,
        onPressed: _openRecord,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.entry});

  final VisitWithShop entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visit = entry.visit;
    final rating = visit.rating;
    const textStyle = TextStyle(color: Colors.white, height: 1.2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VisitPhoto(photoPath: visit.photoPath, cacheWidth: 600),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  [
                    formatDate(visit.eatenAt),
                    if (rating != null) l10n.ratingStar(rating),
                  ].join('  '),
                  style: textStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VisitDetailScreen(visitId: visit.id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
