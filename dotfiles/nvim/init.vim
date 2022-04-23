call plug#begin('~/.nvim/plugged')
  Plug 'airblade/vim-gitgutter'

  Plug 'bling/vim-airline'

  " Plug 'gko/vim-coloresque'

  Plug 'jalvesaq/Nvim-R'
  Plug 'janko-m/vim-test'
  Plug 'jiangmiao/auto-pairs'
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/seoul256.vim'

  Plug 'neomake/neomake'

  Plug 'rking/ag.vim'

  " Plug 'scrooloose/syntastic'
  Plug 'sheerun/vim-polyglot' " SYNTAX HIGHLIGHTS

  Plug 'terryma/vim-multiple-cursors'
  Plug 'tpope/vim-dispatch'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-sensible'
  Plug 'tpope/vim-vinegar'
  Plug 'tpope/vim-rails'

  Plug 'vim-airline/vim-airline-themes'
  Plug 'preservim/vim-colors-pencil'
  " Plug 'vim-scripts/HTML-AutoCloseTag'
  " Plug 'liuchengxu/space-vim-theme'

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
map <silent> <A-,> :lopen<cr>
map <silent> <A-.> :lclose<cr>
let g:neomake_javascript_enabled_makers=['eslint']

" When writing a buffer (no delay).
call neomake#configure#automake('w')
" When writing a buffer (no delay), and on normal mode changes (after 750ms).
call neomake#configure#automake('nw', 750)
" When reading a buffer (after 1s), and when writing (no delay).
call neomake#configure#automake('rw', 1000)
" Full config: when writing or reading a buffer, and on changes in insert and
" normal mode (after 1s; no delay when writing).
call neomake#configure#automake('nrwi', 500)
" au BufReadPost,BufWritePost * Neomake

" SYNTASTIC
" set statusline=%f:%l\ %m%=[line\ %l\/%L]
" let g:syntastic_enable_signs=1
" let g:syntastic_auto_loc_list=2
" let g:syntastic_javascript_checkers=['prettier']

" VIM-AIRLINE
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='base16'
let g:airline_solarized_bg='light'
let g:airline_powerline_fonts = 1
let g:airline#extensions#hunks#enabled=0
let g:airline#extensions#default#layout = [['a', 'b', 'c'],['z']]
let g:airline_section_z='line %l/%L'

" VIM-MULTIPLE-CURSORS
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_quit_key='<Esc>'

" GIT-GUTTER
let g:gitgutter_realtime = 0
let g:gitgutter_eager = 0

" FZF
" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" AUTO-PAIRS
let g:AutoPairsFlyMode = 0

" COLORS
autocmd ColorScheme * highlight! link SignColumn LineNr
set colorcolumn=100
set background=dark
" let g:solarized_termcolors=32
" let g:solarized_termtrans=1
colorscheme pencil
highlight ColorColumn guibg=Red
let g:pencil_higher_contrast_ui=1
let g:pencil_neutral_headings=1
let g:pencil_neutral_code_bg=1

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
set foldmethod=indent
set foldlevel=99

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

" MAXIMIZE AND RESTORE
nmap <A-=> <C-w>=
nmap <A-+> <C-w>\| <C-w>_

" YANK TO CLIPBOARD
imap <C-V> <Esc>"+gPi
" hello world
vmap <C-C> "+y

" TERMINAL
" map the same esc for normal and insert mode
tnoremap <C-q> <C-\><C-n>
imap <C-q> <ESC>

" netrw
nnoremap <silent> <leader>\ :e.<CR>

" fzf
nnoremap <silent> <C-p> :FZF<CR>

nnoremap ; :
vnoremap ; :
cnoreabbrev ag Ag
cnoreabbrev praise Gblame
cnoremap %% <C-R>=expand('%:p').'/'<cr>
map <leader>ew :e %%<cr>
map <leader>ev :vsp %%<cr>
map <leader>et :tabe %%<cr>


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

" fold comments
" autocmd FileType ruby,eruby
"       \ set foldmethod=expr |
"       \ set foldexpr=getline(v:lnum)=~'^\\s*#' |
"       \ exe "normal zM``"
