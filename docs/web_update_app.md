# Web更新アプリ 初期版

## 置き場所

- `admin_app/`: Flutter管理アプリ本体
- `workers/web_update_api/`: Cloudflare Workers API
- `shared/web_update_widget/`: 顧客サイトに埋め込む表示用JavaScript
- `web_sample/update_admin_demo/`: お客様に見せるデモページ

## 初期版の対象

### プラン1: `info`

- 現在のお知らせを表示
- お知らせを編集
- 更新前に内容確認
- 更新

### プラン2: `info_image`

- `info` の機能
- 指定された画像枠を1枚だけ更新

## 認可

画面側では `info` プランのユーザーに画像更新UIを表示しない。
API側でも `/admin/image` 実行時にサイトの `plan` を確認し、`info_image` 以外は `403` を返す。

ログインユーザーは `users.customer_id` と `users.site_id` に紐付いた `sites` のみ更新できる。
別顧客の `site_id` を指定して更新するAPIは初期版では用意しない。

## Cloudflare構成

- Cloudflare Pages: 静的サイト
- Cloudflare Workers: 更新API
- Cloudflare D1: 顧客・ユーザー・サイト・INFO・プラン
- Cloudflare R2: 更新画像

## 顧客サイトへの埋め込み例

```html
<p data-update-info>本日は通常通り営業しています。</p>
<img data-update-image src="./assets/image/default.jpg" alt="">

<script
  src="/shared/web_update_widget/site-content.js"
  data-api-base="https://momoweb-update-api.example.workers.dev"
  data-site-id="roman-demo"
  data-info-target="[data-update-info]"
  data-image-target="[data-update-image]"
></script>
```

APIが落ちている場合は、HTMLに書いた初期表示をそのまま見せる。
