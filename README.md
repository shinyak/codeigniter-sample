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

open http://localhost:8080
```

see [docker/README.md](docker/README.md)
