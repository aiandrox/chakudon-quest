# release.sh のビルド番号の判定とリリース本文の組み立て。git・ネットワークに触れず、scripts/test-release-lib.sh で確かめられるようにしてある。
# 引数・標準入力の「タグ一覧」は `git ls-remote --tags origin` の出力形式。

max_tagged_build() {
  local max=0 sha ref n
  while read -r sha ref; do
    [[ "$ref" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)(\^\{\})?$ ]] || continue
    n=$((10#${BASH_REMATCH[1]}))
    if ((n > max)); then max=$n; fi
  done
  echo "$max"
}

# 注釈付きタグは「^{}」の行がコミットを指すので、そちらを優先する。
tagged_commit() {
  local tag="$1" sha ref plain="" peeled=""
  while read -r sha ref; do
    case "$ref" in
      "refs/tags/${tag}") plain="$sha" ;;
      "refs/tags/${tag}^{}") peeled="$sha" ;;
    esac
  done
  echo "${peeled:-$plain}"
}

# pubspecのビルド番号とタグの最大値の大きい方+1。forcedはそれ以上のときだけ受け付ける。
decide_build() {
  local pubspec_build="$1" tag_max="$2" forced="${3:-}" next
  next=$((pubspec_build > tag_max ? pubspec_build + 1 : tag_max + 1))
  if [[ -z "$forced" ]]; then
    echo "$next"
    return 0
  fi
  [[ "$forced" =~ ^[0-9]+$ ]] || {
    echo "error: --buildは整数で指定してください: ${forced}" >&2
    return 1
  }
  ((10#$forced >= next)) || {
    echo "error: --build ${forced} は使えません（pubspecの${pubspec_build}とタグの最大${tag_max}より大きい${next}以上にしてください）" >&2
    return 1
  }
  echo "$((10#$forced))"
}

# 同じ番号を別の中身で二度上げないよう、タグが無いかHEADを指しているときだけ許す。
check_no_bump() {
  local tag="$1" tag_sha="$2" head="$3"
  [[ -z "$tag_sha" || "$tag_sha" == "$head" ]] && return 0
  echo "error: --no-bumpは使えません: ${tag} は既に別のコミット（${tag_sha:0:10}）でアップロード済みです。番号を上げてください" >&2
  return 1
}

# 番号がbuild未満で最大のv*+Nタグの名前。無ければ空。
previous_tag() {
  local build="$1" best=-1 name="" sha ref n
  while read -r sha ref; do
    [[ "$ref" =~ ^refs/tags/(v[0-9]+\.[0-9]+\.[0-9]+\+([0-9]+))(\^\{\})?$ ]] || continue
    n=$((10#${BASH_REMATCH[2]}))
    if ((n < build && n > best)); then
      best=$n
      name="${BASH_REMATCH[1]}"
    fi
  done
  echo "$name"
}

# release.shが作る番号上げのコミットはユーザー向けの変更ではないので除く。
filter_change_subjects() {
  local subject
  while IFS= read -r subject; do
    case "$subject" in
      "" | ビルド番号を*にする* | バージョンを*にする*) continue ;;
    esac
    printf '%s\n' "$subject"
  done
}

# 「件名 (#123)」→「- #123 件名」
format_change_lines() {
  local subject
  filter_change_subjects | while IFS= read -r subject; do
    if [[ "$subject" =~ ^(.*)\ \(#([0-9]+)\)$ ]]; then
      printf -- '- #%s %s\n' "${BASH_REMATCH[2]}" "${BASH_REMATCH[1]}"
    else
      printf -- '- %s\n' "$subject"
    fi
  done
}

draft_ja_notes() {
  local subject out
  out="$(filter_change_subjects | while IFS= read -r subject; do
    [[ "$subject" =~ ^(.*)\ \(#[0-9]+\)$ ]] && subject="${BASH_REMATCH[1]}"
    printf -- '- %s\n' "$subject"
  done)"
  echo "${out:-- （変更点を書く）}"
}

# --notesのMarkdownから「## <lang>」節の本文を取り出す（前後の空行は除く）。
notes_section() {
  local lang="$1" line in=0 out="" blanks=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    if [[ "$line" =~ ^#{1,2}[[:space:]] ]]; then
      [[ "$line" == "## "* ]] || line=""
      line="${line#"## "}"
      line="${line%"${line##*[![:space:]]}"}"
      [[ "$line" == "$lang" ]] && in=1 || in=0
      continue
    fi
    ((in == 1)) || continue
    if [[ -z "${line//[[:space:]]/}" ]]; then
      [[ -z "$out" ]] || blanks+=$'\n'
      continue
    fi
    [[ -z "$out" ]] || out+=$'\n'
    out+="${blanks}${line}"
    blanks=""
  done
  printf '%s' "$out"
}

char_count() {
  local LC_ALL=en_US.UTF-8
  echo "${#1}"
}

# Google Playは1言語500文字、App Storeの「このバージョンの新機能」は4000文字まで。
store_limit_warnings() {
  local n
  n="$(char_count "$1")"
  if ((n > 4000)); then
    echo "警告: リリースノートが${n}文字あり、App Store（4000文字）とGoogle Play（500文字）の上限を超えています"
  elif ((n > 500)); then
    echo "警告: リリースノートが${n}文字あり、Google Playの上限（500文字）を超えています"
  fi
}

# 引数のiOS・Androidは、そのOSへ上げたかどうか（0/1）。
release_title() {
  local version="$1" build="$2" ios="$3" android="$4" track="$5" to=""
  ((ios == 0)) || to="iOS"
  if ((android == 1)); then
    [[ -z "$to" ]] || to+="・"
    to+="Android"
    [[ "$track" == production ]] || to+=" ${track}"
  fi
  echo "${version} (${build}) ${to}"
}

is_prerelease() {
  local ios="$1" android="$2" track="$3"
  ((ios == 0 && android == 1)) && [[ "$track" != production ]]
}

# 上げていない方のOSの節も載せる（後でもう一方を--no-bumpで上げるときに使い回すため）。
release_body() {
  local draft="$1" summary="$2" ja="$3" changes="$4" prev="$5" warnings
  if ((draft == 1)); then
    printf '> **下書き: 利用者向けの言葉に直してから貼る**（コミット件名から自動生成）\n\n'
  fi
  printf '%s\n\n' "${summary%$'\n'}"
  printf '## Google Play に貼るリリースノート\n\n```\n<ja-JP>\n%s\n</ja-JP>\n```\n\n' "$ja"
  warnings="$(store_limit_warnings "$ja")"
  [[ -z "$warnings" ]] || printf '%s\n\n' "$warnings"
  printf '## App Store Connect に貼る「このバージョンの新機能」（TestFlight は「テスト内容」）\n\n```\n%s\n```\n\n' "$ja"
  if [[ -n "$prev" ]]; then
    printf '## 含まれる変更（%s 以降）\n\n' "$prev"
  else
    printf '## 含まれる変更\n\n'
  fi
  printf '%s\n' "${changes:-（なし）}"
}
