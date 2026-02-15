# RustFS (S3 代替)

このディレクトリは RustFS コンテナの永続データを保持します。

- `data/`: オブジェクトデータ
- `logs/`: RustFS ログ

補足:
- RustFS コンテナは `UID 10001` で動作します。環境によっては権限エラーになるため、その場合はホスト側ディレクトリの所有者を `10001:10001` に変更してください。
- WebUI (RustFS Console) はホストPCブラウザから `http://localhost:9001` でアクセスします。

## WebUI (RustFS Console)

- URL: `http://localhost:9001`
- ログイン: `S3_ACCESS_KEY` / `S3_SECRET_KEY`（デフォルトは `rustfsadmin` / `rustfsadmin`）
- 前提: `docker-compose.yml` で `rustfs` の `9001` がホストへ `ports` 公開されていること。

## テスト用バケット作成 (AWS CLI互換)

前提:
- `docker compose up -d rustfs` 済み
- 認証情報は `docker-compose.yml` の `S3_ACCESS_KEY` / `S3_SECRET_KEY` を使用
- `php` コンテナに `aws` コマンド導入済み

バケット作成例 (`sample-bucket`):

```bash
docker compose exec php sh -lc '
AWS_ACCESS_KEY_ID=${S3_ACCESS_KEY:-rustfsadmin} \
AWS_SECRET_ACCESS_KEY=${S3_SECRET_KEY:-rustfsadmin} \
AWS_DEFAULT_REGION=${S3_REGION:-us-east-1} \
aws --endpoint-url "${S3_ENDPOINT:-http://rustfs:9000}" \
  --no-cli-pager \
  s3api create-bucket --bucket sample-bucket
'
```

作成確認:

```bash
docker compose exec php sh -lc '
AWS_ACCESS_KEY_ID=${S3_ACCESS_KEY:-rustfsadmin} \
AWS_SECRET_ACCESS_KEY=${S3_SECRET_KEY:-rustfsadmin} \
AWS_DEFAULT_REGION=${S3_REGION:-us-east-1} \
aws --endpoint-url "${S3_ENDPOINT:-http://rustfs:9000}" \
  --no-cli-pager \
  s3api list-buckets
'
```

## PHP側のS3クライアント設定

`aws/aws-sdk-php` を使う例。RustFS は S3互換なので `endpoint` と `use_path_style_endpoint` を明示する。

1. SDKをインストール

```bash
docker compose exec php composer require aws/aws-sdk-php
```

2. `.env` に設定

```dotenv
S3_ENDPOINT = 'http://rustfs:9000'
S3_ACCESS_KEY = 'rustfsadmin'
S3_SECRET_KEY = 'rustfsadmin'
S3_REGION = 'us-east-1'
S3_BUCKET = 'sample-bucket'
```

3. クライアント生成例 (`app/Config/Services.php` など)

```php
<?php

use Aws\S3\S3Client;

$s3 = new S3Client([
    'version' => 'latest',
    'region' => env('S3_REGION', 'us-east-1'),
    'endpoint' => env('S3_ENDPOINT'),
    'use_path_style_endpoint' => true,
    'credentials' => [
        'key' => env('S3_ACCESS_KEY'),
        'secret' => env('S3_SECRET_KEY'),
    ],
]);
```

4. アップロード例

```php
<?php

$s3->putObject([
    'Bucket' => env('S3_BUCKET'),
    'Key' => 'test/hello.txt',
    'Body' => "hello from php\n",
    'ContentType' => 'text/plain',
]);
```

## 強制初期化 (ホスト側で全データ削除)

バケットやオブジェクトを含めて RustFS を完全に初期状態へ戻す手順。

```bash
# 1) RustFS停止
docker compose stop rustfs

# 2) データ/ログ削除（全バケット・全オブジェクト消去）
# .rustfs.sys のような隠しファイル/隠しディレクトリも削除する
find docker/rustfs/data -mindepth 1 -delete
find docker/rustfs/logs -mindepth 1 -delete

# 3) 必要なら権限を戻す
# sudo chown -R 10001:10001 docker/rustfs/data docker/rustfs/logs

# 4) RustFS再起動
docker compose up -d rustfs
```

確認:

```bash
docker compose logs --tail=50 rustfs
```
