" ------------------------------------------------------------
"  key bind
" ------------------------------------------------------------

" default nop
vnoremap  <Up>     <nop>
vnoremap  <Down>   <nop>
vnoremap  <Left>   <nop>
vnoremap  <Right>  <nop>
vnoremap  <BS>     <nop>
inoremap  <Up>     <nop>
inoremap  <Down>   <nop>
inoremap  <Left>   <nop>
inoremap  <Right>  <nop>
inoremap  <BS>     <nop>
noremap   <Up>     <nop>
noremap   <Down>   <nop>
noremap   <Left>   <nop>
noremap   <Right>  <nop>
noremap   <BS>     <nop>

" Normal Mode
cnoremap init :<C-u>edit $MYVIMRC<CR>
noremap <Space>s :source $MYVIMRC<CR>
noremap <Space>w :<C-u>w<CR>
noremap <silent><C-h> <C-w>h
noremap <silent><C-j> <C-w>j                                                                                                                                                                                                                                                noremap <silent><C-k> <C-w>k
noremap <silent><C-l> <C-w>l

" Insert Mode
inoremap <silent> jj <ESC>:<C-u>w<CR>:

" Insert mode move key bind
inoremap <C-d> <BS>
inoremap <C-h> <Left>
inoremap <C-l> <Right>
inoremap <C-k> <Up>
inoremap <C-j> <Down>

" encode setting
set encoding=utf-8

" edita setting
set number
set splitbelow
set splitright
set noequalalways
set wildmenu

" cursor setting
set ruler
set cursorline

" tab setting
set expandtab
set tabstop=2
set shiftwidth=2

" ------------------------------------------------------------
" dein.vim set up
" ------------------------------------------------------------

if &compatible
  set nocompatible
endif

let s:dein_dir = expand('~/.vim/dein')
let s:dein_repo_dir = s:dein_dir .  '/repos/github.com/Shougo/dein.vim'
let s:toml_dir = expand('~/.config/nvim')

" Required:
execute 'set runtimepath^=' . s:dein_repo_dir

" Required:
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  call dein#load_toml(s:toml_dir . '/dein.toml', {'lazy': 0})

  call dein#load_toml(s:toml_dir . '/lazy.toml', {'lazy': 1})

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif
