# zsh

## install
```sh
sudo apt-get install zsh
```

### set zsh to default
```sh
chsh -s $(which zsh) # -s : just for current user
```

### `ohmyzsh`
> learn from [novaspirit/pimpyourterm](https://github.com/novaspirit/pimpyourterm)

#### install `ohmyzsh`
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
Then restart your terminal

### some plugins
#### install plugins
```sh
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```

### Theme `Powerlevel10k`
#### install Nerd Font (FiraMono)

see this: [Nerd-Font install](./Documents/nerdfont.md)

#### install Powerlevel10k
```sh
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
```
then restart zsh, it well make you do some options to customize your zsh's looks

