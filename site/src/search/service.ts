import type { CuratedShop } from '../curated.ts';
import { buildOpenPoiNameUrl, buildOpenPoiUrl, openPoiKeywords, parseOpenPoiNameResults, parseOpenPoiResponse } from './openpoi.ts';
import { buildOverpassQuery, parseOverpassResponse } from './overpass.ts';
import {
  type FoundShop,
  type GeoPoint,
  distanceMeters,
  mergeFoundShops,
  nameQueryVariants,
  normalizeShopName,
} from './shop.ts';
import { buildYahooNameUrl, buildYahooNearbyUrl, parseYahooLocal } from './yahoo.ts';

export interface SearchDeps {
  fetch: typeof fetch;
  /** 検索結果のため置き（Cache API）。テストでは Map で差し替える。 */
  cache: Pick<Cache, 'match' | 'put'>;
  yahooAppId?: string;
}

const userAgent = 'ramen-in-cho (https://github.com/aiandrox/ramen-in-cho)';
const upstreamTimeoutMs = 10_000;

/** 検索結果をためておく長さ。店はそう変わらないので1週間。どれかの検索が失敗したときは1日だけ。 */
export const cacheSeconds = 7 * 24 * 60 * 60;
export const partialCacheSeconds = 24 * 60 * 60;

/** 近くの店のため置きのマス目（緯度経度 0.003 度 ≒ 300m）。マスの中心から少し広めに探し、問い合わせの中心で絞る。 */
export const cellDegrees = 0.003;
const cellMarginMeters = 250;

async function getJson(deps: SearchDeps, url: string, init: RequestInit = {}): Promise<any> {
  const response = await deps.fetch(url, {
    ...init,
    headers: { 'user-agent': userAgent, ...init.headers },
    signal: AbortSignal.timeout(upstreamTimeoutMs),
  });
  if (!response.ok) throw new Error(`${new URL(url).host}: HTTP ${response.status}`);
  return response.json();
}

/** 各検索を同時に呼び、失敗したものは null にする。 */
async function attempt(search: () => Promise<FoundShop[]>): Promise<FoundShop[] | null> {
  try {
    return await search();
  } catch (e) {
    console.log(`search failed: ${e}`);
    return null;
  }
}

interface Upstream {
  shops: FoundShop[];
  complete: boolean;
}

async function upstreamNearby(deps: SearchDeps, center: GeoPoint, radiusMeters: number): Promise<Upstream> {
  const appId = deps.yahooAppId;
  const [osm, yahoo, ...poi] = await Promise.all([
    attempt(async () =>
      parseOverpassResponse(
        await getJson(deps, 'https://overpass-api.de/api/interpreter', {
          method: 'POST',
          headers: { 'content-type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({ data: buildOverpassQuery(center, radiusMeters) }).toString(),
        }),
      ),
    ),
    appId ? attempt(async () => parseYahooLocal(await getJson(deps, buildYahooNearbyUrl(center, radiusMeters, appId)))) : null,
    ...openPoiKeywords.map((keyword) =>
      attempt(async () => parseOpenPoiResponse(await getJson(deps, buildOpenPoiUrl(center, keyword, radiusMeters)))),
    ),
  ]);
  const poiShops = mergeFoundShops([], poi.flatMap((shops) => shops ?? []));
  if (osm === null && yahoo === null && poi.every((shops) => shops === null)) {
    throw new Error('店の検索がすべて失敗しました');
  }
  return {
    // OpenStreetMap の店を優先し（ID があるため）、次に Yahoo!、最後に OpenPOI。
    shops: mergeFoundShops(osm ?? [], [...(yahoo ?? []), ...poiShops]),
    complete: osm !== null && (yahoo !== null || !appId) && poi.every((shops) => shops !== null),
  };
}

const cacheUrl = (path: string, params: Record<string, string>) =>
  `https://cache.ramen-in-cho.internal/${path}?${new URLSearchParams(params)}`;

/** ため置きにあればそれを、無ければ [load] して ため置く。 */
async function cached(deps: SearchDeps, key: string, load: () => Promise<Upstream>): Promise<FoundShop[]> {
  const hit = await deps.cache.match(key);
  if (hit) return (await hit.json()) as FoundShop[];
  const { shops, complete } = await load();
  await deps.cache.put(
    key,
    new Response(JSON.stringify(shops), {
      headers: {
        'content-type': 'application/json',
        'cache-control': `public, max-age=${complete ? cacheSeconds : partialCacheSeconds}`,
      },
    }),
  );
  return shops;
}

const curatedFound = (shop: CuratedShop): FoundShop => ({
  name: shop.name,
  latitude: shop.latitude,
  longitude: shop.longitude,
  address: shop.address,
});

/** [center] から [radiusMeters] 以内の店。手で持つ店は通信できなくても出す。 */
export async function searchNearby(
  deps: SearchDeps,
  curated: CuratedShop[],
  center: GeoPoint,
  radiusMeters: number,
): Promise<FoundShop[]> {
  const near = (shop: GeoPoint) => distanceMeters(center, shop) <= radiusMeters;
  const curatedNear = curated.filter((s) => s.status === 'open' && near(s)).map(curatedFound);
  const lat = Math.round(center.latitude / cellDegrees);
  const lon = Math.round(center.longitude / cellDegrees);
  const cell = { latitude: lat * cellDegrees, longitude: lon * cellDegrees };
  let found: FoundShop[];
  try {
    found = await cached(deps, cacheUrl('nearby/v1', { cell: `${lat},${lon}`, r: `${radiusMeters}` }), () =>
      upstreamNearby(deps, cell, radiusMeters + cellMarginMeters),
    );
  } catch (e) {
    if (curatedNear.length > 0) return curatedNear;
    throw e;
  }
  const inRange = found.filter(near);
  return mergeFoundShops(
    inRange.filter((s) => s.osmId),
    [...curatedNear, ...inRange.filter((s) => !s.osmId)],
  );
}

/** 手で持つ店を名前で探す（アプリの builtinShopsNamed と同じ合わせ方）。近い順に5件まで。 */
export function curatedNamed(curated: CuratedShop[], query: string, near?: GeoPoint, limit = 5): FoundShop[] {
  const words = query.replaceAll('　', ' ').split(' ').map(normalizeShopName).filter(Boolean);
  if (words.length === 0) return [];
  const joined = words.join('');
  const appearsInOrder = (name: string) => {
    let from = 0;
    for (const ch of joined) {
      const index = name.indexOf(ch, from);
      if (index < 0) return false;
      from = index + ch.length;
    }
    return true;
  };
  const matched = curated.filter((shop) => {
    if (shop.status !== 'open') return false;
    const name = normalizeShopName(shop.name);
    return words.every((w) => name.includes(w)) || appearsInOrder(name);
  });
  if (near) matched.sort((a, b) => distanceMeters(near, a) - distanceMeters(near, b));
  return matched.slice(0, limit).map(curatedFound);
}

/** 店名で全国から探す。空白の有無で結果が変わるので、空白を詰めた言葉でも探してまとめる。 */
export async function searchByName(
  deps: SearchDeps,
  curated: CuratedShop[],
  query: string,
  near?: GeoPoint,
): Promise<FoundShop[]> {
  const variants = nameQueryVariants(query);
  if (variants.length === 0) return [];
  const fromCurated = curatedNamed(curated, query, near);
  // 先の検索には 0.1 度（約10km）に丸めた場所を渡してため置き、並びは最後に本当の場所からの近さで決める。
  const area = near ? `${Math.round(near.latitude * 10)},${Math.round(near.longitude * 10)}` : '';
  const anchor = near ? { latitude: Math.round(near.latitude * 10) / 10, longitude: Math.round(near.longitude * 10) / 10 } : undefined;
  let found: FoundShop[];
  try {
    found = await cached(deps, cacheUrl('search/v2', { q: variants[0], area }), async () => {
      const appId = deps.yahooAppId;
      const [yahoo, poi] = await Promise.all([
        appId
          ? Promise.all(
              variants.map((v) =>
                attempt(async () => parseYahooLocal(await getJson(deps, buildYahooNameUrl(v, appId, anchor)))),
              ),
            )
          : Promise.resolve([]),
        Promise.all(
          variants.map((v) =>
            attempt(async () => parseOpenPoiNameResults(await getJson(deps, buildOpenPoiNameUrl(v, anchor)))),
          ),
        ),
      ]);
      const all = [...yahoo, ...poi];
      if (all.every((r) => r === null)) throw new Error('店名の検索がすべて失敗しました');
      // 同じ店なら、ラーメン店の業種で絞れる Yahoo! のほうを残す。
      return {
        shops: mergeFoundShops([], [...yahoo.flatMap((r) => r ?? []), ...poi.flatMap((r) => r ?? [])]),
        complete: all.every((r) => r !== null),
      };
    });
  } catch (e) {
    if (fromCurated.length > 0) return fromCurated;
    throw e;
  }
  const shops = mergeFoundShops(fromCurated, found);
  if (near) shops.sort((a, b) => distanceMeters(near, a) - distanceMeters(near, b));
  return shops;
}
