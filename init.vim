source  ~/.config/nvim/plugins.vimrc
source  ~/.config/nvim/key_bindings.vimrc
source  ~/.config/nvim/functions.vimrc
source  ~/.config/nvim/settings.vimrc

" syntax on 
let $FZF_DEFAULT_COMMAND = 'ag -g ""'
""
""Highlights"
highlight LineNr term=bold cterm=NONE ctermfg=white ctermbg=NONE gui=NONE guifg=white guibg=NONE
highlight CursorLineNr term=bold ctermfg=11 gui=bold guifg=Yellow
autocmd CursorHold * silent call CocActionAsync('highlight')
"" EndRegion
"" Ale
hi CocUnderline gui=undercurl term=underline
hi CocErrorHighlight ctermfg=red  guifg=#c4384b gui=underline term=underline
hi CocWarningHighlight ctermfg=yellow guifg=#c4ab39 gui=underline term=underline
"" EndRegion
"" Test
let test#strategy = "neovim"
if has('nvim')
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  tnoremap <Esc> <C-\><C-n>
endif
""EndRegion
""NeoFormat
"LightLine
let g:lightline = {
      \ 'colorscheme': 'nord',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch','filename', 'readonly','coc_error', 'coc_warning' ] ]
      \ },
      \ 'component_function': {
      \   'cocstatus': 'coc#error',
      \   'gitbranch': 'fugitive#head'
      \ },
      \ }
""EndRegion
"Region ClostTages
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.js,*.tsx'
"Region ClostTages
"Region COC
function! s:cocActionsOpenFromSelected(type) abort
  execute 'CocCommand actions.open ' . a:type
endfunction
xmap <silent> <leader>a :<C-u>execute 'CocCommand actions.open ' . visualmode()<CR>
nmap <silent> <leader>a :<C-u>set operatorfunc=<SID>cocActionsOpenFromSelected<CR>g@
au TermOpen * setlocal listchars= nonumber norelativenumber
au TermOpen * startinsert
au BufEnter,BufWinEnter,WinEnter term://* startinsert
au BufLeave term://* stopinsert
"Region TreeSitter
lua require'nvim-treesitter.configs'.setup { highlight = { enable = true } }

"EndRegion
