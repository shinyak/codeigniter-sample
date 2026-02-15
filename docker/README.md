# Docker 開発環境

PHPアプリケーションではMySQL以外に複数の外部連携があり、これらはの連携はdocker仮想環境内のスタブサーバーで受け、外部に影響しないようにする。

PHPコンテナンの network を `internal: true` と設定することにより外部へのアクセスを制限している。

- FTP
- S3
- メール

## 起動方法

1. `.env.local.sample` を `.env` にコピーする
2. コンテナをビルドし、起動する:

   ```bash
   docker compose up -d --build
   ```

3. 依存ライブラリをインストールする

   ```bash
   docker compose exec php composer install
   ```

## アクセス方法

| サービス | アクセス方法 | 説明 | ID/パスワード |
| --- | --- | --- | --- |
| Web | http://localhost:8080 | CodeIgniter 4 アプリケーション | - |
| MySQL | localhost:3306 | MySQL データベース | root/secret , ci4/ci4secret |
| RustFS コンソール | http://localhost:9001 | S3 互換ストレージの管理コンソール | rustfsadmin/rustfsadmin |
| Mailpit コンソール | http://localhost:8025 | メール受信確認用の管理コンソール | - |

パスワード等は `.env` に書かれたものを使用します。

## 動作確認

[docs/Docker環境起動後の動作確認.md](docs/Docker環境起動後の動作確認.md) を参照してください。
