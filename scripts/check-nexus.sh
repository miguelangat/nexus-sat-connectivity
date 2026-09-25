#!/usr/bin/env bash
set -euo pipefail

NEXUS_BASE_URL="${NEXUS_BASE_URL:-https://sonatype.dev.repo.saas.sonatype.dev}"

if [[ -z "${NEXUS_USERNAME:-}" || -z "${NEXUS_TOKEN:-}" ]]; then
  echo "Set NEXUS_USERNAME and NEXUS_TOKEN in the environment." >&2
  exit 2
fi

if [[ ! "$NEXUS_BASE_URL" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$ ]]; then
  echo "NEXUS_BASE_URL must be an HTTPS origin (no path)." >&2
  exit 2
fi

response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

status="$(
  curl --silent --show-error \
    --connect-timeout 15 --max-time 30 \
    --user "$NEXUS_USERNAME:$NEXUS_TOKEN" \
    --output "$response_file" --write-out '%{http_code}' \
    "$NEXUS_BASE_URL/"
)"

content_type="$(file --brief --mime-type "$response_file" 2>/dev/null || printf 'unknown')"
printf 'Nexus endpoint: %s\nHTTP status: %s\nResponse content type: %s\n' \
  "$NEXUS_BASE_URL" "$status" "$content_type"

case "$status" in
  2??|3??) echo "Connectivity and authentication check succeeded." ;;
  401) echo "Nexus rejected the credentials (401 Unauthorized)." >&2; exit 1 ;;
  403) echo "Nexus was reached, but access to the REST API root is forbidden (403)." >&2; exit 1 ;;
  *) echo "Nexus returned HTTP $status." >&2; exit 1 ;;
esac
