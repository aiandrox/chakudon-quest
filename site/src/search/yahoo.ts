import { type FoundShop, type GeoPoint, ramenName } from './shop.ts';

/** 業種コード「グルメ > ラーメン」。 */
const ramenGenre = '0106';
export const yahooAttribution = 'Web Services by Yahoo! JAPAN';

const base = 'https://map.yahooapis.jp/search/local/V1/localSearch';

export function buildYahooNearbyUrl(center: GeoPoint, radiusMeters: number, appId: string): string {
  const params = new URLSearchParams({
    appid: appId,
    lat: `${center.latitude}`,
    lon: `${center.longitude}`,
    dist: `${Math.min(Math.max(radiusMeters / 1000, 0.1), 20)}`,
    gc: ramenGenre,
    sort: 'dist',
    results: '100',
    output: 'json',
  });
  return `${base}?${params}`;
}

export function buildYahooNameUrl(name: string, appId: string, near?: GeoPoint): string {
  const params = new URLSearchParams({ appid: appId, query: name.trim(), gc: ramenGenre, results: '30', output: 'json' });
  if (near) {
    params.set('lat', `${near.latitude}`);
    params.set('lon', `${near.longitude}`);
    params.set('sort', 'dist');
  }
  return `${base}?${params}`;
}

/** 業種で絞ってもラーメンも出す居酒屋などが混ざるので、主な業種がラーメンか、名前がラーメン屋らしい店だけ残す。 */
function isRamenShop(name: string, property: any): boolean {
  if (ramenName.test(name)) return true;
  const genres = property?.Genre;
  if (!Array.isArray(genres) || genres.length === 0) return true;
  const code = genres[0]?.Code;
  return typeof code === 'string' && code.startsWith(ramenGenre);
}

export function parseYahooLocal(body: any): FoundShop[] {
  const features = body?.Feature ?? [];
  if (!Array.isArray(features)) throw new Error('Yahoo! の応答の Feature が読めません');
  const shops: FoundShop[] = [];
  for (const f of features) {
    const name = typeof f?.Name === 'string' ? f.Name.trim() : '';
    const [lon, lat] = typeof f?.Geometry?.Coordinates === 'string' ? f.Geometry.Coordinates.split(',').map(Number) : [];
    if (!name || !Number.isFinite(lat) || !Number.isFinite(lon)) continue;
    if (!isRamenShop(name, f.Property)) continue;
    const address = typeof f.Property?.Address === 'string' ? f.Property.Address.trim() : '';
    shops.push({
      name,
      latitude: lat,
      longitude: lon,
      address: address || undefined,
      dataSource: { licenses: [], attributions: [yahooAttribution] },
    });
  }
  return shops;
}
