# ramen-in-cho（着丼クエストの紹介ページと API）

Cloudflare Pages の1つのプロジェクトに、紹介ページ（`public/`）と API（`functions/`、Pages Functions）を置く。
公開先は https://ramen-in-cho.aiandrox.com 。設計と進み具合は issue #172。記録・写真・位置の履歴は受け取らない。

## API

| 道 | 中身 |
|---|---|
| `GET /api/v1/curated-shops` | アプリに持たせる店の一覧（閉店も含む）。`ETag` 付きで、`If-None-Match` が同じなら 304 |

## 店のデータを直す

1. `../data/curated_shops.json` を直して PR を出す（閉店は消さずに `"status": "closed"`）
2. マージすると GitHub Actions（Site Deploy）が D1 を正本どおりに入れ替えてデプロイする

アプリに同梱している一覧（`lib/features/shop_search/builtin_shops.dart`）も同じ中身にする（テストで確かめる）。

## はじめの設定（一度だけ）

1. Cloudflare にログイン: `npx wrangler login`
2. D1 を作る: `npx wrangler d1 create chakudon-quest` → 出てきた `database_id` を `wrangler.toml` に書く
3. Pages のプロジェクトを作る: `npx wrangler pages project create ramen-in-cho --production-branch main`
4. 独自ドメイン: ダッシュボード → Workers & Pages → ramen-in-cho → Custom domains に `ramen-in-cho.aiandrox.com` を足し、aiandrox.com の DNS に案内どおりの CNAME を足す
5. GitHub の Settings → Secrets に `CLOUDFLARE_API_TOKEN`（Pages と D1 を編集できるトークン）と `CLOUDFLARE_ACCOUNT_ID` を入れる
6. Actions の Site Deploy を手で動かす（workflow_dispatch）

D1 のつなぎ（`DB`）は `wrangler.toml` に書いてあるので、デプロイのときに Pages に反映される。

## 手元で

```bash
npm ci
npm test          # テスト
npm run typecheck # 型の確認
npm run seed      # 正本から D1 に入れる SQL（seed.sql）を作る
npx wrangler pages dev  # 手元で動かす（--local の D1 を使う）
```
