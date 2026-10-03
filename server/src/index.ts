import { type CuratedShop, etagOf } from './curated.ts';

export interface Env {
  DB: D1Database;
}

const json = (body: unknown, init: ResponseInit = {}) =>
  new Response(JSON.stringify(body), {
    ...init,
    headers: { 'content-type': 'application/json; charset=utf-8', ...init.headers },
  });

/** アプリに持たせる店の一覧（閉店も含む。アプリは閉店した店を候補から外す）。 */
export async function curatedShops(request: Request, shops: CuratedShop[]): Promise<Response> {
  const etag = await etagOf(shops);
  const headers = {
    etag,
    // アプリは1日1回までしか取りに来ないが、端の cache にも1時間ためる。
    'cache-control': 'public, max-age=3600',
  };
  if (request.headers.get('if-none-match') === etag) {
    return new Response(null, { status: 304, headers });
  }
  return json({ shops }, { headers });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method !== 'GET') return json({ error: 'method not allowed' }, { status: 405 });
    if (url.pathname === '/v1/curated-shops') {
      const { results } = await env.DB.prepare(
        'SELECT id, name, address, latitude, longitude, chain, status FROM curated_shops ORDER BY id',
      ).all<CuratedShop>();
      return curatedShops(request, results);
    }
    return json({ error: 'not found' }, { status: 404 });
  },
} satisfies ExportedHandler<Env>;
