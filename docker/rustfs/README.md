# RustFS (S3 代替)

このディレクトリは RustFS コンテナの永続データを保持します。

- `data/`: オブジェクトデータ
- `logs/`: RustFS ログ

補足:
- RustFS コンテナは `UID 10001` で動作します。環境によっては権限エラーになるため、その場合はホスト側ディレクトリの所有者を `10001:10001` に変更してください。

## テスト用バケット作成 (AWS CLI互換)

前提:
- `docker compose up -d rustfs` 済み
- 認証情報は `docker-compose.yml` の `S3_ACCESS_KEY` / `S3_SECRET_KEY` を使用
- RustFS は `private` ネットワーク内なので、AWS CLIは同じネットワーク上のコンテナで実行する

バケット作成例 (`sample-bucket`):

```bash
docker run --rm \
  --network codeigniter-sample_private \
  -e AWS_ACCESS_KEY_ID=rustfsadmin \
  -e AWS_SECRET_ACCESS_KEY=rustfsadmin \
  -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli:2.17.33 \
  --endpoint-url http://rustfs:9000 \
  s3api create-bucket --bucket sample-bucket
```

作成確認:

```bash
docker run --rm \
  --network codeigniter-sample_private \
  -e AWS_ACCESS_KEY_ID=rustfsadmin \
  -e AWS_SECRET_ACCESS_KEY=rustfsadmin \
  -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli:2.17.33 \
  --endpoint-url http://rustfs:9000 \
  s3api list-buckets
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
