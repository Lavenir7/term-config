#!/usr/bin/env bash

set -u

# 获取脚本所在目录，而不是使用当前工作目录。
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(dirname -- "$script_dir")"
conf_path="${project_root}/confFiles"

# 源文件，相对于 confFiles。
source_files=(
    "tmux/tmux.conf"
    "zsh/.zshrc"
    "vim/.vimrc"
    "vim/keys.vim"
    "vim/mini.vim"
    "vim/coc-settings.json"
    "superfile/config.toml"
    "superfile/hotkeys.toml"
    "pi/keybindings.json"
)

# 每个文件对应的完整目标路径。
destination_files=(
    "${HOME}/.conf/tmux/tmux.conf"
    "${HOME}/.zshrc"
    "${HOME}/.vimrc"
    "${HOME}/.conf/vim/keys.vim"
    "${HOME}/.conf/vim/mini.vim"
    "${HOME}/.vim/coc-settings.json"
    "${HOME}/.config/superfile/config.toml"
    "${HOME}/.config/superfile/hotkeys.toml"
    "${HOME}/.pi/agent/keybindings.json"
)

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

printf "=== Configuring Lavenir7's config files ===\n\n"

replace_all=false

for i in "${!source_files[@]}"; do
    source_path="${conf_path}/${source_files[$i]}"
    destination_path="${destination_files[$i]}"
    destination_dir="$(dirname -- "$destination_path")"

    printf 'Processing "%s"\n' "${source_files[$i]}"

    # 先检查源文件是否存在。
    if [[ ! -f "$source_path" ]]; then
        printf '%b❯❯❯ Source file not found: "%s"%b\n\n' \
            "$RED" "$source_path" "$NC"
        continue
    fi

    # 创建目标目录。
    if ! mkdir -p -- "$destination_dir"; then
        printf '%b❯❯❯ Failed to create directory: "%s"%b\n\n' \
            "$RED" "$destination_dir" "$NC"
        continue
    fi

    should_replace=false

    if [[ -e "$destination_path" ]]; then
        printf '%b"%s" already exists:%b\n' \
            "$YELLOW" "$destination_path" "$NC"

        if [[ "$replace_all" == true ]]; then
            should_replace=true
        else
            read -r -p "Replace and back it up? [y/a/N] " replace_input
            replace_input="${replace_input,,}"

            case "$replace_input" in
                y)
                    should_replace=true
                    ;;
                a)
                    should_replace=true
                    replace_all=true
                    ;;
                *)
                    printf '%b❯❯❯ Skipped "%s".%b\n\n' \
                        "$YELLOW" "$destination_path" "$NC"
                    continue
                    ;;
            esac
        fi

        if [[ "$should_replace" == true ]]; then
            if ! cp -- "$destination_path" "${destination_path}.bk"; then
                printf '%b❯❯❯ Failed to back up "%s".%b\n\n' \
                    "$RED" "$destination_path" "$NC"
                continue
            fi

            printf 'Backup created: "%s"\n' "${destination_path}.bk"
        fi
    fi

    # 只有 cp 真正成功时，才输出成功。
    if cp -- "$source_path" "$destination_path"; then
        printf '%b❯❯❯ "%s" placed successfully!%b\n\n' \
            "$GREEN" "$destination_path" "$NC"
    else
        printf '%b❯❯❯ Failed to place "%s".%b\n\n' \
            "$RED" "$destination_path" "$NC"
    fi
done
