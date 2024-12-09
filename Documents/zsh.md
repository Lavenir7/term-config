# zsh

## install
```sh
$ sudo apt-get install zsh
```

### set zsh to default
```sh
$ chsh -s $(which zsh) # -s : just for current user
```

### some plugins
#### install plugins
```sh
$ git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
$ git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
$ git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
```

### `ohmyzsh`
> learn from [novaspirit/pimpyourterm](https://github.com/novaspirit/pimpyourterm)

#### install `ohmyzsh`
```sh
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Theme `Powerlevel10k`
#### install Nerd Font (FiraMono)
- way 1: download the font-file manually
    - download the font-file on [github's page](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/FiraMono/Regular/FiraMonoNerdFont-Regular.otf)
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
fc-list | grep FiraMono
```

#### install Powerlevel10k
```sh
$ git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
```
then restart zsh, it well make you do some options to customize your zsh's looks

