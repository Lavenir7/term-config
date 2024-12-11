# vim

1. push the config file `.vimrc` to the path

2. confirm the nodejs and npm
```sh
$ node -v
$ npm -v
```
the vim plug: coc need these

3. then open the vim
```sh
$ vim
```

4. it will install the needed plug automatically
You can install vim plugins manually:
```vim
:PlugInstall
```

5. install Nerd Font (Source Code Pro)

- way 1: download the font-file manually
    - download the font-file on [NerdFonts Page](https://www.nerdfonts.com/font-downloads)
    - move the font-file to `/usr/share/fonts/OTF/`
    - refresh
    ```sh
    fc-cache -v
    ```

- way 2: install by `getnf`
    - install `getnf`
    ```sh
    $ curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | zsh -s -- --tag=v0.1.0
    ```
    - install Nerd Font
    ```sh
    $ getnf # then chose the corresponding number
    ```

- checkout
```sh
fc-list | grep "Source Code Pro"
```

