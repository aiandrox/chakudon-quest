// data/curated_shops.json から、D1 の中身を入れ替える SQL を作る（GitHub Actions で使う）。
import { readFileSync } from 'node:fs';
import { buildSeedSql } from '../src/seed.ts';

const path = process.argv[2];
if (!path) throw new Error('使い方: node scripts/build-seed.mjs <curated_shops.json>');
process.stdout.write(buildSeedSql(JSON.parse(readFileSync(path, 'utf8'))));
