# CodeIgniter 4 サンプルプロジェクト

## クイックスタート

```
cp .env.local.sample .env
docker compose up -d --build
docker compose exec php composer install
```

http://localhost:8080/
にアクセス

## Docker 開発環境

### 起動方法

このリポジトリでは PHP-FPM + Nginx + MySQL によるローカル環境を利用できます。

1. `.env.local.sample` を `.env` にコピーする
2. コンテナをビルドし、起動する:

   ```bash
   docker compose up -d --build
   ```

3. 依存ライブラリをインストールする

   ```bash
   docker compose exec php composer install
   ```

Webは `http://localhost:8080` でアクセスできます。
MySQL は `localhost:3306` でアクセスできます。
パスワード等は `.env` に書かれたものを使用します。
