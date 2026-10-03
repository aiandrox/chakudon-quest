import { verifyAppCheck } from '../../src/app-check.ts';
import { type Env, json } from '../../src/http.ts';

/** アプリ以外からの呼び出しを見分ける。`APP_CHECK_ENFORCE` が "true" になるまでは記録だけして通す。 */
export const onRequest: PagesFunction<Env> = async ({ request, env, next }) => {
  const result = await verifyAppCheck(request.headers.get('x-firebase-appcheck'));
  if (result !== 'ok') {
    console.log(`app check: ${result}`);
    if (env.APP_CHECK_ENFORCE === 'true') return json({ error: 'アプリからの問い合わせではありません' }, { status: 401 });
  }
  return next();
};
