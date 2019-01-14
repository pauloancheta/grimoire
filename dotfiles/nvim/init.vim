call plug#begin('~/.nvim/plugged')
  Plug 'airblade/vim-gitgutter'

  Plug 'bling/vim-airline'

  Plug 'gko/vim-coloresque'

  Plug 'jalvesaq/Nvim-R'
  Plug 'janko-m/vim-test'
  Plug 'jiangmiao/auto-pairs'

  Plug 'kien/ctrlp.vim'

  Plug 'neomake/neomake'

  Plug 'rking/ag.vim'

  Plug 'scrooloose/syntastic'
  Plug 'scrooloose/nerdtree'
  Plug 'sheerun/vim-polyglot' " SYNTAX HIGHLIGHTS

  Plug 'terryma/vim-multiple-cursors'
  Plug 'tpope/vim-dispatch'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-sensible'
  Plug 'tpope/vim-rails'

  Plug 'vim-airline/vim-airline-themes'
  Plug 'vim-scripts/HTML-AutoCloseTag'

  " Plug 'godlygeek/tabular'
  " Plug 'garbas/vim-snipmate'
  " Plug 'tomtom/tlib_vim' " snipmate dep
  " Plug 'MarcWeber/vim-addon-mw-utils' " snipmate dep
  " Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install' } " Plugin outside ~/.vim/plugged with post-update hook
  " Plug 'https://github.com/junegunn/vim-github-dashboard.git' " Using git URL
call plug#end()

" VIM TEST
map <silent> ,t :TestNearest<CR>
map <silent> ,T :TestFile<CR>
let g:test#preserve_screen = 1
let test#strategy = "neovim"

" NEOMAKE
map <silent> <A-M> :Neomake<cr>
map <silent> <A-<> :lopen<cr>
map <silent> <A->> :lclose<cr>
let g:neomake_javascript_enabled_makers = ['eslint']
" call neomake#configure#automake('rw', 1000)
" call neomake#configure#automake('w')
" au BufReadPost,BufWritePost * Neomake

" SYNTASTIC
" set statusline=%f:%l\ %m%=[line\ %l\/%L]
" let g:syntastic_enable_signs=1
" let g:syntastic_auto_loc_list=2

" VIM-AIRLINE
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='base16'
let g:airline_solarized_bg='dark'
let g:airline_powerline_fonts = 1
let g:airline#extensions#hunks#enabled=0
let g:airline#extensions#default#layout = [['a', 'b', 'c'],['z']]
let g:airline_section_z='line %l/%L'

" VIM-MULTIPLE-CURSORS
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_quit_key='<Esc>'

" GIT-GUTTER
" let g:gitgutter_realtime = 0
" let g:gitgutter_eager = 0

" NERDtree
let g:NERDTreeChDirMode       = 2
let g:ctrlp_working_path_mode = 'rw'

" AUTO-PAIRS
let g:AutoPairsFlyMode = 0

" COLORS
set colorcolumn=100
set background=dark
let g:solarized_termcolors=32
let g:solarized_termtrans=1
colorscheme jellybeans
highlight ColorColumn guibg=Black

" ------------------------------------------------------------------------------------
"                                  MORE CONFIG!
" ------------------------------------------------------------------------------------
set tabstop=2     " Size of a hard tabstop
set softtabstop=2
set shiftwidth=2
set smarttab    " Make 'tab' insert indents instead of tabs at the beginning of a line
set expandtab     " always use spaces instead of tab characters
set splitright    " v split
set number        " line numbers
set autoread      " auto refresh
set hid           " a buffer becomes hidden when it is abandoned
set noswapfile    " take out swap files
set cursorline!   " see where the cursor is easier
set nopaste       " get that annoying paste out
set nohls         " don't highlight everything
set so=10         " have cursor relatively in the middle
set nopaste

" ------------------------------------------------------------------------------------
"                                  KEY BINDINGS
" ------------------------------------------------------------------------------------
let mapleader=" "

" SPLITS
nmap <silent> <leader>W :split<CR>
nmap <silent> <leader>w :vsplit<CR>

" WINDOW RESIZE
nnoremap <A-H> :vertical resize +10<CR>
nnoremap <A-L> :vertical resize -10<CR>
nnoremap <A-K> :resize -5<CR>
nnoremap <A-J> :resize +5<CR>

" TABS
nmap <C-T> :tabe<CR>
" map <leader>h :tabn<CR>
" map <leader>l :tabp<CR>

" COPY AND PASTE LINES
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" YANK TO CLIPBOARD
imap <C-V> <Esc>"+gPi
" hello world
vmap <C-C> "+y

" TERMINAL
" map the same esc for normal and insert mode
tnoremap <C-q> <C-\><C-n>
imap <C-q> <ESC>

" NERDTree
nnoremap <silent> <leader>\ :NERDTreeToggle<CR>

nnoremap ; :
vnoremap ; :
cnoreabbrev ag Ag
cnoreabbrev praise Gblame
cnoremap %% <C-R>=expand('%:p').'/'<cr>
map <leader>ew :e %%
map <leader>ev :vsp %%
map <leader>et :tabe %%


" ------------------------------------------------------------------------------------
"                                  R Key Bindings
" ------------------------------------------------------------------------------------
" let maplocalleader = ","
vmap <Space> <Plug>RDSendSelection
nmap <Space> <Plug>RDSendLine
let vimrplugin_applescript=0
let vimrplugin_vsplit=1

" ------------------------------------------------------------------------------------
"                                  FUNCTIONS
" ------------------------------------------------------------------------------------
" Show trailing whitespace only after some text (ignores blank lines):
hi ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" Auto trim white space
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()

" vim test to go into normal mode
if has('nvim')
  tmap <C-o> <C-\><C-n>
end
autocmd filetype crontab setlocal nobackup nowritebackup
