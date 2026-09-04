#!/usr/bin/env bash
# shellcheck disable=SC2329
#
# deploy-check.sh
#
# Usage: ./deploy-check.sh http://localhost:8080 v1
#

set -euo pipefail

readonly CONNECT_TIMEOUT=3
readonly REQUEST_TIMEOUT=10
readonly MAX_RETRIES=3
readonly BACKOFF_SECONDS=(1 2 4)

readonly JQ_VERSION_EXTRACTOR='if type == "object" and has("version") then .version else empty end'
readonly PYTHON_VERSION_EXTRACTOR='import json, sys; data = json.load(sys.stdin); value = data.get("version", "") if isinstance(data, dict) else ""; print("" if value is None else value)'

usage() {
  echo "Uso: ${0} <url_base> <version_esperada>" >&2
  echo "Ejemplo: ${0} http://localhost:8080 1.2.3" >&2
  echo "Para no validar versión, usa ANY como versión esperada." >&2
}

log() {
  printf '[INFO] %s\n' "$*" >&2
}

err() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  err "$*"
  exit 1
}

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]]; then
    rm -rf -- "${TMP_DIR}"
  fi
}

on_exit() {
  local status="$?"

  if [[ $# -gt 0 ]]; then
    status="$1"
  fi

  trap - EXIT INT TERM
  cleanup || true
  exit "$status"
}

on_int() {
  on_exit 130
}

on_term() {
  on_exit 143
}

file_content() {
  local file="$1"

  if [[ -f "$file" && -r "$file" ]]; then
    cat -- "$file" 2>/dev/null || true
  fi
}

truncate_text() {
  local text="$1"
  local max=200

  if [[ ${#text} -gt $max ]]; then
    printf '%s...' "${text:0:max}"
  else
    printf '%s' "$text"
  fi
}

wait_before_retry() {
  local check_name="$1"
  local attempt="$2"
  local delay_index
  local delay

  delay_index=$((attempt - 1))

  if (( delay_index >= ${#BACKOFF_SECONDS[@]} )); then
    delay_index=$(( ${#BACKOFF_SECONDS[@]} - 1 ))
  fi

  delay="${BACKOFF_SECONDS[$delay_index]}"

  log "$check_name: esperando ${delay}s antes de reintentar."

  if ! sleep "$delay"; then
    die "$check_name: falló sleep de ${delay}s."
  fi
}

check_healthz() {
  local check_name="healthz"
  local url="$URL/healthz"
  local body_file="$TMP_DIR/healthz_body"
  local error_file="$TMP_DIR/healthz_error"
  local max_attempts
  local attempt=1
  local http_code
  local last_error

  max_attempts=$((MAX_RETRIES + 1))
  last_error="sin error registrado"

  while (( attempt <= max_attempts )); do
    log "$check_name: intento $attempt/$max_attempts contra $url"
    http_code=""

    if http_code="$(curl --silent --show-error \
        --connect-timeout "$CONNECT_TIMEOUT" \
        --max-time "$REQUEST_TIMEOUT" \
        --output "$body_file" \
        --write-out "%{http_code}" \
        "$url" 2>"$error_file")"; then

      if [[ "$http_code" == "200" ]]; then
        log "$check_name: OK (HTTP 200)."
        return 0
      fi

      last_error="HTTP $http_code; cuerpo: $(truncate_text "$(file_content "$body_file")")"
    else
      last_error="curl no pudo completar la petición: $(truncate_text "$(file_content "$error_file")")"
    fi

    if (( attempt < max_attempts )); then
      log "$check_name: falló. Visto: $last_error"
      wait_before_retry "$check_name" "$attempt"
    fi

    attempt=$((attempt + 1))
  done

  die "Falló el chequeo '$check_name'. URL=$url. Observado: $last_error"
}

check_api_checks() {
  local check_name="api/checks"
  local url="$URL/api/checks"
  local body_file="$TMP_DIR/api_checks_body"
  local error_file="$TMP_DIR/api_checks_error"
  local max_attempts
  local attempt=1
  local http_code
  local actual_version
  local attempt_ok
  local last_error

  max_attempts=$((MAX_RETRIES + 1))
  last_error="sin error registrado"

  while (( attempt <= max_attempts )); do
    log "$check_name: intento $attempt/$max_attempts contra $url"

    http_code=""
    actual_version=""
    attempt_ok=0

    if http_code="$(curl --silent --show-error \
        --connect-timeout "$CONNECT_TIMEOUT" \
        --max-time "$REQUEST_TIMEOUT" \
        --output "$body_file" \
        --write-out "%{http_code}" \
        "$url" 2>"$error_file")"; then

      if [[ "$http_code" == "200" ]]; then

        if [[ "$JSON_VALIDATOR" == "jq" ]]; then

          if jq . "$body_file" >/dev/null 2>"$error_file"; then

            if [[ "$EXPECTED_VERSION" == "ANY" || "$EXPECTED_VERSION" == "-" ]]; then
              attempt_ok=1

            elif actual_version="$(jq -r "$JQ_VERSION_EXTRACTOR" "$body_file" 2>"$error_file")"; then

              if [[ -n "$actual_version" && "$actual_version" == "$EXPECTED_VERSION" ]]; then
                attempt_ok=1

              elif [[ -z "$actual_version" ]]; then
                last_error="JSON válido, pero no encontré un campo .version legible. cuerpo: $(truncate_text "$(file_content "$body_file")")"

              else
                last_error="versión real '$actual_version' != versión esperada '$EXPECTED_VERSION'"
              fi

            else
              last_error="No pude extraer .version con jq: $(truncate_text "$(file_content "$error_file")")"
            fi

          else
            last_error="JSON inválido según jq: $(truncate_text "$(file_content "$error_file")"); cuerpo: $(truncate_text "$(file_content "$body_file")")"
          fi

        else

          if python3 -m json.tool "$body_file" >/dev/null 2>"$error_file"; then

            if [[ "$EXPECTED_VERSION" == "ANY" || "$EXPECTED_VERSION" == "-" ]]; then
              attempt_ok=1

            elif actual_version="$(python3 -c "$PYTHON_VERSION_EXTRACTOR" <"$body_file" 2>"$error_file")"; then

              if [[ -n "$actual_version" && "$actual_version" == "$EXPECTED_VERSION" ]]; then
                attempt_ok=1

              elif [[ -z "$actual_version" ]]; then
                last_error="JSON válido, pero no encontré un campo .version legible. cuerpo: $(truncate_text "$(file_content "$body_file")")"

              else
                last_error="versión real '$actual_version' != versión esperada '$EXPECTED_VERSION'"
              fi

            else
              last_error="No pude extraer .version con python3: $(truncate_text "$(file_content "$error_file")")"
            fi

          else
            last_error="JSON inválido según python3 -m json.tool: $(truncate_text "$(file_content "$error_file")"); cuerpo: $(truncate_text "$(file_content "$body_file")")"
          fi

        fi

      else
        last_error="HTTP $http_code; cuerpo: $(truncate_text "$(file_content "$body_file")")"
      fi

    else
      last_error="curl no pudo completar la petición: $(truncate_text "$(file_content "$error_file")")"
    fi

    if (( attempt_ok == 1 )); then
      if [[ "$EXPECTED_VERSION" == "ANY" || "$EXPECTED_VERSION" == "-" ]]; then
        log "$check_name: OK (HTTP 200 y JSON válido; versión no validada por pedido de ANY)."
      else
        log "$check_name: OK (HTTP 200, JSON válido y versión '$actual_version')."
      fi

      return 0
    fi

    if (( attempt < max_attempts )); then
      log "$check_name: falló. Visto: $last_error"
      wait_before_retry "$check_name" "$attempt"
    fi

    attempt=$((attempt + 1))
  done

  die "Falló el chequeo '$check_name'. URL=$url. Observado: $last_error"
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

URL="$1"
EXPECTED_VERSION="$2"

if [[ -z "$URL" ]]; then
  die "La URL está vacía."
fi

if [[ -z "$EXPECTED_VERSION" ]]; then
  die "La versión esperada está vacía."
fi

URL="${URL%/}"

if [[ -z "$URL" ]]; then
  die "La URL quedó vacía después de normalizarla."
fi

if ! command -v curl >/dev/null 2>&1; then
  die "No encuentro curl."
fi

if command -v jq >/dev/null 2>&1; then
  JSON_VALIDATOR="jq"
elif command -v python3 >/dev/null 2>&1; then
  JSON_VALIDATOR="python3"
else
  die "Necesito jq o python3 para validar JSON."
fi

if ! TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/service_check.XXXXXX")"; then
  die "No pude crear un directorio temporal."
fi

trap on_exit EXIT
trap on_int INT
trap on_term TERM

log "URL base: $URL"
log "Versión esperada: $EXPECTED_VERSION"
log "Validador de JSON: $JSON_VALIDATOR"

check_healthz
check_api_checks

log "Todos los chequeos pasaron."

if [[ "$EXPECTED_VERSION" != "ANY" && "$EXPECTED_VERSION" != "-" ]]; then
  log "Versión esperada confirmada: $EXPECTED_VERSION"
fi

exit 0