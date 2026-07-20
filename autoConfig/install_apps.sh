#!/usr/bin/env bash

set -uo pipefail
IFS=$'\n\t'

readonly TERM_CONFIG_FILES_REPO="https://github.com/Lavenir7/term-config-files.git"
TERM_CONFIG_FILES_DIR="${TERM_CONFIG_FILES_DIR:-${HOME}/term-config-files}"
readonly LOCAL_BIN="${HOME}/.local/bin"

APT_UPDATED=0
AUTO_YES=0

readonly YELLOW=$'\033[0;33m'
readonly GREEN=$'\033[0;32m'
readonly RED=$'\033[0;31m'
readonly NORMAL=$'\033[0m'

declare -a INSTALLED_APPS=()
declare -a UPDATED_APPS=()
declare -a EXISTING_APPS=()
declare -a SKIPPED_APPS=()
declare -a FAILED_APPS=()

log() {
    printf '[term-config] %s\n' "$*"
}

warn() {
    printf '%s[term-config] WARNING: %s%s\n' "${YELLOW}" "$*" "${NORMAL}" >&2
}

error() {
    printf '%s[term-config] ERROR: %s%s\n' "${RED}" "$*" "${NORMAL}" >&2
}

success() {
    printf '%s[term-config] %s%s\n' "${GREEN}" "$*" "${NORMAL}"
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

    case "${array_name}" in
        INSTALLED_APPS) success "安装成功: ${value}" ;;
        UPDATED_APPS) success "更新成功: ${value}" ;;
        EXISTING_APPS) log "已存在或无需处理: ${value}" ;;
        SKIPPED_APPS)
            printf '%s[term-config] 已跳过: %s%s\n'                 "${YELLOW}" "${value}" "${NORMAL}"
            ;;
        FAILED_APPS) error "${value}" ;;
    esac
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
        read -r -p "${YELLOW}${prompt} ${hint}${NORMAL} " answer || return 1
        answer=${answer:-${default_answer}}
        case "${answer}" in
            y|Y|yes|YES|Yes) return 0 ;;
            n|N|no|NO|No) return 1 ;;
            *) printf '%s请输入 y 或 n。%s\n' "${YELLOW}" "${NORMAL}" ;;
        esac
    done
}

ask_choice() {
    local prompt=$1
    shift
    local choice
    local valid

    if [[ ${AUTO_YES} -eq 1 ]]; then
        printf '%s[term-config] %s 自动选择: %s%s\n' \
            "${YELLOW}" "${prompt%%$'\\n'*}" "$1" "${NORMAL}" >&2
        printf '%s\n' "$1"
        return 0
    fi

    while true; do
        printf '%s%s%s\n' "${YELLOW}" "${prompt}" "${NORMAL}" >&2
        read -r -p "${YELLOW}请输入选项编号: ${NORMAL}" choice || return 1
        for valid in "$@"; do
            if [[ "${choice}" == "${valid}" ]]; then
                printf '%s\n' "${choice}"
                return 0
            fi
        done
        printf '%s无效选项，请重新输入。%s\n' "${YELLOW}" "${NORMAL}" >&2
    done
}

ask_input_default() {
    local prompt=$1
    local default_value=$2
    local value

    if [[ ${AUTO_YES} -eq 1 ]]; then
        log "${prompt} 自动选择: ${default_value}"
        printf '%s\n' "${default_value}"
        return 0
    fi

    read -r -p "${YELLOW}${prompt} [${default_value}]: ${NORMAL}" value \
        || return 1
    printf '%s\n' "${value:-${default_value}}"
}

ask_install_failure_action() {
    local app_name=$1
    local answer

    while true; do
        printf '\n%s%s 安装失败。%s\n'             "${RED}" "${app_name}" "${NORMAL}" >&2
        printf '%s请选择：%s\n' "${YELLOW}" "${NORMAL}" >&2
        printf '%s  y. 重新尝试安装该应用%s\n' "${YELLOW}" "${NORMAL}" >&2
        printf '%s  n. 不安装该应用，继续安装其他应用%s\n' "${YELLOW}" "${NORMAL}" >&2
        printf '%s  q. 退出安装脚本%s\n' "${YELLOW}" "${NORMAL}" >&2
        read -r -p "${YELLOW}请输入 y、n 或 q: ${NORMAL}" answer || answer=n

        case "${answer}" in
            y|Y) printf 'retry\n'; return 0 ;;
            n|N) printf 'continue\n'; return 0 ;;
            q|Q) printf 'quit\n'; return 0 ;;
            *) printf '%s请输入 y、n 或 q。%s\n' "${YELLOW}" "${NORMAL}" >&2 ;;
        esac
    done
}

restore_failed_results() {
    local previous_count=$1
    FAILED_APPS=("${FAILED_APPS[@]:0:${previous_count}}")
}

install_with_retry() {
    local app_name=$1
    local install_function=$2
    shift 2

    local failed_count
    local action

    while true; do
        failed_count=${#FAILED_APPS[@]}

        if "${install_function}" "$@"; then
            return 0
        fi

        action=$(ask_install_failure_action "${app_name}")
        case "${action}" in
            retry)
                restore_failed_results "${failed_count}"
                ;;
            continue)
                return 1
                ;;
            quit)
                print_summary
                exit 1
                ;;
        esac
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
        error '无法识别操作系统；此脚本仅支持 Ubuntu。'
        exit 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != 'ubuntu' ]]; then
        error '当前系统不是 Ubuntu；此脚本仅支持 Ubuntu。'
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

        printf '%s%s 当前版本: %s，最新版本: %s。%s\n' \
            "${YELLOW}" "${app_name}" "${installed_version}"             "${candidate_version}" "${NORMAL}"
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
    local local_commit
    local remote_commit

    install_dir=$(oh_my_zsh_dir)
    if [[ ! -d "${install_dir}" ]]; then
        warn "${app_name} 需要先安装 Oh My Zsh。"
        add_result FAILED_APPS "${app_name}（需要 Oh My Zsh）"
        return 1
    fi

    if ! install_apt_dependency git; then
        add_result FAILED_APPS "${app_name}（git 安装失败）"
        return 1
    fi

    target_dir="$(zsh_custom_dir)/${relative_path}"
    if [[ -d "${target_dir}" ]]; then
        if [[ ! -d "${target_dir}/.git" ]]; then
            warn "${app_name} 已存在，但不是 Git 仓库，无法检查版本。"
            add_result FAILED_APPS "${app_name}（无法检查版本）"
            return 1
        fi

        local_commit=$(git -C "${target_dir}" rev-parse HEAD 2>/dev/null) || {
            add_result FAILED_APPS "${app_name}（无法读取本地版本）"
            return 1
        }
        remote_commit=$(git ls-remote "${repository}" HEAD 2>/dev/null | awk 'NR == 1 {print $1}') || true

        if [[ -z "${remote_commit}" ]]; then
            warn "无法获取 ${app_name} 的最新版本。"
            add_result FAILED_APPS "${app_name}（无法获取最新版本）"
            return 1
        fi

        if [[ "${local_commit}" == "${remote_commit}" ]]; then
            log "${app_name} 已是最新版本。"
            add_result EXISTING_APPS "${app_name}"
            return 0
        fi

        if [[ ${AUTO_YES} -eq 1 ]]; then
            log "-y 模式不更新已存在的 ${app_name}。"
            add_result EXISTING_APPS "${app_name}（未更新）"
            return 0
        fi

        if ! ask_yes_no "${app_name} 不是最新版本，是否更新？" N; then
            add_result EXISTING_APPS "${app_name}（未更新）"
            return 0
        fi

        if git -C "${target_dir}" pull --ff-only; then
            add_result UPDATED_APPS "${app_name}"
            return 0
        fi

        add_result FAILED_APPS "${app_name}（更新失败）"
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
        install_with_retry '设置 zsh 为默认 Shell' set_zsh_as_default_shell || true
    else
        add_result SKIPPED_APPS 'zsh（设置默认 Shell）'
    fi

    if ask_yes_no 'Oh My Zsh: Zsh 增强版，是否安装？' N; then
        install_with_retry 'Oh My Zsh' install_oh_my_zsh || true
    else
        add_result SKIPPED_APPS 'Oh My Zsh'
    fi

    if ask_yes_no 'Oh My Zsh 插件 zsh-autosuggestions: 命令行自动补全建议，是否安装？' N; then
        install_with_retry 'zsh-autosuggestions' install_zsh_autosuggestions || true
    else
        add_result SKIPPED_APPS 'zsh-autosuggestions'
    fi

    if ask_yes_no 'Oh My Zsh 插件 zsh-syntax-highlighting: 命令行语法高亮，是否安装？' N; then
        install_with_retry 'zsh-syntax-highlighting' install_zsh_syntax_highlighting || true
    else
        add_result SKIPPED_APPS 'zsh-syntax-highlighting'
    fi

    if ask_yes_no 'Oh My Zsh 主题 Powerlevel10k，是否安装？' N; then
        install_with_retry 'Powerlevel10k' install_powerlevel10k || true
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
load_nvm() {
    export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
    [[ -s "${NVM_DIR}/nvm.sh" ]] || return 1

    # shellcheck disable=SC1091
    . "${NVM_DIR}/nvm.sh"
}

install_nvm() {
    local latest_tag

    if load_nvm; then
        log "nvm 已存在于 ${NVM_DIR}。"
        return 0
    fi

    if ! install_apt_dependency curl; then
        add_result FAILED_APPS 'nvm（curl 安装失败）'
        return 1
    fi

    latest_tag=$(github_latest_tag nvm-sh/nvm || true)
    if [[ -z "${latest_tag}" ]]; then
        warn '无法获取 nvm 最新版本，使用 v0.40.4。'
        latest_tag='v0.40.4'
    fi

    log "安装 nvm ${latest_tag}..."
    if ! curl -fsSL \
        "https://raw.githubusercontent.com/nvm-sh/nvm/${latest_tag}/install.sh" \
        | bash; then
        add_result FAILED_APPS 'nvm（安装失败）'
        return 1
    fi

    if ! load_nvm; then
        add_result FAILED_APPS 'nvm（安装后无法加载）'
        return 1
    fi
}

install_nodejs_with_nvm() {
    local requested_version
    local current_version
    local remote_version
    local installed_version

    requested_version=$(ask_input_default \
        '请输入要通过 nvm 安装的 Node.js 版本，推荐 24；也可输入 22、lts/* 等' \
        24) || return 1

    install_nvm || return 1

    current_version=$(NVM_NO_COLORS=1 nvm version \
        "${requested_version}" 2>/dev/null || true)
    remote_version=$(NVM_NO_COLORS=1 nvm version-remote \
        "${requested_version}" 2>/dev/null || true)

    if [[ -z "${remote_version}" || "${remote_version}" == 'N/A' ]]; then
        add_result FAILED_APPS \
            "nodejs（找不到 nvm 版本 ${requested_version}）"
        return 1
    fi

    if [[ -n "${current_version}" && "${current_version}" != 'N/A' ]]; then
        if [[ "${current_version}" == "${remote_version}" ]]; then
            nvm alias default "${requested_version}" >/dev/null
            nvm use "${requested_version}" >/dev/null
            add_result EXISTING_APPS \
                "nodejs（nvm ${current_version}）"
            return 0
        fi

        printf '%snodejs 当前版本: %s，版本 %s 的最新版本: %s。%s\n' \
            "${YELLOW}" "${current_version}" "${requested_version}" \
            "${remote_version}" "${NORMAL}"

        if [[ ${AUTO_YES} -eq 1 ]]; then
            log '-y 模式不更新已存在的 nodejs。'
            add_result EXISTING_APPS \
                "nodejs（nvm ${current_version}，未更新）"
            return 0
        fi

        if ! ask_yes_no \
            "是否通过 nvm 更新 nodejs 到 ${remote_version}？" N; then
            add_result EXISTING_APPS \
                "nodejs（nvm ${current_version}，未更新）"
            return 0
        fi
    fi

    if ! nvm install "${requested_version}"; then
        add_result FAILED_APPS \
            "nodejs（nvm 安装版本 ${requested_version} 失败）"
        return 1
    fi

    if ! nvm alias default "${requested_version}" >/dev/null \
        || ! nvm use "${requested_version}" >/dev/null; then
        add_result FAILED_APPS 'nodejs（设置 nvm 默认版本失败）'
        return 1
    fi

    installed_version=$(node --version 2>/dev/null || true)
    if [[ -z "${installed_version}" ]] || ! command -v npm >/dev/null 2>&1; then
        add_result FAILED_APPS 'nodejs（安装后无法使用 node 或 npm）'
        return 1
    fi

    if [[ -n "${current_version}" && "${current_version}" != 'N/A' ]]; then
        add_result UPDATED_APPS "nodejs（nvm ${installed_version}）"
    else
        add_result INSTALLED_APPS "nodejs（nvm ${installed_version}）"
    fi
}

install_nodejs_direct() {
    local -a setup_command=(bash -)

    printf '%s将通过 NodeSource 直接安装 Node.js 24。%s\n' \
        "${YELLOW}" "${NORMAL}"

    if [[ ${AUTO_YES} -eq 1 ]] \
        && [[ -n "$(apt_installed_version nodejs)" ]]; then
        log '-y 模式不更新已存在的 nodejs。'
        add_result EXISTING_APPS 'nodejs（未更新）'
        return 0
    fi

    if ! install_apt_dependency curl; then
        add_result FAILED_APPS 'nodejs（curl 安装失败）'
        return 1
    fi

    if [[ ${EUID} -ne 0 ]]; then
        if ! command -v sudo >/dev/null 2>&1; then
            add_result FAILED_APPS 'nodejs（需要 sudo 权限）'
            return 1
        fi
        setup_command=(sudo -E bash -)
    fi

    log '配置 NodeSource Node.js 24.x 软件源...'
    if ! curl -fsSL https://deb.nodesource.com/setup_24.x \
        | "${setup_command[@]}"; then
        add_result FAILED_APPS 'nodejs（NodeSource 软件源配置失败）'
        return 1
    fi

    # NodeSource 脚本修改了软件源，需要重新读取 APT 索引。
    APT_UPDATED=0
    install_apt_app nodejs nodejs required
}

install_nodejs() {
    local method

    if [[ ${AUTO_YES} -eq 1 ]] && command -v node >/dev/null 2>&1; then
        log '-y 模式不更新已存在的 nodejs。'
        add_result EXISTING_APPS "nodejs（$(node --version 2>/dev/null)，未更新）"
        return 0
    fi

    method=$(ask_choice \
        $'请选择 nodejs 安装方式：\n  1. 使用 nvm 安装（推荐，可选择 Node.js 版本）\n  2. 使用 NodeSource 直接安装（默认 Node.js 24）' \
        1 2) || return 1

    case "${method}" in
        1) install_nodejs_with_nvm ;;
        2) install_nodejs_direct ;;
    esac
}
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

    if ! ask_yes_no 'img2chr: 图片转字符，是否安装？' N; then
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

    if ! ask_yes_no 'wd: youdao 查询单词，是否安装？' N; then
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
        if ! ask_yes_no 'yazi: 终端文件管理器，是否安装？' N; then
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

install_pi_ripgrep_dependency() {
    if ! ask_yes_no 'Pi 需要 ripgrep，是否安装 ripgrep？' Y; then
        add_result SKIPPED_APPS 'ripgrep（Pi 依赖）'
        return 0
    fi

    install_apt_app ripgrep ripgrep required
}

install_pi_fd_dependency() {
    local fdfind_path

    if ! ask_yes_no 'Pi 需要 fd，是否安装 fd？' Y; then
        add_result SKIPPED_APPS 'fd（Pi 依赖）'
        return 0
    fi

    if command_exists fd; then
        log 'fd 已存在。'
        add_result EXISTING_APPS 'fd'
        return 0
    fi

    install_apt_app fd fd-find required || return 1

    if command_exists fd; then
        return 0
    fi

    fdfind_path=$(command -v fdfind 2>/dev/null || true)
    if [[ -z "${fdfind_path}" ]]; then
        add_result FAILED_APPS 'fd（安装后找不到 fdfind）'
        return 1
    fi

    mkdir -p "${LOCAL_BIN}"
    if ! ln -sfn "${fdfind_path}" "${LOCAL_BIN}/fd"; then
        add_result FAILED_APPS 'fd（创建 fd 命令软链接失败）'
        return 1
    fi

    export PATH="${LOCAL_BIN}:${PATH}"
    hash -r

    if ! command_exists fd; then
        add_result FAILED_APPS 'fd（安装后无法执行）'
        return 1
    fi

    success "已创建 fd 命令软链接: ${LOCAL_BIN}/fd"
}

install_pi_dependencies() {
    install_pi_ripgrep_dependency || return 1
    install_pi_fd_dependency || return 1
}

pi_latest_version() {
    command -v npm >/dev/null 2>&1 || return 1
    npm view @earendil-works/pi-coding-agent version 2>/dev/null \
        | tail -n 1
}

install_pi_source() {
    local method=$1
    local install_script

    case "${method}" in
        1)
            ensure_term_config_files || return 1
            install_script="${TERM_CONFIG_FILES_DIR}/pi/install.sh"
            if [[ ! -f "${install_script}" ]]; then
                warn "找不到 ${install_script}。"
                return 1
            fi
            bash "${install_script}"
            ;;
        2)
            install_apt_dependency curl || return 1
            curl -fsSL https://pi.dev/install.sh | sh
            ;;
        3)
            if ! command -v npm >/dev/null 2>&1; then
                warn '使用 npm 安装 Pi 需要先安装 nodejs 和 npm。'
                return 1
            fi
            npm install -g --ignore-scripts \
                @earendil-works/pi-coding-agent
            ;;
    esac
}

install_pi() {
    local existed=0
    local method
    local current_version
    local latest_version

    if command_exists pi; then
        existed=1

        if [[ ${AUTO_YES} -eq 1 ]]; then
            log '-y 模式不更新已存在的 pi。'
            add_result EXISTING_APPS 'pi（未更新）'
            return 0
        fi

        current_version=$(pi --version 2>&1 | extract_version || true)
        latest_version=$(pi_latest_version || true)

        if [[ -n "${current_version}" && -n "${latest_version}" ]] \
            && dpkg --compare-versions \
                "${current_version}" ge "${latest_version}"; then
            log "pi 已是最新版本 (${current_version})。"
            add_result EXISTING_APPS 'pi'
            return 0
        fi

        if [[ -n "${current_version}" && -n "${latest_version}" ]]; then
            printf '%spi 当前版本: %s，最新版本: %s。%s\n' \
                "${YELLOW}" "${current_version}" \
                "${latest_version}" "${NORMAL}"
        else
            warn '无法可靠获取 pi 的当前版本或最新版本。'
        fi

        if ! ask_yes_no '是否更新 pi？' N; then
            add_result EXISTING_APPS 'pi（未更新）'
            return 0
        fi
    else
        if ! ask_yes_no 'pi: AI Agent，是否安装？' N; then
            add_result SKIPPED_APPS 'pi'
            return 0
        fi
    fi

    install_pi_dependencies || return 1

    method=$(ask_choice \
        $'请选择 pi 安装方式：\n  1. 使用 ~/term-config-files中的版本\n  2. 下载并安装官方最新版\n  3. 使用 npm 安装' 1 2 3) || return 1

    if install_pi_source "${method}"; then
        export PATH="${LOCAL_BIN}:${PATH}"
        hash -r

        if command_exists pi; then
            if [[ ${existed} -eq 1 ]]; then
                add_result UPDATED_APPS 'pi'
            else
                add_result INSTALLED_APPS 'pi'
            fi
            return 0
        fi
    fi

    add_result FAILED_APPS 'pi（安装失败）'
    return 1
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
        if ! ask_yes_no 'superfile: 终端文件管理器，是否安装？' N; then
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
        if ! ask_yes_no 'getnf: 用于安装 Nerd fonts（字体）的工具，是否安装？' N; then
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
        && ! ask_yes_no 'glow: Markdown 阅读器，是否安装？' N; then
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

    log 'lolcat 依赖 ruby，正在自动安装...'
    if ! install_apt_dependency ruby; then
        return 1
    fi

    command -v ruby >/dev/null 2>&1 \
        && command -v gem >/dev/null 2>&1
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
        && ! ask_yes_no 'lolcat: 彩色的输出，是否安装？' N; then
        add_result SKIPPED_APPS 'lolcat'
        return 0
    fi

    if ! ensure_ruby_for_lolcat; then
        add_result FAILED_APPS 'lolcat（ruby 依赖安装失败）'
        return 1
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
            printf '%slolcat 当前版本: %s，最新版本: %s。%s\n' \
                "${YELLOW}" "${installed_version}" "${latest_version}" "${NORMAL}"
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
    local color=$1
    local title=$2
    shift 2
    local -a values=("$@")
    local value

    printf '\n%s%s%s\n' "${color}" "${title}" "${NORMAL}"
    if [[ ${#values[@]} -eq 0 ]]; then
        printf '  无\n'
        return 0
    fi
    for value in "${values[@]}"; do
        printf '%s  - %s%s\n' "${color}" "${value}" "${NORMAL}"
    done
}

print_summary() {
    printf '\n========== 安装总结 ==========\n'
    print_group "${GREEN}" '新安装的应用：' "${INSTALLED_APPS[@]}"
    print_group "${GREEN}" '更新的应用：' "${UPDATED_APPS[@]}"
    print_group "${NORMAL}" '已存在、未安装或未更新的应用：' "${EXISTING_APPS[@]}"
    print_group "${YELLOW}" '用户跳过的可选安装项：' "${SKIPPED_APPS[@]}"
    print_group "${RED}" '安装失败的应用：' "${FAILED_APPS[@]}"
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

    install_with_retry tmux install_tmux || true
    install_with_retry zsh install_zsh || true
    install_with_retry vim install_vim || true
    install_with_retry git install_git || true
    install_with_retry nodejs install_nodejs || true

    install_with_retry pi install_pi || true
    install_with_retry img2chr install_img2chr || true
    install_with_retry wd install_wd || true
    install_with_retry yazi install_yazi || true
    install_with_retry superfile install_superfile || true
    install_with_retry glow install_glow || true
    install_with_retry figlet install_figlet || true
    install_with_retry lolcat install_lolcat || true
    install_with_retry cowsay install_cowsay || true
    install_with_retry sl install_sl || true
    install_with_retry getnf install_getnf || true

    print_summary
}

main "$@"
