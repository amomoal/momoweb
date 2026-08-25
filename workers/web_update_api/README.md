# momoweb update API

Cloudflare Workers / D1 / R2 で動かす、Web更新アプリ用API。

Production URL:

```text
https://momoweb-update-api.adadashifuso.workers.dev
```

## 初期版のAPI

- `GET /admin/content`: ログインユーザーに紐付くサイトの現在内容
- `PUT /admin/info`: お知らせ更新
- `PUT /admin/image`: 画像1枚更新。`info_image` プランのみ許可
- `PUT /admin/image-position`: 画像の表示位置・拡大率更新。`info_image` プランのみ許可
- `GET /public/sites/:siteId/content`: 顧客サイト表示用の公開取得
- `GET /public/sites/:siteId/image`: 顧客サイト表示用の公開画像

## ローカル確認

```sh
npm test
```

## Cloudflare側で作るもの

1. D1 database: `momoweb-update-db`
2. R2 bucket: `momoweb-update-images`
3. Worker: `momoweb-update-api`

`wrangler.toml` の `database_id` は、D1作成後に実IDへ差し替える。

R2が未有効の場合、`wrangler r2 bucket create` は以下のエラーで止まる。

```text
Please enable R2 through the Cloudflare Dashboard. [code: 10042]
```

この場合はCloudflare DashboardでR2を開き、初回セットアップを完了してからbucketを作成する。

## デモ用トークン

`migrations/0002_demo_seed.sql` は以下のBearer tokenを登録する。

```text
demo-info-image-token
```

実運用では顧客ごとに別トークンを発行し、平文ではなくSHA-256ハッシュを `users.token_hash` に保存する。

## 画像枠比率

画像枠の比率はお客様には変更させず、サイト設定として固定する。
管理アプリではこの比率を固定フレームとして表示し、ユーザーは画像側をドラッグ・ピンチして表示位置と拡大率を調整する。

例: 3:4

```sql
UPDATE sites
SET image_aspect_width = 3,
    image_aspect_height = 4
WHERE id = 'roman-demo';
```

画像の表示調整値は以下を保存する。

- `image_crop_scale`: 固定フレームに対する拡大率
- `image_crop_offset_x`: 固定フレーム幅に対する左右移動率
- `image_crop_offset_y`: 固定フレーム高さに対する上下移動率

例: 正方形

```sql
UPDATE sites
SET image_aspect_width = 1,
    image_aspect_height = 1
WHERE id = 'roman-demo';
```

## 管理アプリとの接続

Flutter WebをAPI接続ありでビルドする場合:

```sh
flutter build web \
  --dart-define=API_BASE_URL=https://momoweb-update-api.adadashifuso.workers.dev
```

`API_BASE_URL` を渡さない場合、管理アプリはローカルのデモモードで動く。
`API_BASE_URL` を渡した公開版では、画面で更新キーを入力する。
