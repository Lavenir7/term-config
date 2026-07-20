# autoConfig

> [!NOTE]
> 
> 自动安装应用及配置

|script|description|
|:-:|:-:|
|install_apps.sh|安装应用|
|placeConfigFiles.sh|安放应用配置文件|

## 配置步骤

1. 首先安装应用 (`./install_apps.sh`)

    - 必备应用：
        - tmux
        - zsh
        - vim
        - git
        - nodejs

    - 可选应用：
        - pi
        - img2chr
        - wd
        - yazi
        - superfile
        - glow
        - figlet
        - lolcat
        - cowsay
        - sl
        - getnf

2. 然后安放配置文件 (`./placeConfigFiles.sh`)
   
    - 其中 .zshrc 需要输入 `y` 同意覆盖原配置；

3. 手动操作：

    - 重启终端；

    - 按照提示配置 zsh 主题；

        - 个人 zsh 主题：

            ![zsh_theme](../imgs/zsh_theme.png)
    
            选项：看图作答 - [Prompt Style 开始 `3-1-2-3-2-2-2-3-3-3-2-2-1-y-1-y` ]
    
        - 个人 zsh 主题配置：

            ![zsh_theme_config](../imgs/zsh_theme_config.png)

    - 【可选】使用 `getnf` 安装字体 (0xProto, FiraMono, SourceCodePro)
    
    - 打开 `vim`，自动安装 vim 插件

        - 若安装超时，则重新打开 vim，输入 `:PlugInstall` 重新安装 vim 插件；

        - 若存在其他安装错误，请检查 ~/.vimrc 配置文件，删除存在错误的插件或自行解决；
    
    - 在安装完 coc.nvim 插件后，打开 `vim`，自动安装 coc.nvim 插件；

    - 打开 `pi`, 输入 `/login` 配置服务商和 api key

        - 【可选】配置完成后，输入 `/model` 设置模型
        
        - 【可选】输入 `/settings` - `Thinking level` 修改思考深度