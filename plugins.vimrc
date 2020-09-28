"Region Plugins
call plug#begin('~/.local/share/nvim/plugged')
"Color
 Plug 'drewtempelmeyer/palenight.vim'
"Auto Complete /Language Server
 Plug 'w0rp/ale'
 Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}
"Github
 Plug 'tpope/vim-fugitive'
 " Plug 'airblade/vim-gitgutter'
"Fuzzy Finder
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
"Language Highlighting
Plug 'sheerun/vim-polyglot'
Plug 'uiiaoo/java-syntax.vim'
 " Plug 'nvim-treesitter/nvim-treesitter'
"New Motions
Plug 'romainl/vim-cool'
Plug 'wellle/targets.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'justinmk/vim-sneak'
Plug 'svermeulen/vim-cutlass'
Plug 'svermeulen/vim-subversive'
"StatusLine
" Plug 'ap/vim-buftabline'
Plug 'itchyny/lightline.vim'
" Plug 'maximbaz/lightline-ale'
"Testing
Plug 'janko-m/vim-test'
"Highlighting
 " Plug 'markonm/traces.vim'
 " Plug 'TaDaa/vimade'
 "Snip
 " Plug 'SirVer/ultisnips'
 Plug 'honza/vim-snippets'
 "Autoformater
 " Plug 'sbdchd/neoformat'
 " Plug 'ambv/black'
 " Plug 'prettier/vim-prettier'
 Plug 'alvan/vim-closetag'
 "Extra TOols
 " Plug 'myusuf3/numbers.vim'
 Plug 'ryanoasis/vim-devicons'
call plug#end()
"EndRegion
