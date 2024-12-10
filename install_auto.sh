#!/bin/bash

# config files
rcfile=("tmux.conf"
".zshrc"
".vimrc"
"coc-settings.json")

# path to store config files
path_to_store=("${HOME}/.conf/tmux"
"${HOME}"
"${HOME}"
"${HOME}/.vim")

# colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m"

confPath="./confFiles"

printf "=== Installing Lavenir7's config files ===\n\n"
replace_all=""
installed=""
for i in "${!rcfile[@]}"; 
do 
    rcfpath="${confPath}/${rcfile[$i]}"
    rcfpath2store="${path_to_store[$i]}/${rcfile[$i]}"
    # checkout path
    printf "checkout the path\n"
    if [ ! -d "${path_to_store[$i]}" ]; then
        mkdir -p "${path_to_store[$i]}"
        printf "create directory: \"${path_to_store[$i]}\"\n"
    else
        true
    fi
    # cp rcfile to the path
    if [ -e ${rcfpath2store} ]; then
        # rcfile already exist
        printf "${YELLOW}\"${rcfile[$i]}\" already exist:\n${NC}"
        printf "\t(${rcfpath2store})\n"
        if [ -n "${replace_all}" ]; then
            # argee to replace all rcfile
            replace="y"
        else
            # ask user whether replace
            printf "Replace and backup it? (enter y/a to confirm it/all) "
            read replace_input
            replace=$(echo "${replace_input}" | tr '[:upper:]' '[:lower:]')
        fi
        if [ "${replace}" == "y" ]; then
            cp "${rcfpath2store}" "${rcfpath2store}.bk"
            cp "${rcfpath}" "${rcfpath2store}"
            printf "${rcfile[$i]}.bk has been created.\n"
            installed="true"
        elif [ "${replace}" == "a" ]; then
            cp "${rcfpath2store}" "${rcfpath2store}.bk"
            cp "${rcfpath}" "${rcfpath2store}"
            printf "${rcfile[$i]}.bk has been created.\n"
            replace_all="true"
            installed="true"
        else
            installed=""
        fi
    else
        cp "${rcfpath}" "${rcfpath2store}"
        installed="true"
    fi
    if [ -n "${installed}" ]; then
        printf "${GREEN}❯❯❯ \"${rcfile[$i]}\" install succeeded!\n${NC}"
    else
        printf "${RED}❯❯❯ \"${rcfile[$i]}\" install failed.\n${NC}"
    fi
done
