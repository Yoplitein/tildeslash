"""Yoplitein's simple and sweet .vimrc

""general stuff
set nocompatible
syntax on

"indentation
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent

"show cursor position
set ruler

"highlighted search
set hlsearch

"show line numbers
set nu

"make searches case-insensitive unless they contain a capital letter
set ignorecase
set smartcase

"disable automatic insertion of comments when starting a new line
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

"fix for function key weirdness under screen
if match($TERM, "screen")!=-1
    set term=xterm
endif

""binds and other automation
nnoremap <F1> :noh<return><esc>
nnoremap <F2> :set nonumber!<CR>
nnoremap <F5> :undo<CR>
nnoremap <F6> :redo<CR>
nnoremap ] :next<CR>
nnoremap [ :previous<CR>

"sets F3 to toggle pasting mode
set pastetoggle=<F3>

"clears entire buffer
command ClearPaste call feedkeys("G\<End>vggd")
nnoremap <F4> :ClearPaste<CR>

"move lines up and down
command MoveLineUp call feedkeys(line(".")==1?"":"ddkkp")
command MoveLineDown call feedkeys("ddp")

nnoremap w :MoveLineUp<CR>
nnoremap s :MoveLineDown<CR>

"don't strip spaces from empty lines
inoremap <CR> <CR>x<BS>

"goppend made me do it
nnoremap x :echo "hi goppend"<CR>

""highlighting settings
"change comments to a light blue (courtesy of Kev)
hi comment ctermfg=blue
