"disable Vi compatability; enable syntax highlight,
"spaces instead of tabs, line/column numbers,
"highlighted searches and line numbers
set nocompatible
syntax on
set tabstop=4
set shiftwidth=4
set expandtab
set ruler
set hlsearch
set nu

"enables pressing F1 to remove search highlights
nnoremap <F1> :noh<return><esc>

"sets F2 to toggle pasting mode
set pastetoggle=<F2>

"Enable automatic indentation
if has("autocmd")
  filetype plugin indent on
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
  "Disable automatic comment insertion on <CR>
  autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
else
  set autoindent
endif
