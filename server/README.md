# chakudon-quest-api

着丼クエストの店のデータと検索を受け持つ Cloudflare Workers。設計と進み具合は issue #172。
記録・写真・位置の履歴は受け取らない。

## API

| 道 | 中身 |
|---|---|
| `GET /v1/curated-shops` | アプリに持たせる店の一覧（閉店も含む）。`ETag` 付きで、`If-None-Match` が同じなら 304 |

## 店のデータを直す

1. `../data/curated_shops.json` を直して PR を出す（閉店は消さずに `"status": "closed"`）
2. マージすると GitHub Actions（Server Deploy）が D1 を正本どおりに入れ替える

アプリに同梱している一覧（`lib/features/shop_search/builtin_shops.dart`）も同じ中身にする（テストで確かめる）。

## はじめの設定（一度だけ）

1. Cloudflare にログインして D1 を作る: `npx wrangler d1 create chakudon-quest`
2. 出てきた `database_id` を `wrangler.toml` に書く
3. GitHub の Settings → Secrets に `CLOUDFLARE_API_TOKEN`（Workers と D1 を編集できるトークン）と `CLOUDFLARE_ACCOUNT_ID` を入れる
4. Actions の Server Deploy を手で動かす（workflow_dispatch）

## 手元で

```bash
npm ci
npm test          # テスト
npm run typecheck # 型の確認
npm run seed      # 正本から D1 に入れる SQL（seed.sql）を作る
npx wrangler dev  # 手元で動かす（--local の D1 を使う）
```
