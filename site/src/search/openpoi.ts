import { type FoundShop, type GeoPoint, ramenName } from './shop.ts';

/** 1語ずつ別に探して結果をまとめる（アプリの openPoiKeywords と同じ理由）。 */
export const openPoiKeywords = ['ラーメン', 'らぁ麺', '中華そば', 'つけ麺', 'まぜそば', '油そば', '麺屋'];

const notRamenNameParts = ['洋麺', 'パスタ', 'スパゲッティ'];
const minGeocodingLevel = 8;
const foodCategories = new Set(['restaurant', 'fast_food', 'food_court', 'unknown']);

export function buildOpenPoiUrl(center: GeoPoint, keyword: string, radiusMeters: number): string {
  const params = new URLSearchParams({
    q: keyword,
    center: `${center.longitude},${center.latitude}`,
    radius: `${radiusMeters}`,
    limit: '100',
  });
  return `https://api.openpoiapi.com/v1/search?${params}`;
}

export function buildOpenPoiNameUrl(name: string, near?: GeoPoint): string {
  const params = new URLSearchParams({ q: name.trim(), limit: '20' });
  if (near) {
    params.set('center', `${near.longitude},${near.latitude}`);
    params.set('radius', '2000000');
  }
  return `https://api.openpoiapi.com/v1/suggest?${params}`;
}

const strings = (value: unknown) => (Array.isArray(value) ? value.filter((v) => typeof v === 'string') : []);

function parseShops(body: any, key: string, foodOnly: boolean): FoundShop[] {
  const results = body?.[key];
  if (!Array.isArray(results)) throw new Error(`OpenPOI の応答に ${key} がありません`);
  const shops: FoundShop[] = [];
  for (const r of results) {
    if (foodOnly && typeof r?.category === 'string' && !foodCategories.has(r.category)) continue;
    const name = typeof r?.name === 'string' ? r.name.trim() : '';
    if (!name || notRamenNameParts.some((part) => name.includes(part))) continue;
    if (typeof r.lat !== 'number' || typeof r.lng !== 'number') continue;
    if (typeof r.level === 'number' && r.level < minGeocodingLevel) continue;
    const address =
      (typeof r.address === 'string' && r.address.trim()) ||
      `${typeof r.prefecture === 'string' ? r.prefecture.trim() : ''}${typeof r.city === 'string' ? r.city.trim() : ''}`;
    shops.push({
      name,
      latitude: r.lat,
      longitude: r.lng,
      address: address || undefined,
      dataSource: { licenses: strings(r.licenses), attributions: strings(r.attributions) },
    });
  }
  return shops;
}

export const parseOpenPoiResponse = (body: any) => parseShops(body, 'results', false);

/** 店名の結果。飲食店でない施設を除き、名前がラーメン屋らしい店を先に並べる。 */
export function parseOpenPoiNameResults(body: any): FoundShop[] {
  const shops = parseShops(body, 'suggestions', true);
  const ramen = shops.filter((s) => ramenName.test(s.name));
  return [...ramen, ...shops.filter((s) => !ramen.includes(s))];
}
