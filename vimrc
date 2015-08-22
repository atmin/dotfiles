set nocompatible                                    " Use Vim settings, rather than Vi settings
set backspace=indent,eol,start                      " Make backspace behave in a sane manner.
syntax on                                           " Switch syntax highlighting on
set mouse=a                                         " Automatically enable mouse usage
set mousehide                                       " Hide the mouse cursor while typing
scriptencoding utf-8                                " UTF-8

if has('clipboard')                                 " Use system clipboard
  if has('unnamedplus')                               " When possible use + register for copy-paste
    set clipboard=unnamed,unnamedplus
  else                                                " On mac and Windows, use * register for copy-paste
    set clipboard=unnamed
  endif
endif

if has('persistent_undo')                           " Persistent undo
  set undofile
  set undolevels=1000                                 " Maximum number of changes that can be undone
  set undoreload=10000                                " Maximum number lines to save for undo on a buffer reload
  set undodir='~/.undodir/'
endif








" WHITESPACE
:set expandtab shiftwidth=2 softtabstop=2           " Whitespace is 2 spaces
" Per file type whitespace policy example
" autocmd FileType haskell,puppet,ruby,yml setlocal expandtab shiftwidth=2 softtabstop=2




" PLUGINS
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'                        " let Vundle manage Vundle, required
Plugin 'altercation/vim-colors-solarized'            " solarized color scheme
Plugin 'scrooloose/syntastic'                        " Syntax checking
Plugin 'scrooloose/nerdtree'                         " NERDTree
Plugin 'scrooloose/nerdcommenter'                    " NERDCommenter
let NERDSpaceDelims=1                                  " Put extra space after comment begin
Plugin 'kien/ctrlp.vim'                              " CtrlP
Plugin 'ervandew/supertab'                           " Supertab autocomplete
Plugin 'bling/vim-airline'                           " Nice status line
Plugin 'tpope/vim-fugitive'                          " Git goodies
Plugin 'mhinz/vim-signify'                           " Git status
Plugin 'tpope/vim-surround'                          " Surround
Plugin 'tpope/vim-abolish'                           " Replace variations
Plugin 'kristijanhusak/vim-multiple-cursors'         " Multiple cursors
Plugin 'mbbill/undotree'                             " Undo tree

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required (Enable file type detection and do language-dependent indenting)





" UI
if filereadable(expand("~/.vim/bundle/vim-colors-solarized/colors/solarized.vim"))
    let g:solarized_termcolors=256
    let g:solarized_termtrans=1
    let g:solarized_contrast="normal"
    let g:solarized_visibility="normal"
    color solarized
endif

set number                                           " Line numbers
set cursorline
highlight clear SignColumn                           " SignColumn should match background
highlight clear LineNr                               " Current line number row will have same background color in relative mode
set ruler                                            " Show the ruler
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)   " A ruler on steroids
set showcmd                                          " Show partial commands in status line and selected characters/lines in visual mode
set showmatch                                        " Show matching brackets/parenthesis
set incsearch                                        " Find as you type search
set hlsearch                                         " Highlight search terms
set smartcase                                        " Case sensitive when uc present
set list                                             " Highlight problematic whitespace
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.
au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0]) " editing a git commit message

if has('statusline')
  set laststatus=2
  set statusline=%<%f\                               " Filename
  set statusline+=%w%h%m%r                           " Options
  if !exists('g:override_spf13_bundles')
      set statusline+=%{fugitive#statusline()}       " Git Hotness
  endif
  set statusline+=\ [%{&ff}/%Y]                      " Filetype
  set statusline+=\ [%{getcwd()}]                    " Current dir
  set statusline+=%=%-14.(%l,%c%V%)\ %p%%            " Right aligned file nav info
endif






" SHORTCUTS

" Change Leader key to ,
let mapleader = ','

" Fix paste in insert mode
:imap <D-v> ^O:set paste<Enter>^R+^O:set nopaste<Enter>

" <Tab>/<Shift-Tab> = Next/Prev buffer
:nnoremap <Tab> :bnext<CR>
:nnoremap <S-Tab> :bprevious<CR>

" <Leader><Leader> = buffers
:nnoremap <Leader><Leader> :CtrlPBuffer<CR>

" Ctrl-E toggles NERDTree
map <C-e> :NERDTreeToggle<CR>

" Type // in visual mode to search selected text
:vnoremap // y/<C-R>"<CR>"

" <Leader>u toggles UndoTree
if isdirectory(expand("~/.vim/bundle/undotree/"))
  nnoremap <Leader>u :UndotreeToggle<CR>
  " If undotree is opened, it is likely one wants to interact with it.
  let g:undotree_SetFocusWhenToggle=1
endif
