# サイト更新 管理アプリ

Flutter製のWeb更新アプリ初期版。

## 対応予定

- iOS
- Web
- Android

## 初期版の機能

- `info` プラン: お知らせの表示、編集、確認、更新
- `info_image` プラン: お知らせ更新と、指定画像1枚の選択、確認、更新

画像更新UIは `info_image` プランのみ表示する。
API側でもプラン確認を行うため、`info` プランのユーザーは直接APIを叩いても画像更新できない。

## デモ起動

API未接続のデモモード:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

## API接続ありの起動

```sh
flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 8080 \
  --dart-define=API_BASE_URL=https://momoweb-update-api.adadashifuso.workers.dev \
  --dart-define=PUBLIC_SITE_URL=https://momoweb.pages.dev
```

API接続ありの場合、画面で更新キーを入力する。
デモ環境の更新キーは `demo-info-image-token`。

## 確認

```sh
flutter analyze
flutter test
flutter build web
```
