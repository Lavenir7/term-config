
"   __  __        __     ___                    
"  |  \/  |_   _  \ \   / (_)_ __ ___  _ __ ___ 
"  | |\/| | | | |  \ \ / /| | '_ ` _ \| '__/ __|
"  | |  | | |_| |   \ V / | | | | | | | | | (__ 
"  |_|  |_|\__, |    \_/  |_|_| |_| |_|_|  \___|
"          |___/                                



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
filetype plugin on
" 同时开启以上三个功能
filetype plugin indent on
" 设置编码
set encoding=utf-8
" 未保存的文件在更换文件时留存至缓冲区
set hidden
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
set list
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


" ============
" === code ===
" ============
" 代码折叠
set foldmethod=indent
set foldlevel=99


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
" bash中执行下面命令，下载vim插件工具
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" 用vim-plug安装插件还需要git
" sudo apt install git
" vim中执行以下命令安装插件
" :PlugInstall
" 自动检测vim-plug安装
if empty(glob('~/.vim/autoload/plug.vim')) " neovim path : ~/.config/nvim/autoload/plug.vim
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Plug 'vim-airline/vim-airline' " 状态栏样式
Plug 'connorholyday/vim-snazzy' " snazzy主题
Plug 'junegunn/goyo.vim', {'on': 'Goyo'} " 打字模式
Plug 'scrooloose/nerdtree', {'on': 'NERDTreeToggle'} " 文件树
Plug 'mbbill/undotree', {'on': 'UndotreeToggle'} " 显示树状文件历史
" Plug 'w0rp/ale' " 显示warning/error
Plug 'gcmt/wildfire.vim' " 回车选中区域
Plug 'tpope/vim-surround' " 包裹词(in visual-mode press 'S' or in normal-mode press 'cs')
Plug 'RRethy/vim-illuminate' " 实时标注光标处词
Plug 'mg979/vim-visual-multi' " 多光标
Plug 'voldikss/vim-translator' " 翻译
Plug 'neoclide/coc.nvim', {'branch': 'release'} " coc [ not only for complete ]
" Git
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/gv.vim'
" Plug 'tpope/vim-fugitive'
" Markdown
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install_sync() }, 'for' :['markdown', 'vim-plug'] }
Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeToggle' }
Plug 'vimwiki/vimwiki'

call plug#end()

" ===================
" === plug config ===
" ===================

" ===
" === snazzy
" ===
colorscheme snazzy
" let g:SnazzyTransparent=1 " 背景透明
" 搜索内容配色
hi Search ctermbg=178 ctermfg=52 guibg=#cfa60f guifg=#491f07
hi IncSearch ctermbg=228 ctermfg=52 guibg=#f3f99d guifg=#592f0c
" 设置特殊字符颜色
hi SpecialKey ctermfg=235 ctermbg=233
" coc菜单配色
hi CocMenu ctermfg=None ctermbg=234
hi CocMenuSel ctermfg=None ctermbg=233
" === 高亮光标所在行的tab、空格 ===
hi DisplayTabAndSpace ctermbg=243 ctermfg=235
" 颜色码为xterm-256color
autocmd InsertEnter,CursorMovedI * match DisplayTabAndSpace /\%.l\%#\@<!\s\+$/
autocmd InsertLeave * call clearmatches()
" === 高亮光标所在行的tab、空格 ===

" ===
" === MarkdownPreview
" ===
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 1
let g:mkdp_refresh_slow = 0
let g:mkdp_command_for_global = 0
let g:mkdp_open_to_the_world = 0
let g:mkdp_open_ip = ''
let g:mkdp_browser = 'msedge' " 
let g:mkdp_echo_preview_url = 0
let g:mkdp_browserfunc = ''
let g:mkdp_preview_options = {
    \ 'mkit': {},
    \ 'katex': {},
    \ 'uml': {},
    \ 'maid': {},
    \ 'disable_sync_scroll': 0,
    \ 'sync_scroll_type': 'middle',
    \ 'hide_yaml_meta': 1
    \ }
let g:mkdp_markdown_css = ''
let g:mkdp_highlight_css = ''
let g:mkdp_port = ''
let g:mkdp_page_title = '「${name}」'

" ===
" === vim-gitgutter
" ===
" let g:gitgutter_map_keys = 0 " disable all gitgutter-key mappings
noremap gt :GitGutter
set signcolumn=yes " keep gitgutter sign column on
" " --- Sign
" " signs (<= 2)
let g:gitgutter_sign_added = ''
let g:gitgutter_sign_modified = '▒'
let g:gitgutter_sign_removed = '﹏'
let g:gitgutter_sign_removed_first_line = '▔'
let g:gitgutter_sign_removed_above_and_below = '┆'
let g:gitgutter_sign_modified_removed = '░'
" " colors
" highlight GitGutterAdd guifg=#009900 ctermfg=2
" highlight GitGutterChange guifg=#bbbb00 ctermfg=3
" highlight GitGutterDelete guifg=#ff2222 ctermfg=1
" " --- Line
" highlight link GitGutterAddLine DiffAdd
" highlight link GitGutterChangeLine DiffChange
" highlight link GitGutterDeleteLine DiffDelete
" highlight link GitGutterChangeDeleteLine DiffChange
" " --- view diff
" GitGutterAddIntraLine gui=reverse cterm=reverse
" GitGutterDeleteIntraLine gui=reverse cterm=reverse
" " set diff relative
" let g:gitgutter_diff_relative_to = 'working_tree'
" " set diff base
" let g:gitgutter_diff_base = '<commit SHA>'

" ===
" === vim-table-mode
" ===
noremap <LEADER>tm :TableModeToggle<CR>

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


" ===
" === vim-translator
" ===
nnoremap <silent> <LEADER>tt :TranslateW --engines=bing<CR>
vnoremap <silent> <LEADER>tt :TranslateW --engines=bing<CR>

" ===
" === NERDTree
" ===
" r : 刷新文件树
" tt : 打开/关闭文件树
noremap tt :NERDTreeToggle<CR>
" let NERDTreeMapOpenExpl = ""
" let NERDTreeMapUpdir = ""
" l : 返回上一级目录
let NERDTreeMapUpdirKeepOpen = "l"
" let NERDTreeMapOpenSplit = ""
" let NERDTreeOpenVSplit = ""
" i : 展开/收起选中目录
let NERDTreeMapActivateNode = "i"
" o : 打开选中文件
let NERDTreeMapOpenInTab = "o"
" let NERDTreeMapPreview = ""
" n : 收起父级目录
let NERDTreeMapCloseDir = "n"
" y : 更改根目录为选中目录
let NERDTreeMapChangeRoot = "y"

" " ==
" " == NERDTree-git
" " ==
" 文件树中增加一些文件状态标记
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }

" " ===
" " === ale
" " ===
" 安装以下python库
" pip install pylint autopep8 yapf
let b:ale_linters = ['pylint']
let b:ale_fixers = ['autopep8', 'yapf']

" " ===
" " === Goyo
" " ===
" <Space>+gy : 开启Goyo打字模式
noremap <LEADER>gy :Goyo<CR>

" " ===
" " === Undotree
" " ===
let g:undotree_DiffAutoOpen = 0
" U : 查看当前文件的历史版本树
noremap U :UndotreeToggle<CR>

" ===
" === coc
" ===
" coc插件
" pip install jedi (for python)
nnoremap coc :CocCommand<CR> " 开启coc命令行
let g:coc_global_extensions = [
    \ 'coc-json', 
    \ 'coc-vimlsp',
    \ 'coc-python',
    \ 'coc-jedi',
    \ 'coc-css',
    \ 'coc-gitignore',
    \ 'coc-marketplace'
    \ ]
" 左侧行号与标记共用
" set signcolumn=number
set updatetime=100 " 补全信息反应更快
set shortmess+=c " 补全信息，更少的信息
" tab补全
inoremap <silent><expr> <TAB>
    \ pumvisible() ? "\<C-n>" :
    \ strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$' ? "\<TAB>" :
    \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
" 查看所有可补全的内容
inoremap <silent><expr> <C-t> coc#refresh()
" 回车选中补全内容不换行
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
    \ : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" 查看函数调用
nnoremap <silent> gd <Plug>(coc-definition)
nnoremap <silent> gy <Plug>(coc-type-definition)
nnoremap <silent> gi <Plug>(coc-implementation)
nnoremap <silent> gr <Plug>(coc-references)
" 查看vim帮助文档
nnoremap <silent> <LEADER>H :call <SID>show_documentation()<CR>

function! s:show_documentation()
    if (index(['vim', 'help'], &filetype) >= 0)
        execute 'tab h '.expand('<cword>')
    else
        call CocAction('doHover')
    endif
endfunction
" 重命名变量
nnoremap <LEADER>rn <Plug>(coc-rename)

