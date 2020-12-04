"Region Plugins
call plug#begin('~/.local/share/nvim/plugged')
"Color
  " Plug 'drewtempelmeyer/palenight.vim'
  Plug 'christianchiarulli/nvcode-color-schemes.vim'
  "
"Auto Complete /Language Server
  Plug 'w0rp/ale'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  
"Github
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
"Fuzzy Finder
 Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
 Plug 'junegunn/fzf.vim'
"Language Highlighting
 Plug 'sheerun/vim-polyglot'
 Plug 'ekalinin/Dockerfile.vim'
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
 Plug 'itchyny/lightline.vim'
"Testing
 Plug 'janko-m/vim-test'
"Highlighting
 Plug 'markonm/traces.vim'
 " Plug 'TaDaa/vimade'
 "Snip
  " Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
 "Autoformater
  Plug 'alvan/vim-closetag'
 "Extra TOols
  Plug 'ryanoasis/vim-devicons'
call plug#end()
"EndRegion
