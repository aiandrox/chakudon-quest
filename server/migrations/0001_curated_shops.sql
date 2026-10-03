-- アプリに持たせる店（地図の検索で見つからないことのある店）。正本は data/curated_shops.json。
CREATE TABLE curated_shops (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  chain TEXT,
  status TEXT NOT NULL CHECK (status IN ('open', 'closed'))
);
