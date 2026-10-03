# 秘伝の一覧

アプリに出てくる秘伝（1回きりのクエスト）の印と内容の一覧。管理用。

- 定義は `lib/features/quests/quests.dart`。期間限定の秘伝も、期間が過ぎたら消さずに残す
- 秘伝を足したり変えたりしたら `flutter test --dart-define=UPDATE_HIDEN_CATALOG=true test/tool/hiden_catalog_test.dart` でこの一覧と印の画像を作り直す
- 印の日付は見本（2026/10/3）

| 印 | 名前 | 会得の条件 | 字 | 形 | 期間 | ID |
|---|---|---|---|---|---|---|
| <img src="first_bowl.png" width="72"> | はじめての着丼 | 最初の1杯を記録する | 初 | 二重丸 | いつでも | `first_bowl` |
| <img src="queue_60.png" width="72"> | 60分の試練 | 60分以上並んで食べる | 忍 | 角 | いつでも | `queue_60` |
| <img src="queue_90.png" width="72"> | 90分の死闘 | 90分以上並んで食べる | 闘 | 八角形 | いつでも | `queue_90` |
| <img src="double_bowl.png" width="72"> | 一日二杯 | 同じ日に2杯食べる | 双 | 菱形 | いつでも | `double_bowl` |
| <img src="third_time.png" width="72"> | 三度目の正直 | 同じ店で2回撤退したあと、その店で食べる | 三 | 六角形 | いつでも | `third_time` |
| <img src="styles.png" width="72"> | 系統の探究 | 「その他」を除く8系統をすべて食べる | 全 | 8つの丸の輪 | いつでも | `styles` |
| <img src="rare_shop.png" width="72"> | 幻の店 | 営業の条件（アクセスの悪さは除く）が2つ以上ある店で食べる | 幻 | 花 | いつでも | `rare_shop` |
| <img src="home_base.png" width="72"> | 拠点を構える | 同じ地域（2km以内）で5杯食べて、拠点をつくる | 城 | 城壁 | いつでも | `home_base` |
| <img src="long_wish.png" width="72"> | 百日越しの願 | 願を掛けてから100日以上たって、その店で食べる | 願 | 点の輪 | いつでも | `long_wish` |
