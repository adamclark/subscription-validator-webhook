#!/usr/bin/env bash
# Validate one chart.
# Usage: validate-chart.sh <chart-dir>
set -euo pipefail

source "$(dirname "$0")/_helpers.sh"

CHART_DIR="${1:?Usage: validate-chart.sh <chart-dir>}"

helm dependency build "$CHART_DIR"

helm lint "$CHART_DIR"

# if helm plugin list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx 'unittest'; then
#   helm unittest "$CHART_DIR"
# else
#   echo "ERROR: helm-unittest plugin is required but not installed" >&2
#   exit 1
# fi

# render_dir="$(create_temp_dir)"

# render_one() {
#   local label="$1"; shift
#   local output="$render_dir/${label}.yaml"
#   echo "Rendering $CHART_DIR ($label)"
#   helm template ci-validation "$CHART_DIR" "$@" > "$output"

#   if command -v kubeconform >/dev/null; then
#     kubeconform -strict -summary "$output"
#   elif [[ "${REQUIRE_KUBECONFORM:-false}" == "true" ]]; then
#     echo "ERROR: kubeconform required but not installed" >&2
#     exit 1
#   else
#     echo "WARN: kubeconform not installed; skipping schema validation" >&2
#   fi

#   if [[ -n "${CONFTEST_POLICY_DIR:-}" ]]; then
#     command -v conftest >/dev/null || {
#       echo "ERROR: CONFTEST_POLICY_DIR set but conftest not installed" >&2
#       exit 1
#     }
#     conftest test "$output" --policy "$CONFTEST_POLICY_DIR"
#   fi

#   # Optional ACS check wrapper. This allows the team to configure the
#   # exact roxctl flags for its RHACS version and policy context.
#   if [[ -n "${ACS_CHECK_SCRIPT:-}" ]]; then
#     [[ -x "$ACS_CHECK_SCRIPT" ]] || {
#       echo "ERROR: ACS_CHECK_SCRIPT is not executable: $ACS_CHECK_SCRIPT" >&2
#       exit 1
#     }
#     "$ACS_CHECK_SCRIPT" "$output"
#   fi
# }

# render_one default

# if [[ -n "${CHART_VALUES_FILES:-}" ]]; then
#   # Paths are whitespace-separated; do not use for filenames containing spaces.
#   i=0
#   for values_file in $CHART_VALUES_FILES; do
#     [[ -f "$values_file" ]] || {
#       echo "ERROR: values file not found: $values_file" >&2
#       exit 1
#     }
#     i=$((i + 1))
#     render_one "values-${i}" --values "$values_file"
#   done
# fi
