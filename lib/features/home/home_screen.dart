import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../record/photo_picker.dart';
import '../record/record_screen.dart';
import '../records/models.dart';
import '../records/record_repository.dart';
import '../records/visit_photo.dart';

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
        AsyncData(:final value) => ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
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

final _dateFormat = DateFormat('yyyy/M/d HH:mm');

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.entry});

  final VisitWithShop entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visit = entry.visit;
    final rating = visit.rating;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 56,
          child: VisitPhoto(photoPath: visit.photoPath, cacheWidth: 168),
        ),
      ),
      title: Text(entry.shop.name),
      subtitle: Text(
        [
          _dateFormat.format(visit.eatenAt),
          if (rating != null) l10n.ratingStar(rating),
        ].join('  '),
      ),
    );
  }
}
