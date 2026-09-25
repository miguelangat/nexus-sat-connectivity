#!/usr/bin/env bash
set -euo pipefail

NEXUS_BASE_URL="${NEXUS_BASE_URL:-https://sonatype.dev.repo.saas.sonatype.dev}"
RUN_ID="${GITHUB_RUN_ID:-local}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-1}"

if [[ -z "${NEXUS_USERNAME:-}" || -z "${NEXUS_TOKEN:-}" ]]; then
  echo "Set NEXUS_USERNAME and NEXUS_TOKEN as GitHub Actions secrets." >&2
  exit 2
fi

if [[ ! "$NEXUS_BASE_URL" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$ ]]; then
  echo "NEXUS_BASE_URL must be an HTTPS origin (no path)." >&2
  exit 2
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/nexus-sat-connectivity-demo"
cp README.md "$tmp_dir/nexus-sat-connectivity-demo/README.md"
{
  printf 'Nexus SAT connectivity demo package\n'
  printf 'GitHub Actions run: %s\n' "$RUN_ID"
  printf 'Run attempt: %s\n' "$RUN_ATTEMPT"
  printf 'Created at (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$tmp_dir/nexus-sat-connectivity-demo/manifest.txt"

archive="$tmp_dir/nexus-sat-connectivity-demo.tar.gz"
tar -czf "$archive" -C "$tmp_dir" nexus-sat-connectivity-demo
upload_url="$NEXUS_BASE_URL/repository/raw/connectivity-demo/github-actions/$RUN_ID-$RUN_ATTEMPT/nexus-sat-connectivity-demo.tar.gz"
response_file="$tmp_dir/response"

status="$(
  curl --silent --show-error \
    --connect-timeout 15 --max-time 60 \
    --user "$NEXUS_USERNAME:$NEXUS_TOKEN" \
    --upload-file "$archive" \
    --output "$response_file" --write-out '%{http_code}' \
    "$upload_url"
)"

printf 'Raw repository upload HTTP status: %s\n' "$status"
case "$status" in
  2??) printf 'Published demo package to raw repository path: %s\n' "${upload_url#"$NEXUS_BASE_URL"}" ;;
  401) echo "Nexus rejected the credentials (401 Unauthorized)." >&2; exit 1 ;;
  403) echo "Nexus denied upload permission to the raw repository (403 Forbidden)." >&2; exit 1 ;;
  *) echo "Nexus returned HTTP $status while uploading the package." >&2; exit 1 ;;
esac
