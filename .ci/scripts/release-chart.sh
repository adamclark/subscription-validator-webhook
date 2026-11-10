#!/usr/bin/env bash
# Package and publish one chart to a Helm repository.
# Usage: release-chart.sh <chart-dir>
set -euo pipefail

source "$(dirname "$0")/_helpers.sh"

CHART_DIR="${1:?Usage: release-chart.sh <chart-dir>}"
: "${HELM_REPO_URL:?}"
: "${HELM_REPO_USER:?}"
: "${HELM_REPO_PASSWORD:?}"

# Set --insecure flag for curl if HELM_INSECURE is set to "true"
INSECURE_FLAG=""
if [[ "${HELM_INSECURE:-false}" == "true" ]]; then
  INSECURE_FLAG="--insecure"
fi

chart_file="$CHART_DIR/Chart.yaml"
[[ -f "$chart_file" ]] || { echo "ERROR: $chart_file not found" >&2; exit 2; }

chart_name="$(get_chart_name_from_file "$chart_file")"
chart_version="$(get_chart_version_from_file "$chart_file")"

tmpdir="$(create_temp_dir)"

# Build the chart package and verify it was produced.
helm dependency build "$CHART_DIR"
helm package "$CHART_DIR" --destination "$tmpdir"

package="$tmpdir/${chart_name}-${chart_version}.tgz"
[[ -f "$package" ]] || {
  echo "ERROR: expected package not produced: $package" >&2
  exit 1
}

# Re-check no previous release immediately before upload to reduce race conditions.
"$(dirname "$0")/pre-release-check.sh" "$CHART_DIR"

# Upload the chart to the Helm repository.
upload_url="${HELM_REPO_URL%/}/"
curl $INSECURE_FLAG --fail --silent --show-error \
  --user "${HELM_REPO_USER}:${HELM_REPO_PASSWORD}" \
  --upload-file "$package" \
  "$upload_url"

# Verify the exact asset can be fetched after upload.
http_code="$(curl $INSECURE_FLAG --silent --show-error --output /dev/null \
  --write-out '%{http_code}' \
  --user "${HELM_REPO_USER}:${HELM_REPO_PASSWORD}" \
  --head "${upload_url}${chart_name}-${chart_version}.tgz")"

if [[ "$http_code" != "200" ]]; then
  echo "ERROR: upload returned success, but attempted fetch returned HTTP $http_code" >&2
  exit 1
fi

# Verify the fingerprint of the uploaded file matches the local file.
remote_sha256="$(curl $INSECURE_FLAG --silent --show-error \
  --user "${HELM_REPO_USER}:${HELM_REPO_PASSWORD}" \
  "${upload_url}${chart_name}-${chart_version}.tgz" | sha256 | cut -d' ' -f1)"

echo "Remote sha256: $remote_sha256"

sha256 -c $remote_sha256 "$package"

echo "Published and verified ${chart_name}-${chart_version}.tgz"