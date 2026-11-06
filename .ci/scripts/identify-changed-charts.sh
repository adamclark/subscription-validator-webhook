#!/usr/bin/env bash
# Find charts with version bumps that are candidates for release.
# Usage: identify-changed-charts.sh <base-ref> <head-ref> [chart-root]
set -euo pipefail

source "$(dirname "$0")/_helpers.sh"

BASE_REF="${1:?Usage: identify-changed-charts.sh <base-ref> <head-ref> [chart-root]}"
HEAD_REF="${2:?Usage: identify-changed-charts.sh <base-ref> <head-ref> [chart-root]}"
CHART_ROOT="${3:-chart}"

# Fetch the base and head refs from origin to ensure they exist locally.
git fetch --quiet origin "$BASE_REF" "$HEAD_REF" 2>/dev/null || {
  echo "ERROR: Failed to fetch refs $BASE_REF and/or $HEAD_REF from origin" >&2
  exit 1
}

# Verify the refs exist and are commits.
git rev-parse --verify "${BASE_REF}^{commit}" >/dev/null
git rev-parse --verify "${HEAD_REF}^{commit}" >/dev/null

# Find changed charts and validate version bumps.
git diff --name-only "$BASE_REF" "$HEAD_REF" \
  | grep "^${CHART_ROOT}/" \
  | sed "s|^${CHART_ROOT}/||" \
  | cut -d/ -f1 \
  | sort -u \
  | while IFS= read -r chart; do
      chart_file="$CHART_ROOT/$chart/Chart.yaml"

      # Validate this is a chart directory - exists at HEAD with a Chart.yaml
      git cat-file -e "${HEAD_REF}:${chart_file}" 2>/dev/null || continue
      [[ -f "$chart_file" ]] || continue

      # Get current chart YAML
      current_chart_name="$(get_chart_name_from_file "$chart_file")"
      current_chart_version="$(get_chart_version_from_file "$chart_file")"

      # Validate directory name matches chart name
      if [[ "$current_chart_name" != "$chart" ]]; then
        echo "ERROR: chart directory '$chart' contains Chart.yaml name '$current_chart_name'." >&2
        echo "This directory name and chart name should match." >&2
        exit 1
      fi

      # Get old chart version from BASE_REF
      old_yaml="$(git show "${BASE_REF}:${chart_file}" 2>/dev/null || true)"
      if [[ -n "$old_yaml" ]]; then
        old_version="$(get_chart_version_from_yaml "$old_yaml")"
      else
        old_version=""
      fi

      # Skip if version unchanged
      if [[ "$current_chart_version" == "$old_version" ]]; then
        echo "ERROR: $chart: chart files changed but version unchanged ($current_chart_version)" >&2
        exit 1
      fi

      # Require valid SemVer version
      if ! [[ "$current_chart_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
        echo "ERROR: $chart: non-SemVer chart version '$current_chart_version'" >&2
        exit 1
      fi

      # Prevent version rollback
      if [[ -n "$old_version" ]]; then
        old_core="${old_version%%[-+]*}"
        new_core="${current_chart_version%%[-+]*}"
        IFS=. read -r old_major old_minor old_patch <<< "$old_core"
        IFS=. read -r new_major new_minor new_patch <<< "$new_core"
        if (( 10#$new_major < 10#$old_major ||
              (10#$new_major == 10#$old_major && 10#$new_minor < 10#$old_minor) ||
              (10#$new_major == 10#$old_major && 10#$new_minor == 10#$old_minor && 10#$new_patch < 10#$old_patch) )); then
          echo "ERROR: $chart: version decreased from $old_version to $current_chart_version" >&2
          exit 1
        fi
      fi

      printf '%s\n' "$chart"
    done
