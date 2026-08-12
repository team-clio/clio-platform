#!/usr/bin/env bash
set -euo pipefail

admin_port="${CLIO_ADMIN_PORT:-3000}"
base_url="http://127.0.0.1:${admin_port}/api/v1/projects"
project_name="Compose Smoke $(date +%s)"

created="$(curl --fail --silent --show-error \
  --request POST \
  --header 'Content-Type: application/json' \
  --data "{\"name\":\"${project_name}\"}" \
  "${base_url}")"

printf '%s' "${created}" | grep --fixed-strings --quiet "\"name\":\"${project_name}\""

projects="$(curl --fail --silent --show-error "${base_url}")"
printf '%s' "${projects}" | grep --fixed-strings --quiet "\"name\":\"${project_name}\""

echo "Smoke test passed: ${project_name}"

