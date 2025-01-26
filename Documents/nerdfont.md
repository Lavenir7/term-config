# Nerd Font Install

## install Nerd Font

- way 1: download the font-file manually
    - download the font-file on [NerdFonts Page](https://www.nerdfonts.com/font-downloads)
        - some of nerd-font files already in `https://github.com/Lavenir7/term-config-files/NerdFonts/`
    - move the font-file to `/usr/share/fonts/opentype/` (.otf file) or `/usr/share/fonts/truetype/` (.ttf file)
    - refresh
    ```sh
    fc-cache -v
    ```

- way 2: install by `getnf`
    - install `getnf`
    ```sh
    curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | zsh -s -- --tag=v0.1.0
    ```
    - install Nerd Font
    ```sh
    getnf
    # then chose the corresponding number
    ```

## checkout
```sh
fc-list | grep <NerdFont-name>
```
