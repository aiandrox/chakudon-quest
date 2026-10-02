import '../records/models.dart';

/// 記録した店の出所（OpenPOI から取り込んだ店のもの）を、重なりを除いてまとめたもの。
class SourceCredits {
  const SourceCredits({required this.attributions, required this.licenses});

  final List<String> attributions;
  final List<String> licenses;

  bool get isEmpty => attributions.isEmpty && licenses.isEmpty;
}

SourceCredits sourceCredits(Iterable<Shop> shops) {
  final attributions = <String>{};
  final licenses = <String>{};
  for (final shop in shops) {
    final source = shop.dataSource;
    if (source == null) continue;
    attributions.addAll(source.attributions);
    licenses.addAll(source.licenses);
  }
  return SourceCredits(
    attributions: attributions.toList()..sort(),
    licenses: licenses.toList()..sort(),
  );
}
