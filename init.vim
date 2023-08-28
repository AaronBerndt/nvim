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
set clipboard=unnamedplus
if has('nvim')
  let test#neovim#term_position = "vert"
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  tnoremap <Esc> <C-\><C-n>
endif
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
"Region Tree Sitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
   highlight = {
	enable = true,              -- false will disable the whole extension
	disable = {},  -- list of language that will be disabled
  },
}
EOF
"EndRegion
"Region Lualine
lua << EOF
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {},
    always_divide_middle = true,
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}
EOF

lua << EOF
require'nvim-web-devicons'.setup {
 -- your personnal icons can go here (to override)
 -- you can specify color or cterm_color instead of specifying both of them
 -- DevIcon will be appended to `name`
 override = {
  zsh = {
    icon = "",
    color = "#428850",
    cterm_color = "65",
    name = "Zsh"
  }
 };
 -- globally enable different highlight colors per icon (default to true)
 -- if set to false all icons will have the default icon's color
 color_icons = true;
 -- globally enable default icons (default to false)
 -- will get overriden by `get_icons` option
 default = true;
 -- globally enable "strict" selection of icons - icon will be looked up in
 -- different tables, first by filename, and if not found by extension; this
 -- prevents cases when file doesn't have any extension but still gets some icon
 -- because its name happened to match some extension (default to false)
 strict = true;
 -- same as `override` but specifically for overrides by filename
 -- takes effect when `strict` is true
 override_by_filename = {
  [".gitignore"] = {
    icon = "",
    color = "#f1502f",
    name = "Gitignore"
  }
 };
 -- same as `override` but specifically for overrides by extension
 -- takes effect when `strict` is true
 override_by_extension = {
  ["log"] = {
    icon = "",
    color = "#81e043",
    name = "Log"
  }
 };
}
EOF
