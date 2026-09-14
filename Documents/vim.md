# vim

## 初始化 vim 配置

1. 将配置文件 `.vimrc` 放到用户主目录 `~`

2. 确认 nodejs 和 npm 已安装
```sh
node -v
npm -v
```
vim 插件：coc 需要

3. 打开 vim
```sh
vim
```

4. vim 会自动安装已配置的插件
你也可以手动安装 vim 插件：
```vim
:PlugInstall
```

5. 安装 Nerd Font（Source Code Pro）

- 详见：[Nerd-Font 安装](./Documents/nerdfont.md)

## vim 插件介绍

### [vim-ai](https://github.com/madox2/vim-ai)

| 命令       | 说明                           |
| :-:        | :-:                            |
| :AI        | 和AI对话                       |
| :AIE       | 和AI对话（会对光标处进行编辑） |
| :AIC       | 开窗口和AI对话                 |
| :AII       | AI生图                         |
| :AIS       | 中断AI说话                     |
| ...        | ...                            |
|            |                                |

1. 先配置 AI 的 BaseUrl 和 APIKey：
    - BaseUrl: .vimrc 中的 `s:vim_ai_endpoint_url` & `s:vim_ai_image_endpoint_url`;
    - APIKey: 存放在 token 文件(.vimrc 中的 `g:vim_ai_token_file_path`)中

2. vim-ai 关键配置：角色 [role]
    - 配置文件 roles.ini (.vimrc 中的 `g:vim_ai_roles_config_file`)
    - 可在 roles.ini 中单独对角色进行所有属性的配置

