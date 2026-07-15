#!/usr/bin/env bash
#
# Install all applications used by Lavenir7/term-config on Ubuntu.
#
# Required applications:
#   tmux, zsh, vim, git, nodejs
#
# Recommended applications:
#   ruby, yazi, superfile, getnf, glow, figlet, lolcat, sl, cowsay
#
# Version policy:
#   - APT packages: compare the installed dpkg version with the current APT
#     candidate version.
#   - GitHub projects: compare the local CLI version with the latest GitHub
#     release.
#   - Ruby gems: compare the installed gem version with RubyGems.
#
# The script is intentionally interactive:
#   - Recommended applications are only installed after confirmation.
#   - Existing applications are upgraded only after confirmation when an
#     older version is detected.
#
# Usage:
#   chmod +x autoConfig/install_apps.sh
#   ./autoConfig/install_apps.sh
#

set -Eeuo pipefail
IFS=$'\n\t'

readonly TERM_CONFIG_FILES_REPO="https://github.com/Lavenir7/term-config-files.git"
readonly TERM_CONFIG_FILES_RAW="https://raw.githubusercontent.com/Lavenir7/term-config-files/main"
readonly YAZI_BUNDLED_ZIP="${TERM_CONFIG_FILES_RAW}/yazi/yazi.zip"
readonly GETNF_INSTALLER="https://raw.githubusercontent.com/getnf/getnf/main/install.sh"
readonly CHARM_GPG_URL="https://repo.charm.sh/apt/gpg.key"
readonly CHARM_APT_SOURCE="deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *"

if [[ -t 1 ]]; then
    readonly RED=$'\033[0;31m'
    readonly GREEN=$'\033[0;32m'
    readonly YELLOW=$'\033[0;33m'
    readonly BLUE=$'\033[0;34m'
    readonly BOLD=$'\033[1m'
    readonly RESET=$'\033[0m'
else
    readonly RED=""
    readonly GREEN=""
    readonly YELLOW=""
    readonly BLUE=""
    readonly BOLD=""
    readonly RESET=""
fi

declare -a INSTALLED_APPS=()
declare -a UPDATED_APPS=()
declare -a CURRENT_APPS=()
declare -a DECLINED_APPS=()
declare -a FAILED_APPS=()

APT_INDEX_READY=0
TMP_ROOT=""

log_info() {
    printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$*"
}

log_ok() {
    printf '%s[ OK ]%s %s\n' "$GREEN" "$RESET" "$*"
}

log_warn() {
    printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*" >&2
}

log_error() {
    printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$*" >&2
}

section() {
    printf '\n%s%s== %s ==%s\n' "$BOLD" "$BLUE" "$*" "$RESET"
}

cleanup() {
    if [[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]]; then
        rm -rf "$TMP_ROOT"
    fi
}
trap cleanup EXIT

on_error() {
    local exit_code=$?
    local line_no=${1:-unknown}
    log_error "脚本在第 ${line_no} 行遇到错误（退出码：${exit_code}）。"
    exit "$exit_code"
}
trap 'on_error "$LINENO"' ERR

ask_yes_no() {
    local prompt=$1
    local default_answer=${2:-N}
    local answer
    local hint

    if [[ "$default_answer" == "Y" ]]; then
        hint="[Y/n]"
    else
        hint="[y/N]"
    fi

    while true; do
        if ! read -r -p "${prompt} ${hint} " answer; then
            printf '\n'
            return 1
        fi

        answer=${answer:-$default_answer}
        case "${answer,,}" in
            y|yes|是)
                return 0
                ;;
            n|no|否)
                return 1
                ;;
            *)
                printf '请输入 y 或 n。\n'
                ;;
        esac
    done
}

record_installed() {
    INSTALLED_APPS+=("$1")
}

record_updated() {
    UPDATED_APPS+=("$1")
}

record_current() {
    CURRENT_APPS+=("$1")
}

record_declined() {
    DECLINED_APPS+=("$1")
}

record_failed() {
    FAILED_APPS+=("$1")
}

require_ubuntu() {
    if [[ ! -r /etc/os-release ]]; then
        log_error "无法识别当前操作系统；此脚本仅支持 Ubuntu。"
        exit 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    if [[ "${ID:-}" != "ubuntu" ]]; then
        log_error "检测到系统为 ${PRETTY_NAME:-unknown}；此脚本目前仅支持 Ubuntu。"
        exit 1
    fi

    log_ok "已检测到 ${PRETTY_NAME:-Ubuntu}。"
}

setup_privilege_command() {
    if (( EUID == 0 )); then
        SUDO=()
    else
        if ! command -v sudo >/dev/null 2>&1; then
            log_error "当前用户不是 root，并且系统中没有 sudo。"
            exit 1
        fi
        SUDO=(sudo)
        sudo -v
    fi
}

run_as_root() {
    "${SUDO[@]}" "$@"
}

apt_update() {
    if (( APT_INDEX_READY == 0 )); then
        log_info "正在刷新 APT 软件包索引..."
        if ! run_as_root apt-get update; then
            log_error "APT 软件包索引刷新失败。"
            return 1
        fi
        APT_INDEX_READY=1
    fi
}

apt_update_force() {
    log_info "正在刷新 APT 软件包索引..."
    if ! run_as_root apt-get update; then
        log_error "APT 软件包索引刷新失败。"
        return 1
    fi
    APT_INDEX_READY=1
}

ensure_support_packages() {
    apt_update
    log_info "正在确认安装脚本所需的基础工具..."
    DEBIAN_FRONTEND=noninteractive run_as_root apt-get install -y \
        ca-certificates curl unzip gnupg tar gzip
}

dpkg_installed_version() {
    local package=$1
    dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true
}

apt_candidate_version() {
    local package=$1
    apt-cache policy "$package" 2>/dev/null |
        awk '/Candidate:/ { print $2; exit }'
}

version_from_text() {
    local text=${1:-}
    printf '%s\n' "$text" |
        grep -oE '[0-9]+([.][0-9A-Za-z~+_-]+)+' |
        head -n 1 ||
        true
}

version_is_at_least() {
    local installed=$1
    local target=$2

    [[ -n "$installed" && -n "$target" ]] &&
        dpkg --compare-versions "$installed" ge "$target"
}

github_latest_tag() {
    local repository=$1
    local response
    local tag

    response=$(
        curl -fsSL --retry 3 --connect-timeout 10 \
            -H 'Accept: application/vnd.github+json' \
            -H 'X-GitHub-Api-Version: 2022-11-28' \
            "https://api.github.com/repos/${repository}/releases/latest" \
            2>/dev/null ||
            true
    )

    tag=$(
        printf '%s\n' "$response" |
            sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' |
            head -n 1
    )

    if [[ -z "$tag" ]]; then
        tag=$(
            curl -fsSLI --retry 3 --connect-timeout 10 \
                -o /dev/null -w '%{url_effective}' \
                "https://github.com/${repository}/releases/latest" \
                2>/dev/null |
                sed -E 's#^.*/tag/##' ||
                true
        )
    fi

    printf '%s\n' "$tag"
}

install_apt_application() {
    local package=$1
    local display_name=$2
    local installed_version
    local candidate_version

    apt_update
    installed_version=$(dpkg_installed_version "$package")
    candidate_version=$(apt_candidate_version "$package")

    if [[ -z "$candidate_version" || "$candidate_version" == "(none)" ]]; then
        log_error "${display_name}：APT 软件源中没有可安装的候选版本。"
        return 1
    fi

    if [[ -z "$installed_version" ]]; then
        log_info "正在安装 ${display_name}（APT 候选版本：${candidate_version}）..."
        if ! DEBIAN_FRONTEND=noninteractive run_as_root apt-get install -y "$package"; then
            log_error "${display_name} 安装失败。"
            return 1
        fi
        record_installed "$display_name"
        log_ok "${display_name} 安装完成。"
        return 0
    fi

    if version_is_at_least "$installed_version" "$candidate_version"; then
        log_ok "${display_name} 已是当前 APT 软件源中的最新版本（${installed_version}）。"
        record_current "$display_name"
        return 0
    fi

    log_warn "${display_name} 当前版本为 ${installed_version}，APT 最新候选版本为 ${candidate_version}。"
    if ask_yes_no "是否将 ${display_name} 更新到 ${candidate_version}？" "N"; then
        if ! DEBIAN_FRONTEND=noninteractive run_as_root apt-get install -y --only-upgrade "$package"; then
            log_error "${display_name} 更新失败。"
            return 1
        fi
        record_updated "$display_name"
        log_ok "${display_name} 已更新。"
    else
        record_declined "${display_name}（拒绝更新）"
        log_info "已保留现有 ${display_name} 版本。"
    fi
}

is_apt_application_installed() {
    [[ -n "$(dpkg_installed_version "$1")" ]]
}

recommended_apt_application() {
    local package=$1
    local display_name=$2
    local installer_function=$3

    if is_apt_application_installed "$package"; then
        "$installer_function"
        return
    fi

    if ask_yes_no "是否安装推荐应用 ${display_name}？" "N"; then
        "$installer_function"
    else
        record_declined "$display_name"
        log_info "已跳过 ${display_name}。"
    fi
}

run_application() {
    local display_name=$1
    local installer_function=$2

    section "$display_name"
    if ! "$installer_function"; then
        record_failed "$display_name"
        log_error "${display_name} 处理失败，继续处理后续应用。"
    fi
}

# ---------------------------------------------------------------------------
# Required applications
# ---------------------------------------------------------------------------

install_tmux() {
    install_apt_application "tmux" "tmux"
}

install_zsh() {
    install_apt_application "zsh" "zsh"
}

install_vim() {
    install_apt_application "vim" "vim"
}

install_git() {
    install_apt_application "git" "git"
}

install_nodejs() {
    install_apt_application "nodejs" "Node.js"
}

# ---------------------------------------------------------------------------
# Recommended applications
# ---------------------------------------------------------------------------

install_ruby() {
    install_apt_application "ruby" "Ruby"
}

yazi_installed_version() {
    local output
    output=$(yazi --version 2>/dev/null || true)
    version_from_text "$output"
}

extract_yazi_archive() {
    local archive=$1
    local destination=$2

    rm -rf "$destination"
    mkdir -p "$destination"
    unzip -q "$archive" -d "$destination"
}

find_yazi_binary() {
    local directory=$1
    find "$directory" -type f -name yazi -print -quit
}

download_official_yazi_zip() {
    local tag=$1
    local output_file=$2
    local machine
    local target

    machine=$(uname -m)
    case "$machine" in
        x86_64|amd64)
            target="x86_64-unknown-linux-gnu"
            ;;
        aarch64|arm64)
            target="aarch64-unknown-linux-gnu"
            ;;
        *)
            log_error "Yazi：暂不支持 CPU 架构 ${machine}。"
            return 1
            ;;
    esac

    local version_without_prefix=${tag#v}
    local tagged_url="https://github.com/sxyazi/yazi/releases/download/${tag}/yazi-${target}.zip"
    local latest_url="https://github.com/sxyazi/yazi/releases/latest/download/yazi-${target}.zip"

    log_info "正在下载 Yazi 官方 ZIP（${version_without_prefix}，${target}）..."
    if ! curl -fL --retry 3 --connect-timeout 10 -o "$output_file" "$tagged_url"; then
        log_warn "按发行标签下载失败，改用 latest 下载地址。"
        curl -fL --retry 3 --connect-timeout 10 -o "$output_file" "$latest_url"
    fi
}

install_yazi() {
    local latest_tag
    local latest_version
    local installed_version
    local bundled_zip="${TMP_ROOT}/yazi-bundled.zip"
    local selected_zip="$bundled_zip"
    local bundled_extract="${TMP_ROOT}/yazi-bundled"
    local selected_extract="$bundled_extract"
    local bundled_binary
    local bundled_version
    local official_zip="${TMP_ROOT}/yazi-official.zip"
    local official_extract="${TMP_ROOT}/yazi-official"
    local binary
    local name

    latest_tag=$(github_latest_tag "sxyazi/yazi")
    latest_version=$(version_from_text "${latest_tag#v}")
    installed_version=$(yazi_installed_version)

    if [[ -z "$latest_version" ]]; then
        log_error "Yazi：无法获取官方最新发行版本，无法可靠执行版本检查。"
        return 1
    fi

    if [[ -n "$installed_version" ]] && version_is_at_least "$installed_version" "$latest_version"; then
        log_ok "Yazi 已是最新版本（${installed_version}）。"
        record_current "Yazi"
        return 0
    fi

    if [[ -n "$installed_version" ]]; then
        log_warn "Yazi 当前版本为 ${installed_version}，官方最新版本为 ${latest_version}。"
        if ! ask_yes_no "是否更新 Yazi 到 ${latest_version}？" "N"; then
            record_declined "Yazi（拒绝更新）"
            return 0
        fi
    fi

    log_info "正在下载 term-config-files 中的 Yazi ZIP..."
    curl -fL --retry 3 --connect-timeout 10 -o "$bundled_zip" "$YAZI_BUNDLED_ZIP"
    extract_yazi_archive "$bundled_zip" "$bundled_extract"

    bundled_binary=$(find_yazi_binary "$bundled_extract")
    if [[ -z "$bundled_binary" ]]; then
        log_error "term-config-files 的 Yazi ZIP 中未找到 yazi 可执行文件。"
        return 1
    fi
    chmod +x "$bundled_binary"
    bundled_version=$(version_from_text "$("$bundled_binary" --version 2>/dev/null || true)")

    if [[ -z "$bundled_version" ]] || ! version_is_at_least "$bundled_version" "$latest_version"; then
        log_warn "资源仓库中的 Yazi ZIP 版本为 ${bundled_version:-未知}，落后于官方最新版本 ${latest_version}。"
        log_info "将继续采用 ZIP 安装方式，但改用官方最新发行包。"
        download_official_yazi_zip "$latest_tag" "$official_zip"
        extract_yazi_archive "$official_zip" "$official_extract"
        selected_zip="$official_zip"
        selected_extract="$official_extract"
    else
        log_ok "资源仓库中的 Yazi ZIP 已对应最新版本 ${bundled_version}。"
    fi

    binary=$(find_yazi_binary "$selected_extract")
    if [[ -z "$binary" ]]; then
        log_error "选定的 Yazi ZIP 中未找到 yazi 可执行文件：${selected_zip}"
        return 1
    fi

    while IFS= read -r binary; do
        name=$(basename "$binary")
        chmod +x "$binary"
        if ! run_as_root install -m 0755 "$binary" "/usr/local/bin/${name}"; then
            log_error "无法安装 ${name} 到 /usr/local/bin。"
            return 1
        fi
    done < <(
        find "$selected_extract" -type f \( -name yazi -o -name ya \) -print
    )

    if [[ -n "$installed_version" ]]; then
        record_updated "Yazi"
        log_ok "Yazi 已更新到 $(yazi_installed_version)。"
    else
        record_installed "Yazi"
        log_ok "Yazi 安装完成（$(yazi_installed_version)）。"
    fi
}

superfile_binary() {
    if command -v spf >/dev/null 2>&1; then
        command -v spf
    elif [[ -x "$HOME/.local/bin/spf" ]]; then
        printf '%s\n' "$HOME/.local/bin/spf"
    else
        return 1
    fi
}

superfile_installed_version() {
    local binary
    local output

    binary=$(superfile_binary 2>/dev/null || true)
    [[ -n "$binary" ]] || return 0

    output=$("$binary" --version 2>/dev/null || "$binary" -v 2>/dev/null || true)
    version_from_text "$output"
}

install_superfile() {
    local latest_tag
    local latest_version
    local installed_version
    local clone_dir="${TMP_ROOT}/term-config-files-superfile"
    local installer="${clone_dir}/superfile/install.sh"
    local pinned_version

    latest_tag=$(github_latest_tag "yorukot/superfile")
    latest_version=$(version_from_text "${latest_tag#v}")
    installed_version=$(superfile_installed_version)

    if [[ -z "$latest_version" ]]; then
        log_error "Superfile：无法获取官方最新发行版本。"
        return 1
    fi

    if [[ -n "$installed_version" ]] && version_is_at_least "$installed_version" "$latest_version"; then
        log_ok "Superfile 已是最新版本（${installed_version}）。"
        record_current "Superfile"
        return 0
    fi

    if [[ -n "$installed_version" ]]; then
        log_warn "Superfile 当前版本为 ${installed_version}，官方最新版本为 ${latest_version}。"
        if ! ask_yes_no "是否更新 Superfile 到 ${latest_version}？" "N"; then
            record_declined "Superfile（拒绝更新）"
            return 0
        fi
    fi

    log_info "正在从 term-config-files 获取 Superfile 安装脚本和本地安装包..."
    rm -rf "$clone_dir"
    if ! git clone --depth 1 --filter=blob:none --sparse "$TERM_CONFIG_FILES_REPO" "$clone_dir"; then
        log_error "term-config-files 克隆失败。"
        return 1
    fi
    if ! git -C "$clone_dir" sparse-checkout set superfile; then
        log_error "无法检出 term-config-files/superfile。"
        return 1
    fi

    if [[ ! -f "$installer" ]]; then
        log_error "未找到 Superfile 安装脚本：${installer}"
        return 1
    fi

    pinned_version=$(
        sed -nE 's/^[[:space:]]*version=([^[:space:]]+).*/\1/p' "$installer" |
            head -n 1
    )

    if [[ -n "$pinned_version" && "$pinned_version" != "$latest_version" ]]; then
        log_warn "资源仓库安装脚本固定版本为 ${pinned_version}；将其临时对齐到最新版本 ${latest_version}。"
        sed -i -E \
            "s/^([[:space:]]*version=).*/\1${latest_version}/" \
            "$installer"
    fi

    chmod +x "$installer"
    if ! (
        cd "$(dirname "$installer")"
        bash "./$(basename "$installer")"
    ); then
        log_error "Superfile 安装脚本执行失败。"
        return 1
    fi

    if [[ -n "$installed_version" ]]; then
        record_updated "Superfile"
        log_ok "Superfile 已更新到 $(superfile_installed_version)。"
    else
        record_installed "Superfile"
        log_ok "Superfile 安装完成（$(superfile_installed_version)）。"
    fi
}

getnf_binary() {
    if command -v getnf >/dev/null 2>&1; then
        command -v getnf
    elif [[ -x "$HOME/.local/bin/getnf" ]]; then
        printf '%s\n' "$HOME/.local/bin/getnf"
    else
        return 1
    fi
}

getnf_installed_version() {
    local binary
    binary=$(getnf_binary 2>/dev/null || true)
    [[ -n "$binary" ]] || return 0
    version_from_text "$("$binary" -V 2>/dev/null || true)"
}

install_getnf() {
    local latest_tag
    local latest_version
    local installed_version

    latest_tag=$(github_latest_tag "getnf/getnf")
    latest_version=$(version_from_text "${latest_tag#v}")
    installed_version=$(getnf_installed_version)

    if [[ -z "$latest_version" ]]; then
        log_error "getnf：无法获取官方最新发行版本。"
        return 1
    fi

    if [[ -n "$installed_version" ]] && version_is_at_least "$installed_version" "$latest_version"; then
        log_ok "getnf 已是最新版本（${installed_version}）。"
        record_current "getnf"
        return 0
    fi

    if [[ -n "$installed_version" ]]; then
        log_warn "getnf 当前版本为 ${installed_version}，官方最新版本为 ${latest_version}。"
        if ! ask_yes_no "是否更新 getnf 到 ${latest_version}？" "N"; then
            record_declined "getnf（拒绝更新）"
            return 0
        fi
    fi

    log_info "正在按照配置仓库中的方式，通过 getnf 安装脚本安装 ${latest_tag}..."
    if ! curl -fsSL --retry 3 --connect-timeout 10 "$GETNF_INSTALLER" |
        zsh -s -- "--tag=${latest_tag}"; then
        log_error "getnf 安装脚本执行失败。"
        return 1
    fi

    if [[ -n "$installed_version" ]]; then
        record_updated "getnf"
        log_ok "getnf 已更新到 $(getnf_installed_version)。"
    else
        record_installed "getnf"
        log_ok "getnf 安装完成（$(getnf_installed_version)）。"
    fi
}

configure_charm_repository() {
    local keyring="/etc/apt/keyrings/charm.gpg"
    local source_file="/etc/apt/sources.list.d/charm.list"
    local temp_key="${TMP_ROOT}/charm.gpg"

    if ! run_as_root mkdir -p /etc/apt/keyrings; then
        return 1
    fi

    log_info "正在配置 Charm APT 软件源..."
    if ! curl -fsSL --retry 3 --connect-timeout 10 "$CHARM_GPG_URL" |
        gpg --dearmor --yes -o "$temp_key"; then
        log_error "Charm APT 仓库签名密钥下载或转换失败。"
        return 1
    fi
    if ! run_as_root install -m 0644 "$temp_key" "$keyring"; then
        return 1
    fi

    if ! printf '%s\n' "$CHARM_APT_SOURCE" |
        run_as_root tee "$source_file" >/dev/null; then
        log_error "Charm APT 软件源配置写入失败。"
        return 1
    fi

    apt_update_force
}

install_glow() {
    configure_charm_repository
    install_apt_application "glow" "Glow"
}

install_figlet() {
    install_apt_application "figlet" "figlet"
}

lolcat_installed_version() {
    ruby -e '
        specs = Gem::Specification.find_all_by_name("lolcat")
        puts specs.max_by(&:version).version unless specs.empty?
    ' 2>/dev/null || true
}

lolcat_latest_version() {
    gem list --remote --exact lolcat 2>/dev/null |
        sed -nE 's/^lolcat \(([^,)]*).*/\1/p' |
        head -n 1
}

install_lolcat() {
    local installed_version
    local latest_version

    if ! command -v ruby >/dev/null 2>&1 || ! command -v gem >/dev/null 2>&1; then
        log_warn "lolcat 依赖 Ruby；将先安装 Ruby。"
        if ! install_ruby; then
            log_error "Ruby 安装失败，无法继续安装 lolcat。"
            return 1
        fi
    fi

    installed_version=$(lolcat_installed_version)
    latest_version=$(lolcat_latest_version)

    if [[ -z "$latest_version" ]]; then
        log_error "lolcat：无法从 RubyGems 获取最新版本。"
        return 1
    fi

    if [[ -n "$installed_version" ]] && version_is_at_least "$installed_version" "$latest_version"; then
        log_ok "lolcat 已是最新版本（${installed_version}）。"
        record_current "lolcat"
        return 0
    fi

    if [[ -n "$installed_version" ]]; then
        log_warn "lolcat 当前版本为 ${installed_version}，RubyGems 最新版本为 ${latest_version}。"
        if ! ask_yes_no "是否更新 lolcat 到 ${latest_version}？" "N"; then
            record_declined "lolcat（拒绝更新）"
            return 0
        fi
    fi

    log_info "正在通过 RubyGems 安装 lolcat ${latest_version}..."
    if ! run_as_root gem install lolcat --no-document; then
        log_error "lolcat 安装失败。"
        return 1
    fi

    if [[ -n "$installed_version" ]]; then
        record_updated "lolcat"
        log_ok "lolcat 已更新到 $(lolcat_installed_version)。"
    else
        record_installed "lolcat"
        log_ok "lolcat 安装完成（$(lolcat_installed_version)）。"
    fi
}

install_sl() {
    install_apt_application "sl" "sl"
}

install_cowsay() {
    install_apt_application "cowsay" "cowsay"
}

# ---------------------------------------------------------------------------
# Recommended-app dispatchers
# ---------------------------------------------------------------------------

recommend_ruby() {
    recommended_apt_application "ruby" "Ruby" install_ruby
}

recommend_yazi() {
    if command -v yazi >/dev/null 2>&1; then
        install_yazi
    elif ask_yes_no "是否安装推荐应用 Yazi？" "N"; then
        install_yazi
    else
        record_declined "Yazi"
        log_info "已跳过 Yazi。"
    fi
}

recommend_superfile() {
    if [[ -n "$(superfile_binary 2>/dev/null || true)" ]]; then
        install_superfile
    elif ask_yes_no "是否安装推荐应用 Superfile？" "N"; then
        install_superfile
    else
        record_declined "Superfile"
        log_info "已跳过 Superfile。"
    fi
}

recommend_getnf() {
    if [[ -n "$(getnf_binary 2>/dev/null || true)" ]]; then
        install_getnf
    elif ask_yes_no "是否安装推荐应用 getnf？" "N"; then
        install_getnf
    else
        record_declined "getnf"
        log_info "已跳过 getnf。"
    fi
}

recommend_glow() {
    recommended_apt_application "glow" "Glow" install_glow
}

recommend_figlet() {
    recommended_apt_application "figlet" "figlet" install_figlet
}

recommend_lolcat() {
    if [[ -n "$(lolcat_installed_version)" ]] || command -v lolcat >/dev/null 2>&1; then
        install_lolcat
    elif ask_yes_no "是否安装推荐应用 lolcat？" "N"; then
        install_lolcat
    else
        record_declined "lolcat"
        log_info "已跳过 lolcat。"
    fi
}

recommend_sl() {
    recommended_apt_application "sl" "sl" install_sl
}

recommend_cowsay() {
    recommended_apt_application "cowsay" "cowsay" install_cowsay
}

print_list() {
    local title=$1
    shift
    local -a values=("$@")
    local value

    ((${#values[@]} > 0)) || return 0
    printf '%s:\n' "$title"
    for value in "${values[@]}"; do
        printf '  - %s\n' "$value"
    done
}

print_summary() {
    section "执行结果"
    print_list "新安装" "${INSTALLED_APPS[@]}"
    print_list "已更新" "${UPDATED_APPS[@]}"
    print_list "已是最新" "${CURRENT_APPS[@]}"
    print_list "用户跳过" "${DECLINED_APPS[@]}"
    print_list "处理失败" "${FAILED_APPS[@]}"

    if ((${#FAILED_APPS[@]} == 0)); then
        log_ok "应用安装与版本检查流程已完成。"
    else
        log_warn "流程已完成，但有 ${#FAILED_APPS[@]} 个应用处理失败。"
    fi
}

main() {
    export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
    TMP_ROOT=$(mktemp -d -t term-config-apps.XXXXXXXX)

    printf '%s%sTerm Config - Ubuntu 应用一键安装器%s\n' "$BOLD" "$GREEN" "$RESET"
    printf '必装应用会自动安装；推荐应用会逐项询问。\n'
    printf '检测到旧版本时，脚本会询问是否更新。\n'

    require_ubuntu
    setup_privilege_command
    ensure_support_packages

    section "必装应用"
    run_application "tmux" install_tmux
    run_application "zsh" install_zsh
    run_application "vim" install_vim
    run_application "git" install_git
    run_application "Node.js" install_nodejs

    section "推荐应用"
    run_application "Ruby" recommend_ruby
    run_application "Yazi" recommend_yazi
    run_application "Superfile" recommend_superfile
    run_application "getnf" recommend_getnf
    run_application "Glow" recommend_glow
    run_application "figlet" recommend_figlet
    run_application "lolcat" recommend_lolcat
    run_application "sl" recommend_sl
    run_application "cowsay" recommend_cowsay

    print_summary

    if ((${#FAILED_APPS[@]} > 0)); then
        return 1
    fi
}

main "$@"
