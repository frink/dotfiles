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

function! FIXretab()
    if &expandtab
        retab
    else
        retab!
    endif
endfunction

autocmd InsertLeave * call FIXretab()

function! YankToClipboard()
    call system('copy', getreg('"'))
endfunction

function! YankToFile()
    call writefile([getreg('"')], expand('~/.vimyank'))
endfunction

function! YankToCopyAndFile()
    call system('echo ' . shellescape(getreg('"')) . ' | tee ~/.vimyank | copy')
endfunction

augroup YankProcess
    autocmd!
    autocmd TextYankPost * silent! call YankToCopyAndFile()
augroup END

augroup caddyfile_syntax
    autocmd!
    autocmd BufNewFile,BufRead Caddyfile,*.Caddyfile,Caddyfile.* set filetype=caddyfile
    autocmd FileType caddyfile call s:caddyfile_syntax()

    function! s:caddyfile_syntax()
        if exists("b:current_syntax")
            return
        endif

        syn match caddyDirective "\v^\s*(\w\S*)" nextgroup=caddyDirectiveArgs skipwhite
        syn region caddyDirectiveArgs start="" end="\({\|#\|$\)"me=s-1 oneline contained contains=caddyPlaceholder,caddyString,caddyNamedMatcher nextgroup=caddyDirectiveBlock skipwhite
        syn region caddyDirectiveBlock start="{" skip="\\}" end="}" contained contains=caddySubdirective,caddyComment,caddyImport

        syn match caddySubdirective "\v^\s*(\w\S*)" contained nextgroup=caddySubdirectiveArgs skipwhite
        syn region caddySubdirectiveArgs start="" end="\(#\|$\)"me=s-1 oneline contained contains=caddyPlaceholder,caddyString,caddyNamedMatcher

        " Needs priority over Directive
        syn match caddyImport "\v^\s*<import>" nextgroup=caddyImportPattern skipwhite
        syn match caddyImportPattern "\v\c\S+" contained nextgroup=caddyImportArgs skipwhite
        syn region caddyImportArgs start="" end="$"me=s-1 oneline contained contains=caddyPlaceholder,caddyString,caddyNamedMatcher

        syn match caddyHost "\v\c^\s*\zs(https?://)?(([0-9a-z-]+\.)([0-9a-z-]+\.?)+|[0-9a-z-]+)?(:\d{1,5})?" nextgroup=caddyHostBlock skipwhite
        syn region caddyHostBlock start="{" skip="\\}" end="}" contained contains=caddyDirective,caddyComment,caddyNamedMatcherDef,caddyImport

        " Needs priority over Host
        syn region caddySnippetDef start="("rs=e+1 end=")"re=s-1 oneline keepend contains=caddySnippet
        syn match caddySnippet "\v\w+" contained nextgroup=caddySnippetBlock skipwhite

        syn match caddyNamedMatcher "\v^\s*\zs\@\S+" contained skipwhite
        syn match caddyNamedMatcherDef "\v\s*\zs\@\S+" nextgroup=caddyNamedMatcherDefBlock
        syn region caddyNamedMatcherDefBlock start="{" skip="\\}" end="}" contained contains=caddySubdirective,caddyComment,caddyImport

        syn region caddyPlaceholder start="{" skip="\\}" end="}" oneline contained
        syn region caddyString start='"' skip='\\\\\|\\"' end='"' oneline
        syn region caddyComment start="#" end="$" oneline

        hi link caddyDirective Keyword
        hi link caddySubdirective Structure
        hi link caddyHost Identifier
        hi link caddyImport PreProc
        hi link caddySnippetDef PreProc
        hi link caddySnippet Identifier
        hi link caddyPlaceholder Special
        hi link caddyString String
        hi link caddyComment Comment
        hi link caddyNamedMatcherDef caddyNamedMatcher
        hi link caddyNamedMatcher Identifier

        let b:current_syntax = "caddyfile"
    endfunction
augroup END

autocmd FileType vim setlocal tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab autoindent smartindent cindent
autocmd FileType markdown setlocal columns=100 wrap
autocmd FileType javascript setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType yaml setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType sql setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType vue setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType css setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType svg setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType html setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType php setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType sh setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab autoindent smartindent cindent
autocmd FileType caddyfile setlocal noexpandtab tabstop=4 shiftwidth=4 autoindent smartindent cindent
