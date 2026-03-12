#!/usr/bin/env bash
# Sentinel installer — https://github.com/aneesahammed/sentinel-dist
set -euo pipefail

REPO="aneesahammed/sentinel-dist"
BINARY="sentinel"
INSTALL_DIR="${INSTALL_DIR:-$HOME/bin}"

# ── Platform detection ────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux"  ;;
  *)
    echo "error: unsupported OS '$(uname -s)'. Download manually from:" >&2
    echo "  https://github.com/${REPO}/releases/latest" >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64|amd64)   ARCH="amd64" ;;
  arm64|aarch64)  ARCH="arm64" ;;
  *)
    echo "error: unsupported architecture '$(uname -m)'. Download manually from:" >&2
    echo "  https://github.com/${REPO}/releases/latest" >&2
    exit 1
    ;;
esac

# ── Fetch latest release metadata ────────────────────────────────────────────
API="https://api.github.com/repos/${REPO}/releases/latest"
if command -v curl >/dev/null 2>&1; then
  RELEASE_JSON="$(curl -fsSL "${API}")"
elif command -v wget >/dev/null 2>&1; then
  RELEASE_JSON="$(wget -qO- "${API}")"
else
  echo "error: curl or wget is required." >&2
  exit 1
fi

TAG="$(printf '%s' "${RELEASE_JSON}" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
VERSION="${TAG#v}"
ASSET="${BINARY}_${VERSION}_${OS}_${ARCH}"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

# Validate that this platform asset exists in the release
if ! printf '%s' "${RELEASE_JSON}" | grep -q "\"${ASSET}\""; then
  echo "error: no release asset for ${OS}/${ARCH} in ${TAG}." >&2
  echo "Available assets:" >&2
  printf '%s' "${RELEASE_JSON}" | grep '"name"' | grep "sentinel_" | sed 's/.*"name": *"\([^"]*\)".*/  \1/' >&2
  exit 1
fi

echo "Installing Sentinel ${TAG} (${OS}/${ARCH})..."

# ── Download ──────────────────────────────────────────────────────────────────
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

_download() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$2" "$1"
  else
    wget -qO "$2" "$1"
  fi
}

echo "  Downloading ${ASSET}..."
_download "${BASE_URL}/${ASSET}" "${TMP}/${BINARY}"
_download "${BASE_URL}/checksums.txt" "${TMP}/checksums.txt"

# ── Checksum verification ─────────────────────────────────────────────────────
EXPECTED="$(awk -v asset="${ASSET}" '$2==asset{print $1}' "${TMP}/checksums.txt")"

if [[ -z "${EXPECTED}" ]]; then
  echo "  warning: checksum entry for '${ASSET}' not found; skipping verification."
else
  if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL="$(sha256sum "${TMP}/${BINARY}" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    ACTUAL="$(shasum -a 256 "${TMP}/${BINARY}" | awk '{print $1}')"
  else
    echo "  warning: no sha256 tool found; skipping checksum verification."
    ACTUAL="${EXPECTED}"
  fi

  if [[ "${ACTUAL}" != "${EXPECTED}" ]]; then
    echo "error: checksum mismatch." >&2
    echo "  expected: ${EXPECTED}" >&2
    echo "  actual:   ${ACTUAL}" >&2
    exit 1
  fi
  echo "  Checksum OK."
fi

# ── Install ───────────────────────────────────────────────────────────────────
mkdir -p "${INSTALL_DIR}"
chmod +x "${TMP}/${BINARY}"
mv "${TMP}/${BINARY}" "${INSTALL_DIR}/${BINARY}"

echo "  Installed: ${INSTALL_DIR}/${BINARY}"

# PATH hint
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    echo ""
    echo "  '${INSTALL_DIR}' is not in your PATH. Add this to your shell profile:"
    echo "    export PATH=\"${INSTALL_DIR}:\$PATH\""
    ;;
esac

echo ""
"${INSTALL_DIR}/${BINARY}" version
