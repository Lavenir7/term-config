
"  __  __        __     ___                                _       _ 
" |  \/  |_   _  \ \   / (_)_ __ ___  _ __ ___   _ __ ___ (_)_ __ (_)
" | |\/| | | | |  \ \ / /| | '_ ` _ \| '__/ __| | '_ ` _ \| | '_ \| |
" | |  | | |_| |   \ V / | | | | | | | | | (__  | | | | | | | | | | |
" |_|  |_|\__, |    \_/  |_|_| |_| |_|_|  \___| |_| |_| |_|_|_| |_|_|
"         |___/                                                      


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


" ================
" === file set ===
" ================
" 自动检测文件类型
filetype on
" 根据文件类型自动设置缩进规则
filetype indent on
" 根据文件类型自动加载插件
" filetype plugin on
" 同时开启以上三个功能
" filetype plugin indent on
" 设置编码
set encoding=utf-8
" 未保存的文件在更换文件时留存至缓冲区
" set hidden
" 取消备份
" set nobackup
" 禁止临时文件生成
" set noswapfile


" ===============
" === display ===
" ===============
" 主题配色方案
" colorscheme industry
" 语法高亮
syntax on
" 显示行数
set number
" 显示相对行数
set relativenumber
" 滚轮到边缘保留行数
set scrolloff=5
" 自动折行
set wrap
" 设置折行处与右边缘之间空出的字符数
" set wrapmargin=2
" 不在单词内部发生折行
" set linebreak
" 突出显示当前行
set cursorline
" 突出显示当前列
" set cursorcolumn
" 不显示特殊字符
set nolist
" 设置特殊字符显示（tab：TAB，space：空格，trail：痕迹/空格拖尾，eol：行尾）
set listchars=tab:▏\ ,space:∷,trail:༶,eol:\ 
" 设置特殊字符颜色
hi SpecialKey ctermfg=235 ctermbg=233
" 前置菜单配色
hi Pmenu ctermfg=None ctermbg=237
hi PmenuSel ctermfg=None ctermbg=233
" === 高亮光标所在行的tab、空格 ===
hi DisplayTabAndSpace ctermbg=243 ctermfg=235
" 颜色码为xterm-256color
autocmd InsertEnter,CursorMovedI * match DisplayTabAndSpace /\%.l\%#\@<!\s\+$/
autocmd InsertLeave * call clearmatches()
" === 高亮光标所在行的tab、空格 ===


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


" ==================
" === better tab ===
" ==================
" 换行时自动同步上一行的缩进
set ai
" 手动缩进（TAB）自动转换为空格
set expandtab
" 设置TAB宽度
set tabstop=4
" 设置一级缩进（>>）、取消一级缩进（<<）、自动缩进（==）时每一级的字符数
set shiftwidth=4
" 读取文件时TAB转换成空格的数量
set softtabstop=4
" === 自动补全功能 ===
function! CleverTab()
    if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
        return "\<Tab>"
    else
        return "\<C-N>"
    endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>

" 识别文件类型，自动选择omni补全（<C-x><C-o>）列表
if has("autocmd") && exists("+omnifunc")
    autocmd Filetype *
        \    if &omnifunc == "" |
        \        setlocal omnifunc=syntaxcomplete#Complete |
        \    endif
endif
" === 自动补全功能 ===


" ==============
" === search ===
" ==============
" 查找结果高亮显示
set hlsearch
" 搜索模式时，每输入一个字符就自动跳到第一个匹配结果
set incsearch
" 搜索时忽略大小写
set ignorecase
" 搜索仅全小写时忽略大小写（需要开启ignorecase）
set smartcase



" ==============
" === status ===
" ==============
" 状态栏显示（0不显示，1仅多窗口显示，2显示）
set laststatus=2 
" 状态栏显示当前光标位置信息
set ruler
" 状态栏显示指令
set showcmd
" 状态栏显示当前模式
set showmode
" 命令补全
set wildmenu
" 自定义状态栏*
" set statusline=%-08.8([revc]%)%-030.30(%F%m%)%-020.20([%l,%c]%)%p%%


" ===========
" === cmd ===
" ===========
" 设置vim命令行区域高度
" set cmdheight=2


"   ____  _                 
"  |  _ \| |_   _  __ _ ___ 
"  | |_) | | | | |/ _` / __|
"  |  __/| | |_| | (_| \__ \
"  |_|   |_|\__,_|\__, |___/
"                 |___/     

" =================
" === plug call ===
" =================
call plug#begin('~/.vim/plugged')

Plug 'gcmt/wildfire.vim' " 回车选中区域
Plug 'tpope/vim-surround' " 包裹词(in visual-mode press 'S' or in normal-mode press 'cs')
Plug 'RRethy/vim-illuminate' " 实时标注光标处词
Plug 'mg979/vim-visual-multi' " 多光标

call plug#end()

" ===================
" === plug config ===
" ===================

" ===
" === vim-illuminate
" ===
let g:Illuminate_delay = 750
hi illuminatedWord cterm=underline gui=underline

" ===
" === vim-visual-multi
" ===
let g:VM_theme = 'iceblue'
" let g:VM_default_mappings = 0
" let g:VM_leader = {'default':',', 'visual': ',', 'buffer':','}
" let g:VM_maps = 0
" let g:VM_custom_motions = {'n': 'h', 'i': 'l', 'u': 'k', 'e': 'j', 'N': '0', 'I': '$', 'h': 'e'}
" let g:VM_maps['i'] ='i'
" let g:VM_maps['I'] ='I'
" let g:VM_maps['Find Under'] = '<C-n>'
" let g:VM_maps['Find Subword Under'] ='<C-N>'
" let g:VM_maps['Find Next'] = 'n'
" let g:VM_maps['Find Prev'] = 'N'
" let g:VM_maps['Remove Region'] = 'Q'
" let g:VM_maps['Skip Region'] = 'q'
" let g:VM_maps["Undo"] = ''
" let g:VM_maps["Redo"] = ''

