#!/usr/bin/env bash
# scripts/release-lib.sh の判定をダミーのタグ一覧で確かめる。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/release-lib.sh

fails=0
check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "ok   ${name}"
  else
    echo "FAIL ${name}: expected '${expected}', got '${actual}'"
    fails=$((fails + 1))
  fi
}

tags=$'aaaa\trefs/tags/v1.0.0+7\n'
tags+=$'bbbb\trefs/tags/v1.0.0+7^{}\n'
tags+=$'cccc\trefs/tags/v1.0.0+8\n'
tags+=$'dddd\trefs/tags/v1.0.0+8^{}\n'
tags+=$'eeee\trefs/tags/v0.9.0+10-rc\n'
tags+=$'ffff\trefs/tags/other+99\n'
tags+=$'1111\trefs/tags/v1.0.1+9\n'

check "タグの最大（注釈付き・対象外の名前を含む）" 9 "$(max_tagged_build <<<"$tags")"
check "タグなし" 0 "$(max_tagged_build <<<"")"

check "pubspecよりタグが大きい" 10 "$(decide_build 8 9 "")"
check "タグよりpubspecが大きい" 13 "$(decide_build 12 9 "")"
check "同じ値" 10 "$(decide_build 9 9 "")"
check "--buildが次の値と同じ" 10 "$(decide_build 8 9 10)"
check "--buildが次の値より大きい" 15 "$(decide_build 8 9 15)"
decide_build 8 9 9 2>/dev/null
check "--buildがタグの最大と同じなら拒否" 1 "$?"
decide_build 12 9 11 2>/dev/null
check "--buildがpubspec以下なら拒否" 1 "$?"
decide_build 8 9 abc 2>/dev/null
check "--buildが整数でなければ拒否" 1 "$?"

check "注釈付きタグは指す先のコミット" dddd "$(tagged_commit v1.0.0+8 <<<"$tags")"
check "軽量タグはそのまま" 1111 "$(tagged_commit v1.0.1+9 <<<"$tags")"
check "無いタグは空" "" "$(tagged_commit v1.0.0+80 <<<"$tags")"

check_no_bump v1.0.0+80 "" dddd 2>/dev/null
check "--no-bump: タグが無ければ許す" 0 "$?"
check_no_bump v1.0.0+8 dddd dddd 2>/dev/null
check "--no-bump: タグがHEADなら許す" 0 "$?"
check_no_bump v1.0.0+8 dddd 9999 2>/dev/null
check "--no-bump: タグが別のコミットなら拒否" 1 "$?"

check "前のタグ: 番号未満で最大" v1.0.1+9 "$(previous_tag 10 <<<"$tags")"
check "前のタグ: 同じ番号は含めない" v1.0.0+8 "$(previous_tag 9 <<<"$tags")"
check "前のタグ: 無ければ空" "" "$(previous_tag 7 <<<"$tags")"

subjects=$'ビルド番号を9にする (#391)\n'
subjects+=$'release.shでビルド番号の重複と食い違いを防ぐ (#390)\n'
subjects+=$'バージョンを1.0.1+10にする (#392)\n'
subjects+=$'Androidのリリースビルドが起動直後にクラッシュする問題を直す (#389)\n'
subjects+=$'番号なしのコミット\n'
check "変更一覧: 番号上げを除きPR番号を前に" \
  $'- #390 release.shでビルド番号の重複と食い違いを防ぐ\n- #389 Androidのリリースビルドが起動直後にクラッシュする問題を直す\n- 番号なしのコミット' \
  "$(format_change_lines <<<"$subjects")"
check "jaの下書き: PR番号を外す" \
  $'- release.shでビルド番号の重複と食い違いを防ぐ\n- Androidのリリースビルドが起動直後にクラッシュする問題を直す\n- 番号なしのコミット' \
  "$(draft_ja_notes <<<"$subjects")"
check "jaの下書き: 変更が無いとき" "- （変更点を書く）" "$(draft_ja_notes <<<"ビルド番号を9にする (#391)")"

notes=$'# 1.0.1\r\n\r\n## ja\r\n\r\n- 起動直後の終了を修正\r\n\r\n- 英語に対応\r\n\r\n## en\n- Fixed a crash\n- Added English\n\n\n## memo\nメモ'
check "notes: ja節（CRLF・前後と途中の空行）" $'- 起動直後の終了を修正\n\n- 英語に対応' "$(notes_section ja <<<"$notes")"
check "notes: en節（次の見出しで終わる）" $'- Fixed a crash\n- Added English' "$(notes_section en <<<"$notes")"
check "notes: #見出しでも節が終わる" "- Fix" "$(notes_section en <<<$'## en\n- Fix\n# 次\nメモ')"
check "notes: 無い節は空" "" "$(notes_section fr <<<"$notes")"

check "文字数は文字単位" 5 "$(char_count "起動abc")"
long_ja="$(printf '%0501d' 0)"
check "上限: 範囲内なら警告なし" "" "$(store_limit_warnings "- 短い")"
check "上限: Playの500文字を超えたら警告" 1 "$(store_limit_warnings "$long_ja" | grep -c 'Google Play')"

check "タイトル: Androidのテストトラック" "1.0.0 (9) Android alpha" "$(release_title 1.0.0 9 0 1 alpha)"
check "タイトル: 両方・production" "1.0.0 (10) iOS・Android" "$(release_title 1.0.0 10 1 1 production)"
check "タイトル: iOSのみ" "1.0.0 (10) iOS" "$(release_title 1.0.0 10 1 0 internal)"
is_prerelease 0 1 alpha
check "プレリリース: Androidのテストトラックのみ" 0 "$?"
is_prerelease 1 1 alpha
check "プレリリース: iOSも上げたなら違う" 1 "$?"
is_prerelease 0 1 production
check "プレリリース: productionなら違う" 1 "$?"

body="$(release_body 1 $'- Android: Google Play（alpha）へ1.0.0+9をアップロード\n' "- 修正" "- #389 修正" v1.0.0+8)"
check "本文: 下書きの注意が先頭" 1 "$(head -n 1 <<<"$body" | grep -c '下書き: 利用者向けの言葉に直してから貼る')"
check "本文: Playの言語タグ" 1 "$(grep -c -x '<ja-JP>' <<<"$body")"
check "本文: Play と App Store のコードブロック" 4 "$(grep -c -x '```' <<<"$body")"
check "本文: 含まれる変更" "## 含まれる変更（v1.0.0+8 以降）" "$(grep '含まれる変更' <<<"$body")"
body="$(release_body 0 "- iOS: x" "- 修正" "" "")"
check "本文: notes指定時は下書きの注意なし" 0 "$(grep -c '下書き' <<<"$body")"

((fails == 0))
