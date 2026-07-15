#!/usr/bin/env bash
# One-click installer for term-config's img2chr and wd commands.
# Source: https://github.com/Lavenir7/term-config-files/tree/main/scripts
set -Eeuo pipefail
IFS=$'\n\t'
umask 022

readonly APP_NAME="term-config-shell"
readonly RAW_BASE="https://raw.githubusercontent.com/Lavenir7/term-config-files/refs/heads/main/scripts"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
APP_HOME="${TERM_CONFIG_SHELL_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/${APP_NAME}}"
SOURCE_DIR="${APP_HOME}/scripts"
VENV_DIR="${APP_HOME}/venv"
TEMP_DIR=""
PYTHON_BIN=""

log() {
  printf '[term-config] %s\n' "$*"
}

warn() {
  printf '[term-config] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[term-config] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    rm -rf -- "${TEMP_DIR}"
  fi
}

on_error() {
  local exit_code=$?
  printf '[term-config] ERROR: installation failed at line %s: %s\n' \
    "${BASH_LINENO[0]:-unknown}" "${BASH_COMMAND:-unknown}" >&2
  exit "${exit_code}"
}

trap cleanup EXIT
trap on_error ERR

usage() {
  cat <<'EOF'
Usage:
  bash install_shell.sh

Optional environment variables:
  INSTALL_DIR              Command installation directory
                           Default: $HOME/.local/bin
  TERM_CONFIG_SHELL_HOME   Private application data directory
                           Default: ${XDG_DATA_HOME:-$HOME/.local/share}/term-config-shell
EOF
}

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "Root privileges are required to install system packages, but sudo is unavailable."
  fi
}

install_system_dependencies() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Installing Debian/Ubuntu system dependencies..."
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get update
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      ca-certificates curl ncurses-bin python3 python3-venv
  elif command -v pkg >/dev/null 2>&1; then
    log "Installing Termux system dependencies..."
    pkg update -y
    pkg install -y ca-certificates curl ncurses-utils python
  else
    warn "No supported package manager was found; system packages will not be installed automatically."
  fi
}

select_python() {
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python3)"
  elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python)"
  else
    die "Python 3 is required but was not found."
  fi

  "${PYTHON_BIN}" - <<'PY'
import sys
if sys.version_info < (3, 8):
    raise SystemExit("Python 3.8 or newer is required.")
PY
}

download_file() {
  local url=$1
  local destination=$2

  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error \
      --retry 3 --retry-delay 1 \
      --output "${destination}" "${url}"
  elif command -v wget >/dev/null 2>&1; then
    wget --quiet --tries=3 --output-document="${destination}" "${url}"
  else
    die "curl or wget is required to download the command files."
  fi
}

validate_source() {
  local file=$1
  local name=$2

  [[ -s "${file}" ]] || die "Downloaded ${name} is empty."
  head -n 1 "${file}" | grep -q 'python' \
    || die "Downloaded ${name} does not look like a Python script."
}

create_virtual_environment() {
  log "Creating an isolated Python environment..."
  mkdir -p -- "${APP_HOME}"

  if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
  fi

  "${VENV_DIR}/bin/python" -m pip install \
    --disable-pip-version-check --upgrade pip setuptools wheel

  log "Installing Python dependencies: Pillow, Beautiful Soup 4, lxml..."
  "${VENV_DIR}/bin/python" -m pip install \
    --disable-pip-version-check --upgrade \
    pillow beautifulsoup4 lxml
}

install_sources() {
  TEMP_DIR="$(mktemp -d)"
  log "Downloading img2chr and wd from term-config-files..."

  download_file "${RAW_BASE}/img2chr" "${TEMP_DIR}/img2chr"
  download_file "${RAW_BASE}/wd" "${TEMP_DIR}/wd"

  validate_source "${TEMP_DIR}/img2chr" "img2chr"
  validate_source "${TEMP_DIR}/wd" "wd"

  mkdir -p -- "${SOURCE_DIR}"
  cp -- "${TEMP_DIR}/img2chr" "${SOURCE_DIR}/img2chr"
  cp -- "${TEMP_DIR}/wd" "${SOURCE_DIR}/wd"
  chmod 0755 "${SOURCE_DIR}/img2chr" "${SOURCE_DIR}/wd"
}

install_wrappers() {
  local img_wrapper="${TEMP_DIR}/img2chr.wrapper"
  local wd_wrapper="${TEMP_DIR}/wd.wrapper"

  cat >"${img_wrapper}" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
APP_HOME="${TERM_CONFIG_SHELL_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/term-config-shell}"
exec "${APP_HOME}/venv/bin/python" "${APP_HOME}/scripts/img2chr" "$@"
EOF

  cat >"${wd_wrapper}" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
APP_HOME="${TERM_CONFIG_SHELL_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/term-config-shell}"
exec "${APP_HOME}/venv/bin/python" "${APP_HOME}/scripts/wd" "$@"
EOF

  mkdir -p -- "${INSTALL_DIR}"
  cp -- "${img_wrapper}" "${INSTALL_DIR}/img2chr"
  cp -- "${wd_wrapper}" "${INSTALL_DIR}/wd"
  chmod 0755 "${INSTALL_DIR}/img2chr" "${INSTALL_DIR}/wd"
}

ensure_local_bin_on_path() {
  local export_line='export PATH="$HOME/.local/bin:$PATH"'
  local rc_file

  if [[ "${INSTALL_DIR}" != "${HOME}/.local/bin" ]]; then
    warn "Custom INSTALL_DIR is in use; ensure it is present in PATH: ${INSTALL_DIR}"
    return
  fi

  for rc_file in "${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [[ "${rc_file}" != "${HOME}/.profile" && ! -e "${rc_file}" ]]; then
      continue
    fi

    touch "${rc_file}"
    if ! grep -Fqx "${export_line}" "${rc_file}"; then
      {
        printf '\n# Added by term-config autoConfig/install_shell.sh\n'
        printf '%s\n' "${export_line}"
      } >>"${rc_file}"
    fi
  done
}

verify_installation() {
  log "Verifying installation..."

  "${VENV_DIR}/bin/python" - <<'PY'
from PIL import Image
import bs4
import lxml
PY

  [[ -x "${INSTALL_DIR}/img2chr" ]] || die "img2chr command was not installed."
  [[ -x "${INSTALL_DIR}/wd" ]] || die "wd command was not installed."

  "${INSTALL_DIR}/img2chr" --version >/dev/null
}

main() {
  case "${1:-}" in
    "")
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Unknown argument: ${1}"
      ;;
  esac

  install_system_dependencies
  select_python
  create_virtual_environment
  install_sources
  install_wrappers
  ensure_local_bin_on_path
  verify_installation

  log "Installation complete."
  printf '\nInstalled commands:\n'
  printf '  %s\n' "${INSTALL_DIR}/img2chr"
  printf '  %s\n' "${INSTALL_DIR}/wd"
  printf '\nOpen a new terminal, or run:\n'
  printf '  export PATH="%s:$PATH"\n' "${INSTALL_DIR}"
  printf '\nExamples:\n'
  printf '  img2chr path/to/image.png\n'
  printf '  wd hello\n'
}

main "$@"
