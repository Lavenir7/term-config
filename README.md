# term-config

> All my terminal programs are using **Vim-style** as much as possible.

## Config Files

| name                            | config file                                               | path to storage             |
| :-:                             | :-:                                                       | :-:                         |
| [tmux](./Documents/tmux.md)     | [tmux.conf](./confFiles/tmux/tmux.conf)                   | ~/.conf/tmux/tmux.conf      |
| [zsh](./Documents/zsh.md)       | [.zshrc](./confFiles/zsh/.zshrc)                          | ~/.zshrc                    |
| [vim](./Documents/vim.md)       | [.vimrc](./confFiles/vim/.vimrc)                          | ~/.vimrc                    |
| [vimk](./Documents/vim.md)      | [keys.vim](./confFiles/vim/keys.vim)                      | ~/.conf/vim/keys.vim        |
| [vimm](./Documents/vim.md)      | [mini.vim](./confFiles/vim/mini.vim)                      | ~/.conf/vim/mini.vim        |
| [coc](./Documents/coc.md)       | [coc-settings.json](./confFiles/vim/coc-settings.json)    | ~/.vim/coc-settings.json    |
| [termux](./Documents/termux.md) | [termux.properties](./confFiles/termux/termux.properties) | ~/.termux/termux.properties |
|                                 |                                                           |                             |

> You can run [this shell script](./autoConfig/placeConfigFiles.sh) to automatically place the config files.


## Software
### Required
| name              | description                          |
| :-:               | :-:                                  |
| [tmux](#tmux)     | terminal multiplexer                 |
| [zsh](#zsh)       | a shell                              |
| [vim](#vim)       | a editor                             |
| [git](#git)       | a version control tool               |
| [nodejs](#nodejs) | vim plugin -- coc needed             |
|                   |                                      |

### Optional
| name              | description                |
| :-:               | :-:                        |
| [yazi](#yazi)     | a console file manager     |
| [getnf](#getnf)   | easy to install Nerd Fonts |
| [glow](#glow)     | a markdown reader          |
| [ruby](#ruby)     | install lolcat needed                |
|                   |                            |

### Funny
| name              | description                  |
| :-:               | :-:                          |
| [figlet](#figlet) | a ASCII art                  |
| [lolcat](#lolcat) | a colorful printer           |
| [sl](#sl)         | a train is running           |
| [cowsay](#cowsay) | a cow is saying something... |
|                   |                              |

## Install (Ubuntu24.04 available)

### tmux
```sh
$ sudo apt-get install tmux
```

### zsh
```sh
$ sudo apt-get install zsh
```

### vim
```sh
$ sudo apt-get install vim
```

### git
```sh
$ sudo apt-get install git
```

### ruby
```sh
$ sudo apt-get install ruby
```

### nodejs
```sh
$ sudo apt-get install nodejs
```

### getnf
```sh
$ curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | zsh -s -- --tag=v0.1.0
```

### glow
```sh
$ sudo mkdir -p /etc/apt/keyrings
$ curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
$ echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
$ sudo apt update && sudo apt install glow
```
More install way see here: [charmbracelet/glow](https://github.com/charmbracelet/glow)

### figlet
```sh
$ sudo apt-get install figlet
```

### lolcat
- checkout `ruby`
```sh
$ ruby -v
```

- install ruby if not have ruby
```sh
$ sudo apt-get install ruby
```

- download lolcat
```sh
$ curl -fLo ~/lolcat.zip https://github.com/busyloop/lolcat/archive/master.zip
$ unzip ~/lolcat.zip
```

- install lolcat
```sh
$ cd ~/lolcat-master/bin
$ gem install lolcat
```

### sl
```sh
$ sudo apt-get install sl
```

### cowsay
```sh
$ sudo apt-get install cowsay
```


