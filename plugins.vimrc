"Region Plugins
call plug#begin('~/.local/share/nvim/plugged')
"Color
  Plug 'shaunsingh/nord.nvim'
  Plug 'christianchiarulli/nvcode-color-schemes.vim'
  "
"Auto Complete /Language Server
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  
"Github
  Plug 'tpope/vim-fugitive'
  Plug 'stsewd/fzf-checkout.vim'
  Plug 'airblade/vim-gitgutter'
"Fuzzy Finder
 Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
 Plug 'junegunn/fzf.vim'
 Plug 'nvim-lua/plenary.nvim'
 Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.2' }
"Language Highlighting
 Plug 'ekalinin/Dockerfile.vim'
 Plug 'nvim-treesitter/nvim-treesitter'
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
 Plug 'nvim-lualine/lualine.nvim'
 Plug 'kyazdani42/nvim-web-devicons'
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
 "Addons
  " Plug 'karb94/neoscroll.nvim'
 "Extra Tools
 Plug 'nvim-tree/nvim-web-devicons'
  Plug 'metakirby5/codi.vim'
call plug#end()
"EndRegion

