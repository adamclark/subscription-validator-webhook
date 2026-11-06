#!/usr/bin/env bash
# Shared library functions for CI scripts
# Usage: source "$(dirname "$0")/_helpers.sh"

# Temporary file/directory cleanup
_TEMP_REGISTRY="$(mktemp)"
_cleanup_temp_paths() {
  if [[ -f "$_TEMP_REGISTRY" ]]; then
    while IFS= read -r path; do
      [[ -n "$path" ]] && rm -rf "$path"
    done < "$_TEMP_REGISTRY"
    rm -f "$_TEMP_REGISTRY"
  fi
}
trap _cleanup_temp_paths EXIT INT TERM

# Create a temporary directory with automatic cleanup on exit
# Usage: tmpdir="$(create_temp_dir)"
create_temp_dir() {
  local dir
  dir="$(mktemp -d)"
  echo "$dir" >> "$_TEMP_REGISTRY"
  echo "$dir"
}

# Create a temporary file with automatic cleanup on exit
# Usage: tmpfile="$(create_temp_file)"
create_temp_file() {
  local file
  file="$(mktemp)"
  echo "$file" >> "$_TEMP_REGISTRY"
  echo "$file"
}

# Get chart name from Chart.yaml content
# Usage: chart_name="$(get_chart_name "$yaml_content")"
get_chart_name_from_yaml() {
  local yaml_content="${1:?get_chart_name requires YAML content}"
  local value="$(printf '%s\n' "$yaml_content" | yq -r '.name // ""')"

  if [[ -z "$value" ]]; then
    echo "ERROR: Chart.yaml missing 'name' field" >&2
    return 2
  fi

  echo "$value"
}

# Get chart name from Chart.yaml file
# Usage: chart_name="$(get_chart_name_from_file "$chart_file")"
get_chart_name_from_file() {
  local chart_file="${1:?get_chart_name_from_file requires chart file}"
  if [[ -f "$chart_file" ]]; then
    get_chart_name_from_yaml "$(cat "$chart_file")"
  else
    echo "ERROR: $chart_file not found" >&2
    return 2
  fi
}

# Get chart version from Chart.yaml content
# Usage: chart_version="$(get_chart_version "$yaml_content")"
get_chart_version_from_yaml() {
  local yaml_content="${1:?get_chart_version requires YAML content}"
  local value="$(printf '%s\n' "$yaml_content" | yq -r '.version // ""')"

  if [[ -z "$value" ]]; then
    echo "ERROR: Chart.yaml missing 'version' field" >&2
    return 2
  fi

  echo "$value"
}

# Get chart version from Chart.yaml file
# Usage: chart_version="$(get_chart_version_from_file "$chart_file")"
get_chart_version_from_file() {
  local chart_file="${1:?get_chart_version_from_file requires chart file}"
  if [[ -f "$chart_file" ]]; then
    get_chart_version_from_yaml "$(cat "$chart_file")"
  else
    echo "ERROR: $chart_file not found" >&2
    return 2
  fi
}
