# coc

## install the nodejs and npm
- confirm
```sh
node -v
npm -v
```

- install
```sh
sudo apt-get install nodejs # nodejs has npm, so just install nodejs is enough
```

## view the coc-plugins
run this in vim
```vim
:CocList extensions
```
start with `*` meaning `is runing`
start with `+` meaning `has installed`

## edit the coc config
- open the config file
```sh
vim ~/.vim/coc-settings.json
```

- use vim cmd
```vim
:CocConfig
```

