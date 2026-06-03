#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIGNING_DIR="$PROJECT_ROOT/.build/signing"
KEYCHAIN_PATH="${APPICONEXPORTER_SIGNING_KEYCHAIN_PATH:-$SIGNING_DIR/AppIconExporterSigning.keychain-db}"
KEYCHAIN_PASSWORD_FILE="${KEYCHAIN_PATH}.password"
IDENTITY_COMMON_NAME="${LOCAL_SIGN_IDENTITY_NAME:-AppIconExporter Local Signer}"
CERT_VALID_DAYS="${LOCAL_SIGN_IDENTITY_DAYS:-3650}"
PRINT_ENV=0

usage() {
  cat <<'EOF'
Usage: scripts/ensure-local-signing.sh [--print-env]

Creates or reuses a project-local self-signed code signing identity.

Options:
  --print-env   Print shell assignments for SIGN_IDENTITY and SIGN_KEYCHAIN_PATH.
EOF
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

if [[ "${1:-}" == "--print-env" ]]; then
  PRINT_ENV=1
elif [[ $# -eq 1 ]]; then
  usage >&2
  exit 1
fi

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
}

require_command openssl
require_command security
require_command certtool

mkdir -p "$SIGNING_DIR"
chmod 700 "$SIGNING_DIR"

keychain_password() {
  if [[ -f "$KEYCHAIN_PASSWORD_FILE" ]]; then
    cat "$KEYCHAIN_PASSWORD_FILE"
    return 0
  fi

  local generated_password
  generated_password="$(openssl rand -base64 24 | tr -d '\n')"
  printf '%s' "$generated_password" > "$KEYCHAIN_PASSWORD_FILE"
  chmod 600 "$KEYCHAIN_PASSWORD_FILE"
  printf '%s' "$generated_password"
}

find_identity_sha1() {
  security find-identity -v -p codesigning "$KEYCHAIN_PATH" 2>/dev/null |
    awk -v cn="$IDENTITY_COMMON_NAME" 'index($0, "\"" cn "\"") { print $2; exit }'
}

ensure_keychain() {
  local password="$1"

  if [[ ! -f "$KEYCHAIN_PATH" ]]; then
    security create-keychain -p "$password" "$KEYCHAIN_PATH" >/dev/null
  fi

  security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH" >/dev/null
  security unlock-keychain -p "$password" "$KEYCHAIN_PATH" >/dev/null
}

create_identity() {
  local password="$1"
  local temp_dir
  temp_dir="$(mktemp -d "$SIGNING_DIR/create-local-signing.XXXXXX")"
  trap '[[ -n "${temp_dir:-}" ]] && rm -rf "$temp_dir"' RETURN

  cat > "$temp_dir/openssl.cnf" <<EOF
[ req ]
default_bits = 2048
distinguished_name = dn
prompt = no

[ dn ]
CN = $IDENTITY_COMMON_NAME
O = AppIconExporter
OU = Local Development

[ codesign ]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
EOF

  rm -f "$KEYCHAIN_PATH"
  openssl genrsa -traditional -out "$temp_dir/signing.key" 2048 >/dev/null 2>&1
  openssl req \
    -new \
    -key "$temp_dir/signing.key" \
    -out "$temp_dir/signing.csr" \
    -config "$temp_dir/openssl.cnf" >/dev/null 2>&1
  openssl x509 \
    -req \
    -days "$CERT_VALID_DAYS" \
    -in "$temp_dir/signing.csr" \
    -signkey "$temp_dir/signing.key" \
    -out "$temp_dir/signing.crt" \
    -extfile "$temp_dir/openssl.cnf" \
    -extensions codesign >/dev/null 2>&1

  certtool i \
    "$temp_dir/signing.crt" \
    k="$KEYCHAIN_PATH" \
    r="$temp_dir/signing.key" \
    c \
    p="$password" >/dev/null 2>&1

  security add-trusted-cert \
    -d \
    -r trustRoot \
    -k "$KEYCHAIN_PATH" \
    "$temp_dir/signing.crt" >/dev/null 2>&1

  ensure_keychain "$password"

  security set-key-partition-list \
    -S apple-tool:,apple: \
    -s \
    -k "$password" \
    "$KEYCHAIN_PATH" >/dev/null
}

main() {
  local password
  local identity_sha1

  password="$(keychain_password)"
  ensure_keychain "$password"

  identity_sha1="$(find_identity_sha1 || true)"
  if [[ -z "$identity_sha1" ]]; then
    create_identity "$password"
    identity_sha1="$(find_identity_sha1 || true)"
  fi

  if [[ -z "$identity_sha1" ]]; then
    echo "Failed to create a reusable code signing identity." >&2
    exit 1
  fi

  if [[ "$PRINT_ENV" -eq 1 ]]; then
    printf 'SIGN_IDENTITY=%q\n' "$identity_sha1"
    printf 'SIGN_KEYCHAIN_PATH=%q\n' "$KEYCHAIN_PATH"
    printf 'SIGN_IDENTITY_LABEL=%q\n' "$IDENTITY_COMMON_NAME"
    return 0
  fi

  echo "Local signing identity is ready."
  echo "Identity: $IDENTITY_COMMON_NAME"
  echo "SHA-1: $identity_sha1"
  echo "Keychain: $KEYCHAIN_PATH"
}

main "$@"
