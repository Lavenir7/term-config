#!/usr/bin/env bash

set -uo pipefail
IFS=$'\n\t'

readonly TERM_CONFIG_FILES_REPO="https://github.com/Lavenir7/term-config-files.git"
TERM_CONFIG_FILES_DIR="${TERM_CONFIG_FILES_DIR:-${HOME}/term-config-files}"
readonly LOCAL_BIN="${HOME}/.local/bin"

APT_UPDATED=0
AUTO_YES=0

declare -a INSTALLED_APPS=()
declare -a UPDATED_APPS=()
declare -a EXISTING_APPS=()
declare -a SKIPPED_APPS=()
declare -a FAILED_APPS=()

log() {
    printf '[term-config] %s\n' "$*"
}

warn() {
    printf '[term-config] WARNING: %s\n' "$*" >&2
}

add_result() {
    local array_name=$1
    local value=$2
    local -n result_array="${array_name}"
    local item

    for item in "${result_array[@]:-}"; do
        [[ "${item}" == "${value}" ]] && return 0
    done
    result_array+=("${value}")
}

remove_result() {
    local array_name=$1
    local value=$2
    local -n result_array="${array_name}"
    local -a kept=()
    local item

    for item in "${result_array[@]:-}"; do
        [[ -n "${item}" && "${item}" != "${value}" ]] && kept+=("${item}")
    done
    result_array=("${kept[@]}")
}

usage() {
    printf '用法: %s [-y|--yes]\n' "${0##*/}"
    printf '  -y, --yes  安装所有未安装的应用；已存在的应用不更新。\n'
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)
                AUTO_YES=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                warn "未知参数: $1"
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
}

ask_yes_no() {
    local prompt=$1
    local default_answer=${2:-N}
    local answer
    local hint='[y/N]'

    if [[ ${AUTO_YES} -eq 1 ]]; then
        log "${prompt} 自动选择: y"
        return 0
    fi

    [[ "${default_answer}" == 'Y' ]] && hint='[Y/n]'

    while true; do
        read -r -p "${prompt} ${hint} " answer || return 1
        answer=${answer:-${default_answer}}
        case "${answer}" in
            y|Y|yes|YES|Yes) return 0 ;;
            n|N|no|NO|No) return 1 ;;
            *) printf '请输入 y 或 n。\n' ;;
        esac
    done
}

ask_choice() {
    local prompt=$1
    shift
    local choice
    local valid

    if [[ ${AUTO_YES} -eq 1 ]]; then
        printf '[term-config] %s 自动选择: %s\n' \
            "${prompt%%$'\\n'*}" "$1" >&2
        printf '%s\n' "$1"
        return 0
    fi

    while true; do
        printf '%s\n' "${prompt}" >&2
        read -r -p '请输入选项编号: ' choice || return 1
        for valid in "$@"; do
            if [[ "${choice}" == "${valid}" ]]; then
                printf '%s\n' "${choice}"
                return 0
            fi
        done
        printf '无效选项，请重新输入。\n' >&2
    done
}

run_as_root() {
    if [[ ${EUID} -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        warn '需要 root 权限，但系统中没有 sudo。'
        return 1
    fi
}

check_ubuntu() {
    if [[ ! -r /etc/os-release ]]; then
        printf '无法识别操作系统；此脚本仅支持 Ubuntu。\n' >&2
        exit 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != 'ubuntu' ]]; then
        printf '当前系统不是 Ubuntu；此脚本仅支持 Ubuntu。\n' >&2
        exit 1
    fi
}

ensure_apt_updated() {
    if [[ ${APT_UPDATED} -eq 0 ]]; then
        log '更新 APT 软件包索引...'
        if ! run_as_root apt-get update; then
            warn 'APT 软件包索引更新失败。'
            return 1
        fi
        APT_UPDATED=1
    fi
}

apt_installed_version() {
    dpkg-query -W -f='${Status} ${Version}\n' "$1" 2>/dev/null \
        | awk '$1 == "install" && $2 == "ok" && $3 == "installed" {print $4}'
}

apt_candidate_version() {
    apt-cache policy "$1" 2>/dev/null \
        | awk '/Candidate:/ {print $2; exit}'
}

install_apt_dependency() {
    local package=$1

    if [[ -n "$(apt_installed_version "${package}")" ]]; then
        return 0
    fi

    ensure_apt_updated || return 1
    log "安装依赖: ${package}"
    run_as_root apt-get install -y "${package}"
}

install_apt_app() {
    local app_name=$1
    local package=$2
    local install_type=$3
    local installed_version
    local candidate_version

    ensure_apt_updated || {
        add_result FAILED_APPS "${app_name}（APT 更新失败）"
        return 1
    }

    installed_version=$(apt_installed_version "${package}")
    candidate_version=$(apt_candidate_version "${package}")

    if [[ -n "${installed_version}" ]]; then
        if [[ -z "${candidate_version}" || "${candidate_version}" == '(none)' ]] \
            || dpkg --compare-versions "${installed_version}" ge "${candidate_version}"; then
            log "${app_name} 已是软件源中的最新版本 (${installed_version})。"
            add_result EXISTING_APPS "${app_name}"
            return 0
        fi

        printf '%s 当前版本: %s，最新版本: %s。\n' \
            "${app_name}" "${installed_version}" "${candidate_version}"
        if [[ ${AUTO_YES} -eq 1 ]]; then
            log "-y 模式不更新已存在的 ${app_name}。"
            add_result EXISTING_APPS "${app_name}（未更新）"
            return 0
        fi
        if ! ask_yes_no "是否更新 ${app_name} 到最新版本？" N; then
            add_result EXISTING_APPS "${app_name}（未更新）"
            return 0
        fi

        if run_as_root apt-get install -y "${package}"; then
            add_result UPDATED_APPS "${app_name}"
            return 0
        fi

        add_result FAILED_APPS "${app_name}（更新失败）"
        return 1
    fi

    if [[ "${install_type}" == 'recommended' ]] \
        && ! ask_yes_no "${app_name} 是推荐应用，是否安装？" N; then
        add_result SKIPPED_APPS "${app_name}"
        return 0
    fi

    if [[ -z "${candidate_version}" || "${candidate_version}" == '(none)' ]]; then
        warn "APT 软件源中找不到 ${package}。"
        add_result FAILED_APPS "${app_name}（软件源中不存在）"
        return 1
    fi

    if run_as_root apt-get install -y "${package}"; then
        add_result INSTALLED_APPS "${app_name}"
        return 0
    fi

    add_result FAILED_APPS "${app_name}（安装失败）"
    return 1
}

ensure_term_config_files() {
    if [[ -d "${TERM_CONFIG_FILES_DIR}" ]]; then
        return 0
    fi

    if [[ -e "${TERM_CONFIG_FILES_DIR}" ]]; then
        warn "${TERM_CONFIG_FILES_DIR} 已存在，但不是目录。"
        return 1
    fi

    install_apt_dependency git || return 1
    log "克隆 term-config-files 到 ${TERM_CONFIG_FILES_DIR}..."
    git clone "${TERM_CONFIG_FILES_REPO}" "${TERM_CONFIG_FILES_DIR}"
}

install_to_local_bin() {
    local source_file=$1
    local command_name=$2

    mkdir -p "${LOCAL_BIN}"
    install -m 0755 "${source_file}" "${LOCAL_BIN}/${command_name}"
    export PATH="${LOCAL_BIN}:${PATH}"
    hash -r
}

command_exists() {
    command -v "$1" >/dev/null 2>&1 || [[ -x "${LOCAL_BIN}/$1" ]]
}

extract_version() {
    grep -oE '[0-9]+([.][0-9]+)+' | head -n 1
}

normalize_version() {
    printf '%s\n' "$1" | extract_version
}

github_latest_tag() {
    local repository=$1
    local tag
    local final_url

    install_apt_dependency curl >/dev/null 2>&1 || return 1

    tag=$(curl -fsSL \
        -H 'Accept: application/vnd.github+json' \
        "https://api.github.com/repos/${repository}/releases/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n 1)

    if [[ -n "${tag}" ]]; then
        printf '%s\n' "${tag}"
        return 0
    fi

    final_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
        "https://github.com/${repository}/releases/latest" 2>/dev/null) || return 1
    tag=${final_url##*/}
    [[ -n "${tag}" && "${tag}" != 'latest' ]] || return 1
    printf '%s\n' "${tag}"
}

needs_github_update() {
    local app_name=$1
    local command_name=$2
    local version_args=$3
    local repository=$4
    local current_version

    if [[ ${AUTO_YES} -eq 1 ]]; then
        log "-y 模式不更新已存在的 ${app_name}。"
        return 1
    fi
    local latest_tag
    local latest_version

    current_version=$("${command_name}" ${version_args} 2>&1 | extract_version || true)
    latest_tag=$(github_latest_tag "${repository}" || true)
    latest_version=$(normalize_version "${latest_tag}" || true)

    if [[ -n "${current_version}" && -n "${latest_version}" ]] \
        && dpkg --compare-versions "${current_version}" ge "${latest_version}"; then
        log "${app_name} 已是最新版本 (${current_version})。"
        return 1
    fi

    if [[ -n "${current_version}" && -n "${latest_version}" ]]; then
        printf '%s 当前版本: %s，最新版本: %s。\n' \
            "${app_name}" "${current_version}" "${latest_version}"
    else
        warn "无法可靠获取 ${app_name} 的当前版本或最新版本。"
    fi

    ask_yes_no "是否更新 ${app_name}？" N
}

set_zsh_as_default_shell() {
    local zsh_path
    local current_shell

    zsh_path=$(command -v zsh) || {
        add_result FAILED_APPS 'zsh（无法获取可执行文件路径）'
        return 1
    }
    current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)

    if [[ "${current_shell}" == "${zsh_path}" ]]; then
        log 'zsh 已是当前用户的默认 Shell。'
        add_result EXISTING_APPS 'zsh（默认 Shell）'
    elif chsh -s "${zsh_path}"; then
        add_result UPDATED_APPS 'zsh（设为默认 Shell）'
    else
        add_result FAILED_APPS 'zsh（设置默认 Shell 失败）'
        return 1
    fi
}

oh_my_zsh_dir() {
    printf '%s\n' "${ZSH:-${HOME}/.oh-my-zsh}"
}

zsh_custom_dir() {
    local zsh_dir
    zsh_dir=$(oh_my_zsh_dir)
    printf '%s\n' "${ZSH_CUSTOM:-${zsh_dir}/custom}"
}

install_oh_my_zsh() {
    local install_dir
    install_dir=$(oh_my_zsh_dir)

    if [[ -d "${install_dir}" ]]; then
        log "Oh My Zsh 已存在于 ${install_dir}。"
        add_result EXISTING_APPS 'Oh My Zsh'
        return 0
    fi

    if ! install_apt_dependency curl || ! install_apt_dependency git; then
        add_result FAILED_APPS 'Oh My Zsh（依赖安装失败）'
        return 1
    fi

    if RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended; then
        add_result INSTALLED_APPS 'Oh My Zsh'
    else
        add_result FAILED_APPS 'Oh My Zsh（安装失败）'
        return 1
    fi
}

install_oh_my_zsh_component() {
    local app_name=$1
    local repository=$2
    local relative_path=$3
    local install_dir
    local target_dir

    install_dir=$(oh_my_zsh_dir)
    if [[ ! -d "${install_dir}" ]]; then
        warn "${app_name} 需要先安装 Oh My Zsh。"
        add_result FAILED_APPS "${app_name}（需要 Oh My Zsh）"
        return 1
    fi

    target_dir="$(zsh_custom_dir)/${relative_path}"
    if [[ -d "${target_dir}" ]]; then
        log "${app_name} 已存在。"
        add_result EXISTING_APPS "${app_name}"
        return 0
    fi

    if ! install_apt_dependency git; then
        add_result FAILED_APPS "${app_name}（git 安装失败）"
        return 1
    fi
    mkdir -p "$(dirname "${target_dir}")"

    if git clone "${repository}" "${target_dir}"; then
        add_result INSTALLED_APPS "${app_name}"
    else
        add_result FAILED_APPS "${app_name}（安装失败）"
        return 1
    fi
}

install_zsh_autosuggestions() {
    install_oh_my_zsh_component \
        zsh-autosuggestions \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        plugins/zsh-autosuggestions
}

install_zsh_syntax_highlighting() {
    install_oh_my_zsh_component \
        zsh-syntax-highlighting \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        plugins/zsh-syntax-highlighting
}

install_powerlevel10k() {
    install_oh_my_zsh_component \
        Powerlevel10k \
        https://github.com/romkatv/powerlevel10k.git \
        themes/powerlevel10k
}

configure_zsh() {
    if ask_yes_no '是否将 zsh 设置为当前用户的默认 Shell？' N; then
        set_zsh_as_default_shell || true
    else
        add_result SKIPPED_APPS 'zsh（设置默认 Shell）'
    fi

    if ask_yes_no '是否安装 Oh My Zsh？' N; then
        install_oh_my_zsh || true
    else
        add_result SKIPPED_APPS 'Oh My Zsh'
    fi

    if ask_yes_no '是否安装 Oh My Zsh 的 zsh-autosuggestions 插件？' N; then
        install_zsh_autosuggestions || true
    else
        add_result SKIPPED_APPS 'zsh-autosuggestions'
    fi

    if ask_yes_no '是否安装 Oh My Zsh 的 zsh-syntax-highlighting 插件？' N; then
        install_zsh_syntax_highlighting || true
    else
        add_result SKIPPED_APPS 'zsh-syntax-highlighting'
    fi

    if ask_yes_no '是否安装 Powerlevel10k 主题？' N; then
        install_powerlevel10k || true
    else
        add_result SKIPPED_APPS 'Powerlevel10k'
    fi
}

install_tmux() { install_apt_app tmux tmux required; }
install_zsh() {
    install_apt_app zsh zsh required || return 1
    configure_zsh
}
install_vim() { install_apt_app vim vim required; }
install_git() { install_apt_app git git required; }
install_nodejs() {
    install_apt_app nodejs nodejs required || return 1
    install_apt_app npm npm required
}
install_ruby() { install_apt_app ruby ruby recommended; }
install_figlet() { install_apt_app figlet figlet recommended; }
install_sl() { install_apt_app sl sl recommended; }
install_cowsay() { install_apt_app cowsay cowsay recommended; }

install_img2chr() {
    local source_file

    if command_exists img2chr; then
        log 'img2chr 已存在；使用本地仓库文件的应用不检查版本。'
        add_result EXISTING_APPS 'img2chr'
        return 0
    fi

    if ! ask_yes_no 'img2chr 是推荐应用，是否安装？' N; then
        add_result SKIPPED_APPS 'img2chr'
        return 0
    fi

    ensure_term_config_files || {
        add_result FAILED_APPS 'img2chr（term-config-files 不可用）'
        return 1
    }
    source_file="${TERM_CONFIG_FILES_DIR}/scripts/img2chr"
    [[ -f "${source_file}" ]] || {
        add_result FAILED_APPS 'img2chr（源文件不存在）'
        return 1
    }

    if ! install_apt_dependency python3 \
        || ! install_apt_dependency python3-pil \
        || ! install_apt_dependency ncurses-bin; then
        add_result FAILED_APPS 'img2chr（依赖安装失败）'
        return 1
    fi

    if install_to_local_bin "${source_file}" img2chr; then
        add_result INSTALLED_APPS 'img2chr'
        return 0
    fi

    add_result FAILED_APPS 'img2chr（安装失败）'
    return 1
}

install_wd() {
    local source_file

    if command_exists wd; then
        log 'wd 已存在；使用本地仓库文件的应用不检查版本。'
        add_result EXISTING_APPS 'wd'
        return 0
    fi

    if ! ask_yes_no 'wd 是推荐应用，是否安装？' N; then
        add_result SKIPPED_APPS 'wd'
        return 0
    fi

    ensure_term_config_files || {
        add_result FAILED_APPS 'wd（term-config-files 不可用）'
        return 1
    }
    source_file="${TERM_CONFIG_FILES_DIR}/scripts/wd"
    [[ -f "${source_file}" ]] || {
        add_result FAILED_APPS 'wd（源文件不存在）'
        return 1
    }

    if ! install_apt_dependency python3 \
        || ! install_apt_dependency python3-bs4 \
        || ! install_apt_dependency python3-lxml; then
        add_result FAILED_APPS 'wd（依赖安装失败）'
        return 1
    fi

    if install_to_local_bin "${source_file}" wd; then
        add_result INSTALLED_APPS 'wd'
        return 0
    fi

    add_result FAILED_APPS 'wd（安装失败）'
    return 1
}

install_system_binary() {
    local source_file=$1
    local command_name=$2

    if run_as_root install -m 0755 "${source_file}" "/usr/local/bin/${command_name}"; then
        hash -r
        return 0
    fi

    warn "无法写入 /usr/local/bin，改为安装到 ${LOCAL_BIN}。"
    install_to_local_bin "${source_file}" "${command_name}"
}

install_yazi_archive() {
    local method=$1
    local temp_dir
    local archive
    local binary

    install_apt_dependency unzip || return 1
    temp_dir=$(mktemp -d) || return 1
    archive="${temp_dir}/yazi.zip"

    if [[ "${method}" == '1' ]]; then
        ensure_term_config_files || {
            rm -rf "${temp_dir}"
            return 1
        }
        if [[ ! -f "${TERM_CONFIG_FILES_DIR}/yazi/yazi.zip" ]]; then
            warn 'term-config-files/yazi/yazi.zip 不存在。'
            rm -rf "${temp_dir}"
            return 1
        fi
        cp "${TERM_CONFIG_FILES_DIR}/yazi/yazi.zip" "${archive}"
    else
        install_apt_dependency curl || {
            rm -rf "${temp_dir}"
            return 1
        }
        curl -fLo "${archive}" \
            'https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip' || {
            rm -rf "${temp_dir}"
            return 1
        }
    fi

    if ! unzip -q "${archive}" -d "${temp_dir}/unpacked"; then
        rm -rf "${temp_dir}"
        return 1
    fi

    binary=$(find "${temp_dir}/unpacked" -type f -name yazi -print -quit)
    if [[ -z "${binary}" ]]; then
        warn 'Yazi 压缩包中未找到 yazi 可执行文件。'
        rm -rf "${temp_dir}"
        return 1
    fi

    chmod 0755 "${binary}"
    install_system_binary "${binary}" yazi
    local status=$?
    rm -rf "${temp_dir}"
    return "${status}"
}

install_yazi() {
    local existed=0
    local method

    if command_exists yazi; then
        existed=1
        if ! needs_github_update yazi yazi '--version' sxyazi/yazi; then
            add_result EXISTING_APPS 'yazi'
            return 0
        fi
    else
        if ! ask_yes_no 'yazi 是推荐应用，是否安装？' N; then
            add_result SKIPPED_APPS 'yazi'
            return 0
        fi
    fi

    method=$(ask_choice $'请选择 yazi 安装方式：\n  1. 使用 ~/term-config-files 中的版本\n  2. 下载并安装官方最新版' 1 2) || return 1

    if install_yazi_archive "${method}" && command_exists yazi; then
        if [[ ${existed} -eq 1 ]]; then
            add_result UPDATED_APPS 'yazi'
        else
            add_result INSTALLED_APPS 'yazi'
        fi
        return 0
    fi

    add_result FAILED_APPS 'yazi（安装失败）'
    return 1
}

install_superfile_source() {
    local method=$1

    if [[ "${method}" == '1' ]]; then
        ensure_term_config_files || return 1
        [[ -f "${TERM_CONFIG_FILES_DIR}/superfile/install.sh" ]] || {
            warn 'term-config-files/superfile/install.sh 不存在。'
            return 1
        }
        (cd "${TERM_CONFIG_FILES_DIR}/superfile" && bash ./install.sh)
    else
        install_apt_dependency curl || return 1
        bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
    fi
}

install_superfile() {
    local existed=0
    local method

    if command_exists spf; then
        existed=1
        if ! needs_github_update superfile spf '--version' yorukot/superfile; then
            add_result EXISTING_APPS 'superfile'
            return 0
        fi
    else
        if ! ask_yes_no 'superfile 是推荐应用，是否安装？' N; then
            add_result SKIPPED_APPS 'superfile'
            return 0
        fi
    fi

    method=$(ask_choice $'请选择 superfile 安装方式：\n  1. 使用 term-config-files 中的版本\n  2. 下载并安装官方最新版' 1 2) || return 1

    if install_superfile_source "${method}"; then
        export PATH="${LOCAL_BIN}:${PATH}"
        hash -r
        if command_exists spf; then
            if [[ ${existed} -eq 1 ]]; then
                add_result UPDATED_APPS 'superfile'
            else
                add_result INSTALLED_APPS 'superfile'
            fi
            return 0
        fi
    fi

    add_result FAILED_APPS 'superfile（安装失败）'
    return 1
}

install_getnf() {
    local existed=0
    local latest_tag

    if command_exists getnf; then
        existed=1
        if ! needs_github_update getnf getnf '-V' getnf/getnf; then
            add_result EXISTING_APPS 'getnf'
            return 0
        fi
    else
        if ! ask_yes_no 'getnf 是推荐应用，是否安装？' N; then
            add_result SKIPPED_APPS 'getnf'
            return 0
        fi
    fi

    install_apt_dependency curl || return 1
    install_apt_dependency zsh || return 1
    latest_tag=$(github_latest_tag getnf/getnf || true)
    if [[ -z "${latest_tag}" ]]; then
        warn '无法获取 getnf 最新标签，使用配置仓库原说明中的 v0.1.0。'
        latest_tag='v0.1.0'
    fi

    if curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh \
        | zsh -s -- "--tag=${latest_tag}"; then
        export PATH="${LOCAL_BIN}:${PATH}"
        hash -r
        if command_exists getnf; then
            if [[ ${existed} -eq 1 ]]; then
                add_result UPDATED_APPS 'getnf'
            else
                add_result INSTALLED_APPS 'getnf'
            fi
            return 0
        fi
    fi

    add_result FAILED_APPS 'getnf（安装失败）'
    return 1
}

setup_glow_repository() {
    local key_file
    local list_file
    local temp_key

    install_apt_dependency ca-certificates || return 1
    install_apt_dependency curl || return 1
    install_apt_dependency gnupg || return 1

    key_file='/etc/apt/keyrings/charm.gpg'
    list_file='/etc/apt/sources.list.d/charm.list'
    temp_key=$(mktemp) || return 1

    if ! curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor > "${temp_key}"; then
        rm -f "${temp_key}"
        return 1
    fi

    run_as_root mkdir -p /etc/apt/keyrings || {
        rm -f "${temp_key}"
        return 1
    }
    run_as_root install -m 0644 "${temp_key}" "${key_file}" || {
        rm -f "${temp_key}"
        return 1
    }
    rm -f "${temp_key}"

    printf 'deb [signed-by=%s] https://repo.charm.sh/apt/ * *\n' "${key_file}" \
        | run_as_root tee "${list_file}" >/dev/null || return 1

    run_as_root apt-get update || return 1
    APT_UPDATED=1
}

install_glow() {
    local installed_version

    installed_version=$(apt_installed_version glow)
    if [[ -z "${installed_version}" ]] \
        && ! ask_yes_no 'glow 是推荐应用，是否安装？' N; then
        add_result SKIPPED_APPS 'glow'
        return 0
    fi

    if ! setup_glow_repository; then
        add_result FAILED_APPS 'glow（软件源配置失败）'
        return 1
    fi

    install_apt_app glow glow required
}

local_gem_version() {
    gem list --local --exact "$1" 2>/dev/null \
        | sed -n "s/^$1 (\([^,)]*\).*/\1/p" \
        | head -n 1
}

remote_gem_version() {
    gem list --remote --exact "$1" 2>/dev/null \
        | sed -n "s/^$1 (\([^,)]*\).*/\1/p" \
        | head -n 1
}

ensure_ruby_for_lolcat() {
    if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then
        return 0
    fi

    if ! ask_yes_no 'lolcat 依赖 ruby，是否安装 ruby 并继续？' Y; then
        return 1
    fi

    remove_result SKIPPED_APPS 'ruby'
    install_apt_app ruby ruby required
}

install_lolcat() {
    local installed_version
    local latest_version

    if command -v gem >/dev/null 2>&1; then
        installed_version=$(local_gem_version lolcat)
    else
        installed_version=''
    fi

    if [[ -z "${installed_version}" ]] \
        && ! ask_yes_no 'lolcat 是推荐应用，是否安装？' N; then
        add_result SKIPPED_APPS 'lolcat'
        return 0
    fi

    if ! ensure_ruby_for_lolcat; then
        add_result SKIPPED_APPS 'lolcat'
        return 0
    fi

    installed_version=$(local_gem_version lolcat)
    if [[ -n "${installed_version}" ]]; then
        if [[ ${AUTO_YES} -eq 1 ]]; then
            log '-y 模式不更新已存在的 lolcat。'
            add_result EXISTING_APPS 'lolcat（未更新）'
            return 0
        fi

        latest_version=$(remote_gem_version lolcat)
        if [[ -n "${latest_version}" ]] \
            && dpkg --compare-versions "${installed_version}" ge "${latest_version}"; then
            log "lolcat 已是最新版本 (${installed_version})。"
            add_result EXISTING_APPS 'lolcat'
            return 0
        fi

        if [[ -n "${latest_version}" ]]; then
            printf 'lolcat 当前版本: %s，最新版本: %s。\n' \
                "${installed_version}" "${latest_version}"
        else
            warn '无法获取 lolcat 的 RubyGems 最新版本。'
        fi

        if ! ask_yes_no '是否更新 lolcat？' N; then
            add_result EXISTING_APPS 'lolcat（未更新）'
            return 0
        fi

        if run_as_root gem install lolcat --no-document; then
            add_result UPDATED_APPS 'lolcat'
            return 0
        fi

        add_result FAILED_APPS 'lolcat（更新失败）'
        return 1
    fi

    if run_as_root gem install lolcat --no-document; then
        add_result INSTALLED_APPS 'lolcat'
        return 0
    fi

    add_result FAILED_APPS 'lolcat（安装失败）'
    return 1
}

print_group() {
    local title=$1
    shift
    local -a values=("$@")
    local value

    printf '\n%s\n' "${title}"
    if [[ ${#values[@]} -eq 0 ]]; then
        printf '  无\n'
        return 0
    fi
    for value in "${values[@]}"; do
        printf '  - %s\n' "${value}"
    done
}

print_summary() {
    printf '\n========== 安装总结 ==========\n'
    print_group '新安装的应用：' "${INSTALLED_APPS[@]}"
    print_group '更新的应用：' "${UPDATED_APPS[@]}"
    print_group '已存在、未安装或未更新的应用：' "${EXISTING_APPS[@]}"
    print_group '用户跳过的可选安装项：' "${SKIPPED_APPS[@]}"
    print_group '安装失败的应用：' "${FAILED_APPS[@]}"
}

main() {
    parse_args "$@"
    check_ubuntu
    export PATH="${LOCAL_BIN}:${PATH}"

    printf '开始安装 term-config 所需应用。\n'
    if [[ ${AUTO_YES} -eq 1 ]]; then
        printf '%s\n' '-y 模式：安装所有未安装项，跳过所有现有应用的更新。'
    fi
    printf 'term-config-files 默认路径: %s\n' "${TERM_CONFIG_FILES_DIR}"

    install_tmux || true
    install_zsh || true
    install_vim || true
    install_git || true
    install_nodejs || true

    install_ruby || true
    install_img2chr || true
    install_wd || true
    install_yazi || true
    install_superfile || true
    install_getnf || true
    install_glow || true
    install_figlet || true
    install_lolcat || true
    install_sl || true
    install_cowsay || true

    print_summary
}

main "$@"
