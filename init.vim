set nowrap
set hidden
set nobackup
set nowritebackup
set noswapfile
set wildmenu
set relativenumber 
set nu

set nowrap
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" Switch syntax highlighting on when the terminal has colors or when using the
" GUI (which always has colors).
if &t_Co > 2 || has("gui_running")
    " Revert with ":syntax off".
    syntax on

    " I like highlighting strings inside C comments.
    " Revert with ":unlet c_comment_strings".
    let c_comment_strings=1
endif


" In many terminal emulators the mouse works just fine.  By enabling it you
" can position the cursor, Visually select and scroll with the mouse.
" Only xterm can grab the mouse events when using the shift key, for other
" terminals use ":", select text and press Esc.
if has('mouse')
    if &term =~ 'xterm'
        set mouse=a
    else
        set mouse=nvi
    endif
endif

map <F5> :w <CR> :!gcc % -o %<.exe && %<.exe <CR>

call plug#begin()
Plug 'ThePrimeagen/vim-be-good'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
call plug#end()

set background=dark
colorscheme gruvbox

lua require 'nvim-treesitter.install'.compilers = { "gcc" }
