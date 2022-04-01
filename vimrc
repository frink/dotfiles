set encoding=utf8 ffs=unix,dos,mac
set number nowrap foldmethod=indent
set list lcs=tab:•·,space:•,trail:·,nbsp:•,precedes:◀,extends:▶
set sidescroll=1 scrolloff=3
set hlsearch incsearch magic
set cursorline
set lazyredraw 
set showmatch mat=2
set noerrorbells novisualbell t_vb= tm=500
set foldcolumn=1
set autoindent
set smartindent
set cindent
set mouse=a

syntax enable
colorscheme ron 

set hid
set ruler
set history=500
set wildmenu
set autoread

set backspace=eol,start,indent
set whichwrap+=<,>,h,l

highlight Cursor cterm=NONE ctermbg=11 ctermfg=0
highlight LineNR ctermfg=23
highlight Search ctermbg=23
highlight SpecialKey ctermfg=23
highlight EndOfBuffer ctermfg=23

highlight CursorLine cterm=NONE ctermbg=17 ctermfg=NONE
highlight CursorLineNR cterm=NONE ctermbg=17 ctermfg=26
highlight Folded ctermbg=17 ctermfg=NONE

let g:user_emmet_leader_key='<C-m>'

autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType vue setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType css setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType svg setlocal shiftwidth=2 tabstop=2 expandtab

