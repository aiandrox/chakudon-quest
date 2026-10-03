import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../map/map_screen.dart';
import '../shugyo/shugyo_screen.dart';
import '../wishes/wish_list_screen.dart';
import '../../theme/washi_buttons.dart';
import '../record/record_screen.dart';
import 'home_screen.dart';

/// 下のタブ（印帳・願掛け・修行・地図）で画面を切り替える、アプリの外枠。
/// タブの真ん中には、どの画面からでも記録を始められる大きな判子を置く。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _mapIndex = 3;

  /// 下のタブで、真ん中の判子のために空けておく位置。
  static const _gap = 2;

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          const WishListScreen(),
          const ShugyoScreen(),
          // 地図は開いたときだけ作る。開くたびに全部のピンが入る範囲に合わせ直し、
          // 地図を見ていないときにタイルを取りに行かないようにするため。
          if (_index == _mapIndex)
            const MapScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: Padding(
        // タブの上に半分ほどはみ出すように、少し下げる。
        padding: const EdgeInsets.only(top: 36),
        child: RecordSealButton(
          tooltip: l10n.addRecord,
          onPressed: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: (_) => const RecordScreen())),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        // 真ん中は判子の場所として空けておく（押しても何もしない）。
        selectedIndex: _index < _gap ? _index : _index + 1,
        onDestinationSelected: (index) {
          if (index == _gap) return;
          setState(() => _index = index < _gap ? index : index - 1);
        },
        destinations: [
          for (final (glyph, label) in [
            (l10n.navGlyphRecords, l10n.navRecords),
            (l10n.navGlyphWishes, l10n.navWishes),
          ])
            NavigationDestination(
              icon: _TabSeal(glyph: glyph, selected: false),
              selectedIcon: _TabSeal(glyph: glyph, selected: true),
              label: label,
            ),
          const NavigationDestination(
            icon: SizedBox(width: RecordSealButton.size),
            label: '',
            enabled: false,
          ),
          for (final (glyph, label) in [
            (l10n.navGlyphShugyo, l10n.navShugyo),
            (l10n.navGlyphMap, l10n.navMap),
          ])
            NavigationDestination(
              icon: _TabSeal(glyph: glyph, selected: false),
              selectedIcon: _TabSeal(glyph: glyph, selected: true),
              label: label,
            ),
        ],
      ),
    );
  }
}

/// タブのアイコン。筆文字1字の印で、選んでいるときは朱で塗る。
class _TabSeal extends StatelessWidget {
  const _TabSeal({required this.glyph, required this.selected});

  final String glyph;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Washi.shu : Colors.transparent,
        border: Border.all(
          color: selected ? Washi.shu : Washi.inkSoft,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        glyph,
        style: TextStyle(
          fontFamily: Washi.brush,
          fontSize: 18,
          height: 1.1,
          color: selected ? Washi.page : Washi.inkSoft,
        ),
      ),
    );
  }
}
