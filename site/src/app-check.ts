import { type JWTVerifyGetKey, createRemoteJWKSet, jwtVerify } from 'jose';

/** Firebase プロジェクト ramen-in-cho のプロジェクト番号。 */
export const firebaseProjectNumber = '452252955491';

const firebaseJwks = createRemoteJWKSet(new URL('https://firebaseappcheck.googleapis.com/v1/jwks'));

export type AppCheckResult = 'ok' | 'missing' | 'invalid';

/** `X-Firebase-AppCheck` のトークンが、このプロジェクトのアプリが発行したものか確かめる。 */
export async function verifyAppCheck(
  token: string | null,
  keys: JWTVerifyGetKey = firebaseJwks,
  projectNumber = firebaseProjectNumber,
): Promise<AppCheckResult> {
  if (!token) return 'missing';
  try {
    await jwtVerify(token, keys, {
      algorithms: ['RS256'],
      typ: 'JWT',
      issuer: `https://firebaseappcheck.googleapis.com/${projectNumber}`,
      audience: `projects/${projectNumber}`,
    });
    return 'ok';
  } catch {
    return 'invalid';
  }
}
