# Docker 開発環境

## 起動方法

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
RustFSコンソールは `http://localhost:9001` でアクセスできます。
パスワード等は `.env` に書かれたものを使用します。

## 動作確認

### 前提
```
docker compose up -d --build

docker compose exec php composer install
```

が完了していること。

### 確認手順

1. CodeIgniter 4 が動作していることを確認する

   ブラウザで `http://localhost:8080/` を開き、CodeIgniter 4 のウェルカムページが表示されることを確認します。

2. ホストPCから root で MySQL 接続できることを確認する

   ```bash
   mysql -h 127.0.0.1 -P "${MYSQL_PORT:-3306}" -u root -p"${MYSQL_ROOT_PASSWORD:-secret}" -e "SELECT 1;"
   ```

   `1` が返れば接続成功です。  
   （ホストに `mysql` クライアントがない場合は `docker compose exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-secret}" -e "SELECT 1;"` でも確認できます）

3. php サーバーから ci4 ユーザーで MySQL 接続できることを確認する

   ```bash
   docker compose exec php php -r '
   mysqli_report(MYSQLI_REPORT_OFF);
   $db = new mysqli("mysql", getenv("MYSQL_USER") ?: "ci4", getenv("MYSQL_PASSWORD") ?: "ci4secret", getenv("MYSQL_DATABASE") ?: "ci4", 3306);
   if ($db->connect_errno) { fwrite(STDERR, "NG: {$db->connect_error}\n"); exit(1); }
   $res = $db->query("SELECT CURRENT_USER() u, DATABASE() d");
   $row = $res->fetch_assoc();
   echo "OK user={$row["u"]} db={$row["d"]}\n";
   '
   ```

   `OK user=... db=...` が表示されれば接続成功です。

4. ホストPCから RustFS コンソールにログインできることを確認する

   1. ブラウザで `http://localhost:9001` を開く  
   2. `S3_ACCESS_KEY` / `S3_SECRET_KEY`（デフォルト: `rustfsadmin` / `rustfsadmin`）でログインする

5. php サーバーから `aws` コマンドで RustFS にアクセスできることを確認する

   ```bash
   docker compose exec php sh -lc '
   AWS_ACCESS_KEY_ID=${S3_ACCESS_KEY:-rustfsadmin} \
   AWS_SECRET_ACCESS_KEY=${S3_SECRET_KEY:-rustfsadmin} \
   AWS_DEFAULT_REGION=${S3_REGION:-us-east-1} \
   aws --endpoint-url "${S3_ENDPOINT:-http://rustfs:9000}" --no-cli-pager s3 ls
   '
   ```

   エラーなく実行できれば接続成功です（バケット未作成でも正常）。

6. php サーバーから FTP サーバーにアップロード/ダウンロードできることを確認する

   ```bash
   docker compose exec php php -r '
   $host = "ftp";
   $user = getenv("FTP_USER_NAME") ?: "testftp";
   $pass = getenv("FTP_USER_PASS") ?: "testftp";
   $remote = "probe.txt";
   $localUp = "/tmp/ftp-up.txt";
   $localDown = "/tmp/ftp-down.txt";
   file_put_contents($localUp, "ftp upload test\n");
   $ftp = ftp_connect($host, 21, 10);
   if (!$ftp) { fwrite(STDERR, "NG: connect failed\n"); exit(1); }
   if (!ftp_login($ftp, $user, $pass)) { fwrite(STDERR, "NG: login failed\n"); exit(1); }
   ftp_pasv($ftp, true);
   if (!ftp_put($ftp, $remote, $localUp, FTP_ASCII)) { fwrite(STDERR, "NG: upload failed\n"); exit(1); }
   if (!ftp_get($ftp, $localDown, $remote, FTP_ASCII)) { fwrite(STDERR, "NG: download failed\n"); exit(1); }
   $u = trim(file_get_contents($localUp));
   $d = trim(file_get_contents($localDown));
   echo ($u === $d) ? "OK ftp upload/download\n" : "NG: content mismatch\n";
   ftp_close($ftp);
   '
   ```

   `OK ftp upload/download` が表示されれば成功です。
