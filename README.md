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

### クイックスタート

```bash
cp .env.local.sample .env

docker compose up -d --build
docker compose exec php composer install

open http://localhost:8080
```

see [docker/README.md](docker/README.md)
