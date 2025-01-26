
"  __  __        __     ___                      _                  
" |  \/  |_   _  \ \   / (_)_ __ ___  _ __ ___  | | _____ _   _ ___ 
" | |\/| | | | |  \ \ / /| | '_ ` _ \| '__/ __| | |/ / _ \ | | / __|
" | |  | | |_| |   \ V / | | | | | | | | | (__  |   <  __/ |_| \__ \
" |_|  |_|\__, |    \_/  |_|_| |_| |_|_|  \___| |_|\_\___|\__, |___/
"         |___/                                           |___/     

"   ____       _   _   _                 
"  / ___|  ___| |_| |_(_)_ __   __ _ ___ 
"  \___ \ / _ \ __| __| | '_ \ / _` / __|
"   ___) |  __/ |_| |_| | | | | (_| \__ \
"  |____/ \___|\__|\__|_|_| |_|\__, |___/
"                              |___/     

" =======================
" === map/noremap key ===
" =======================
" map : 键位映射
" noremap : 非递归映射
" 更多map使用请查看官方帮助文档 :tab h map

" 设置<LEADER>为空格Space
let mapleader=" "

" 取消一些键
noremap K <nop>
noremap J <nop>
" s - split
noremap s <nop>
" t - terminal
noremap t <nop>
" noremap <Left> <nop>
" noremap <Right> <nop>
" noremap <Up> <nop>
" noremap <Down> <nop>

" 更远的上下移动
noremap J 5j
noremap K 5k
noremap L $
noremap H 0
" <Ctrl>+l : 开关空白字符显示
noremap <C-l> :set list!<CR>
" tx : 艺术字生成
noremap tx :r !figlet 
" <Space>rc : 跳转到vim配置文件
noremap <LEADER>rc :e ~/.vimrc<CR>
" <Space>R : 加载vim配置
noremap <LEADER>rr :source $MYVIMRC<CR>
" <Ctrl>+h : 开关搜索结果高亮
noremap <C-h> :set nohls!<CR>
" <Space><Space> : placeholder edit
noremap <LEADER><LEADER> <Esc>/<++><CR>:nohls<CR>c4l
" ts : tab to space
noremap ts :%s/\t/    /gc<CR>
" <Space>rn : rename
nnoremap <LEADER>rn :%s/<C-R><C-W>/<C-R><C-W>/gc<Left><Left><Left>

" 文件多开
" 标签页
noremap te :tabe<CR>
noremap tn :tabn<CR>
noremap tp :tabp<CR>
noremap tc :tabc<CR>
" sk/sj/sh/sl : 上下左右分屏
noremap sk :set nosplitbelow<CR>:split<CR>
noremap sj :set splitbelow<CR>:split<CR>
noremap sh :set nosplitright<CR>:vsplit<CR>
noremap sl :set splitright<CR>:vsplit<CR>
" <Space>k/j/h/l : 上下左右分屏之间移动
noremap <LEADER>k <C-w>k
noremap <LEADER>j <C-w>j
noremap <LEADER>h <C-w>h
noremap <LEADER>l <C-w>l
" 更改分屏方向（ss切换成左右分屏，sv切换成上下分屏）
noremap ss <C-w>t<C-w>H
noremap sv <C-w>t<C-w>K
" <Ctrl-s>k/j/h/l : 调整分屏大小
noremap <C-s>k :res +5<CR>
noremap <C-s>j :res -5<CR>
noremap <C-s>h :vertical resize-5<CR>
noremap <C-s>l :vertical resize+5<CR>

" 插入模式快捷键
" 保存
inoremap <C-s> <C-o>:w<CR>
" 撤销
inoremap <C-z> <C-o>u
" 恢复
inoremap <C-r> <C-o><C-r>
" 粘贴
inoremap <C-v> <C-o>p
" 复制粘贴当前行
inoremap <C-c> <C-o>yy<C-o>p



" ==============
" === system ===
" ==============
" 取消vim剪切寄存器独立于系统剪切板
" set clipboard+=unnamedplus
" set clipboard=unnamed
" 查看vim-clipboard命令：vim --version | grep clipboard

" 不兼容vi模式
set nocompatible
" 扩展退格键使用（backspace）
" set backspace=indent,eol,start

" ==============
" === cursor ===
" ==============
" === 光标形状 ===
" Insert模式 6 : solid vertical bar
let &t_SI = "\<Esc>[6 q"
" Replace模式3 : blinking underscore
let &t_SR = "\<Esc>[3 q"
" Normal模式2 : solid block
let &t_EI = "\<Esc>[2 q"
" === 光标形状 ===
" 打开文件时光标自动位于上次退出的位置
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

