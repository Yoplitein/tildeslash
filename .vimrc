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

"status line tweaks
set laststatus=2
set statusline=%t\ %y\ %#error#%{&modified==1?'[UNSAVED]':''}%#StatusLine#%=\ col\ %c/row\ %l\ \ \ \ %P
hi StatusLine ctermbg=black ctermfg=darkyellow

"highlighted search
set hlsearch

"show line numbers
set number

"make searches case-insensitive unless they contain a capital letter
set ignorecase
set smartcase

"move cursor while typing out search
set incsearch

"no (awful) word wrapping
set nowrap

"disable automatic insertion of comments when starting a new line
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

"use tabs in Makefiles
autocmd FileType make setlocal noexpandtab

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

"sublime-like insert mode bindings
inoremap <C-p> <C-o>:
inoremap <C-y> <C-o>:redo<CR>
inoremap <C-s> <C-o>:w<CR>
inoremap <C-k> <Home><C-o>v<End>d<Home>
inoremap <C-n> <C-o>:normal n<CR>
inoremap <C-b> <C-o>:normal N<CR>

"might require changing suspend key (stty susp)
"can still suspend with :suspend
inoremap <C-z> <C-o>:undo<CR>

"searching (<C-_> is actually ctrl+/)
inoremap <C-_> <C-o>/

"sets F3 to toggle pasting mode
set pastetoggle=<F3>

"clears entire buffer
command ClearPaste call feedkeys("G\<End>vggd")
nnoremap <F4> :ClearPaste<CR>

"move lines up and down
nnoremap w :m -2<CR>
nnoremap s :m +1<CR>

"don't strip spaces from empty lines
inoremap <CR> <CR>x<BS>

"goppend made me do it
nnoremap x :echo "hi goppend"<CR>

""highlighting settings
"change comments to a light blue (courtesy of Kev)
hi comment ctermfg=blue

""filetype associations
"AngelScript
au BufNewFile,BufRead *.as setlocal ft=cpp
