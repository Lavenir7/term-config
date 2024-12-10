#!/bin/bash

# config files
rcfile=("tmux.conf"
".zshrc"
".vimrc"
"ranger.conf"
"coc-settings.json")

# path to store config files
path_to_store=("${HOME}/.conf/tmux"
"${HOME}"
"${HOME}"
"${HOME}/.conf/ranger
"${HOME}/.vim")

# colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m"

confPath="./confFiles"

printf "=== Configuring Lavenir7's config files ===\n\n"
replace_all=""
placed=""
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
            placed="true"
        elif [ "${replace}" == "a" ]; then
            cp "${rcfpath2store}" "${rcfpath2store}.bk"
            cp "${rcfpath}" "${rcfpath2store}"
            printf "${rcfile[$i]}.bk has been created.\n"
            replace_all="true"
            placed="true"
        else
            placed=""
        fi
    else
        cp "${rcfpath}" "${rcfpath2store}"
        placed="true"
    fi
    if [ -n "${placed}" ]; then
        printf "${GREEN}❯❯❯ \"${rcfile[$i]}\" placed successfully!\n${NC}"
    else
        printf "${RED}❯❯❯ \"${rcfile[$i]}\" placement failed.\n${NC}"
    fi
done
