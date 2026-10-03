import { type Env, curatedShops, loadCuratedShops } from '../../../src/http.ts';

export const onRequestGet: PagesFunction<Env> = async ({ request, env }) =>
  curatedShops(request, await loadCuratedShops(env.DB));
