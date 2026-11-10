#!/usr/bin/env bash
# Fail if this chart/version is already present in the Helm repository.
# Usage: chart-version-release-check.sh <chart-dir>
#
# Required: HELM_REPO_URL, HELM_REPO_USER, HELM_REPO_PASSWORD
set -euo pipefail

source "$(dirname "$0")/_helpers.sh"

CHART_DIR="${1:?Usage: chart-version-release-check.sh <chart-dir>}"
: "${HELM_REPO_URL:?}"
: "${HELM_REPO_USER:?}"
: "${HELM_REPO_PASSWORD:?}"

chart_file="$CHART_DIR/Chart.yaml"
[[ -f "$chart_file" ]] || { echo "ERROR: $chart_file not found" >&2; exit 2; }

chart_name="$(get_chart_name_from_file "$chart_file")"
chart_version="$(get_chart_version_from_file "$chart_file")"

url="${HELM_REPO_URL%/}/${chart_name}-${chart_version}.tgz"

# HEAD request with timeouts to prevent hanging
# --insecure only added for dev with dev Helm repo
http_code="$(curl --insecure --silent --show-error --output /dev/null \
  --write-out '%{http_code}' \
  --connect-timeout 10 \
  --max-time 30 \
  --user "${HELM_REPO_USER}:${HELM_REPO_PASSWORD}" \
  --head "$url")"

case "$http_code" in
  200)
    echo "ERROR: ${chart_name}-${chart_version}.tgz already exists in repository" >&2
    echo "  Bump version in Chart.yaml before publishing" >&2
    exit 1
    ;;
  404)
    echo "✓ ${chart_name} ${chart_version} eligible to publish"
    ;;
  *)
    echo "ERROR: Unexpected HTTP $http_code from $url" >&2
    echo "  Cannot publish until connectivity is verified" >&2
    exit 1
    ;;
esac
