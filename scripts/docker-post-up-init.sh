#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

S3_LOCAL_DIR="${ROOT_DIR}/docker/init/s3"
FTP_LOCAL_DIR="${ROOT_DIR}/docker/init/ftp"
FTP_VOLUME_DIR="${ROOT_DIR}/docker/ftp/volume"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found" >&2
  exit 1
fi

get_env_value() {
  local key="$1"
  local default="$2"

  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "${default}"
    return
  fi

  local line
  line="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "${ENV_FILE}" | tail -n1 || true)"
  if [[ -z "${line}" ]]; then
    echo "${default}"
    return
  fi

  local value="${line#*=}"
  value="$(printf '%s' "${value}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+#.*$//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/')"

  if [[ -z "${value}" ]]; then
    echo "${default}"
  else
    echo "${value}"
  fi
}

wait_for() {
  local title="$1"
  local cmd="$2"
  local max_retry="${3:-30}"
  local sleep_sec="${4:-2}"

  echo "[wait] ${title}"
  for ((i = 1; i <= max_retry; i++)); do
    if eval "${cmd}" >/dev/null 2>&1; then
      echo "[ok] ${title}"
      return 0
    fi
    sleep "${sleep_sec}"
  done

  echo "[ng] ${title}" >&2
  return 1
}

S3_ENDPOINT="$(get_env_value S3_ENDPOINT 'http://rustfs:9000')"
S3_ACCESS_KEY="$(get_env_value S3_ACCESS_KEY 'rustfsadmin')"
S3_SECRET_KEY="$(get_env_value S3_SECRET_KEY 'rustfsadmin')"
S3_REGION="$(get_env_value S3_REGION 'us-east-1')"
S3_BUCKET="$(get_env_value S3_BUCKET 'sample-bucket')"

FTP_USER="$(get_env_value FTP_USER_NAME 'testftp')"
FTP_REMOTE_BASE="$(get_env_value FTP_REMOTE_BASE '/')"
FTP_REMOTE_BASE="${FTP_REMOTE_BASE#/}"
FTP_DEST_DIR="${FTP_VOLUME_DIR}/${FTP_USER}"
if [[ -n "${FTP_REMOTE_BASE}" ]]; then
  FTP_DEST_DIR="${FTP_DEST_DIR}/${FTP_REMOTE_BASE}"
fi

wait_for "php container ready" "docker compose exec -T php php -v"
wait_for "rustfs reachable" "docker compose exec -T php sh -lc 'AWS_ACCESS_KEY_ID=\"${S3_ACCESS_KEY}\" AWS_SECRET_ACCESS_KEY=\"${S3_SECRET_KEY}\" AWS_DEFAULT_REGION=\"${S3_REGION}\" aws --endpoint-url \"${S3_ENDPOINT}\" --no-cli-pager s3api list-buckets >/dev/null'"

echo "[run] migrate"
docker compose exec -T php php spark migrate --all

echo "[run] ensure bucket ${S3_BUCKET}"
docker compose exec -T php sh -lc "
AWS_ACCESS_KEY_ID='${S3_ACCESS_KEY}' \\
AWS_SECRET_ACCESS_KEY='${S3_SECRET_KEY}' \\
AWS_DEFAULT_REGION='${S3_REGION}' \\
if aws --endpoint-url '${S3_ENDPOINT}' --no-cli-pager s3api head-bucket --bucket '${S3_BUCKET}' >/dev/null 2>&1; then
  echo '[ok] bucket exists'
else
  aws --endpoint-url '${S3_ENDPOINT}' --no-cli-pager s3api create-bucket --bucket '${S3_BUCKET}'
  echo '[ok] bucket created'
fi
"

if [[ -d "${S3_LOCAL_DIR}" ]]; then
  echo "[run] sync S3 ${S3_LOCAL_DIR} -> s3://${S3_BUCKET}/"
  docker compose exec -T php sh -lc "
AWS_ACCESS_KEY_ID='${S3_ACCESS_KEY}' \\
AWS_SECRET_ACCESS_KEY='${S3_SECRET_KEY}' \\
AWS_DEFAULT_REGION='${S3_REGION}' \\
aws --endpoint-url '${S3_ENDPOINT}' --no-cli-pager \\
  s3 sync '/var/www/html/docker/init/s3/' 's3://${S3_BUCKET}/' --exact-timestamps
"
else
  echo "[skip] S3 local dir not found: ${S3_LOCAL_DIR}"
fi

if [[ -d "${FTP_LOCAL_DIR}" ]]; then
  if ! command -v rsync >/dev/null 2>&1; then
    echo "rsync command not found" >&2
    exit 1
  fi

  mkdir -p "${FTP_DEST_DIR}"
  echo "[run] sync FTP files ${FTP_LOCAL_DIR} -> ${FTP_DEST_DIR}"
  rsync -a --delete "${FTP_LOCAL_DIR}/" "${FTP_DEST_DIR}/"
else
  echo "[skip] FTP local dir not found: ${FTP_LOCAL_DIR}"
fi

echo "[done] docker post-up initialization completed"
