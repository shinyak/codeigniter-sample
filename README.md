# CodeIgniter 4 サンプルプロジェクト

## クイックスタート

前提：ホストPCに Docker, PHP, composer, mysqlクライアントがインストールされていること。

phpコンテナは外部へのアクセスを制限しているため、composer install はホストPCで実行します。

```bash
composer install
```

```bash
cp .env.development.sample .env
docker compose up -d --build
```

http://localhost:8080/
にアクセス

## Docker 開発環境

### クイックスタート

```bash
cp .env.local.sample .env

docker compose up -d --build
docker compose exec php composer install
./scripts/docker-post-up-init.sh

open http://localhost:8080
```

see [docker/README.md](docker/README.md)

## Docker起動後の初期化

`scripts/docker-post-up-init.sh` は以下を冪等に実行します。

- CI4 マイグレーション（テーブル作成）
- RustFS バケット作成（未作成時のみ）
- `docker/init/s3/` のファイルを S3 に同期
- `docker/init/ftp/` のファイルを `docker/ftp/volume/<FTP_USER_NAME>/` に同期（`rsync --delete`）
