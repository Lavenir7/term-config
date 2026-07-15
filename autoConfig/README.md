# autoConfig

> [!NOTE]
> 
> 自动安装应用及配置

|script|description|
|:-:|:-:|
|install.sh|安装应用及配置|
|install_apps.sh|安装应用|
|install_shell.sh|安装shell小工具|
|placeConfigFiles.sh|安放配置文件|

## 配置步骤

1. 首先安装应用 (`install_apps.sh`)
    - 必备应用：
        - tmux
        - zsh
        - vim
        - git
        - nodejs
    - 可选应用：
        - yazi
        - superfile
        - getnf
        - glow
        - ruby
        - figlet
        - lolcat
        - sl
        - cowsay

2. 然后安放配置文件 (`placeConfigFiles.sh`)

3. 手动操作：
    - 重启终端，配置 zsh 主题；
    - 打开 vim，自动安装 vim 插件；
    - 打开 vim，输入 `:PlugInstall` 安装 vim-coc 插件；