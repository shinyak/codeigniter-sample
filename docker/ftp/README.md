# FTPメモ

`docker/ftp/passwd/pureftpd.passwd` は Pure-FTPd の仮想ユーザ定義ファイルです。  
このリポジトリの `testftp` 行は、実質的に以下の `pure-pw` コマンドで作られた形式です。

```bash
docker compose exec ftp pure-pw useradd testftp -u ftpuser -d /home/ftpusers/testftp -m
```

- `-m` を付けると `pureftpd.passwd` 更新と DB 再生成（`mkdb`）まで実行されます。
  なお、このコンテナは起動時にも `pureftpd.passwd` から `pureftpd.pdb` を再生成するため、通常は `pureftpd.passwd` の永続化だけで動作します。
- 対話式なので、実行後にパスワードを2回入力します。

## FTPユーザを追加する手順

1. ユーザ用ディレクトリを作成（ホスト側）

```bash
mkdir -p docker/ftp/volume/<username>
```

2. コンテナ内でユーザ追加（対話式）

```bash
docker compose exec ftp pure-pw useradd <username> -u ftpuser -d /home/ftpusers/<username> -m
```

3. 反映確認（任意）

```bash
docker compose exec ftp pure-pw list
```

## 非対話で追加する例（任意）

CI 等で非対話実行したい場合は次のように `stdin` でパスワードを渡せます。

```bash
printf '%s\n%s\n' '<password>' '<password>' \
  | docker compose exec -T ftp pure-pw useradd <username> -u ftpuser -d /home/ftpusers/<username> -m
```

## 補足

- `docker-compose.yml` の `FTP_USER_NAME` / `FTP_USER_PASS` / `FTP_USER_HOME` はコンテナ起動時の初期ユーザ用です。
- 追加ユーザは `docker/ftp/passwd/pureftpd.passwd` をボリュームマウントで永続化しています（`pureftpd.pdb` は起動時に再生成）。
