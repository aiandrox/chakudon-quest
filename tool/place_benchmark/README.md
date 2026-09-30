# 店舗データの提供元の比較（#57）

同じ地点・同じ半径で、各社の「ラーメン店の検索」を実行し、結果を表にまとめる検証用のスクリプト。アプリには組み込まない。

## 使い方

```bash
# キーは環境変数で渡す（リポジトリには入れない）。無いものは飛ばす。OSM はキー不要。
export GOOGLE_PLACES_API_KEY=...   # Google Places API (New)
export YAHOO_CLIENT_ID=...         # Yahoo!デベロッパーネットワークの Client ID
export HOTPEPPER_API_KEY=...       # リクルート WEB サービス（任意）
export FOURSQUARE_API_KEY=...      # Foursquare Places API（任意）

dart run tool/place_benchmark/place_benchmark.dart            # 各1回
dart run tool/place_benchmark/place_benchmark.dart --repeat 5 # 速さ・失敗の回数も見る
dart run tool/place_benchmark/place_benchmark.dart --providers OSM,Google
```

- 結果の表は標準出力と `tool/place_benchmark/results/<日時>.md`、生データは同じフォルダの `.json` に出る（`results/` は .gitignore 済み）
- 地点と正解リストは `points.json`。自宅の近くなど公開したくない地点は、同じ形で `points.local.json` に書く（.gitignore 済み）

## 各社の検索条件

| 提供元 | 条件 |
|---|---|
| OSM | 今のアプリと同じ（cuisine=ramen、または店名にラーメン等） |
| Google | Nearby Search (New)、種類 `ramen_restaurant`、近い順、最大20件（1回で返る上限） |
| Yahoo! | ローカルサーチ、グルメ（業種コード 01）で「ラーメン」、近い順、最大100件 |
| ホットペッパー | ジャンル G013（ラーメン）、半径は 300/500/1000/2000/3000m から近いもの、最大100件 |
| Foursquare | 「ラーメン」で検索、近い順、最大50件 |

## 費用

どれも無料枠の範囲。Google は月5,000回まで無料で、`--repeat 5` で全地点を回しても数十回。
