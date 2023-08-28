"KeyBindings
let mapleader=" "
nnoremap Q <Nop> 
"Subverse
nmap <Leader>r <plug>(SubversiveSubstitute)
"Fuzzy Finder
nmap <Leader>f <cmd>Telescope find_files<cr>
nmap <Leader>g <cmd>Telescope live_grep<cr>
nmap <Leader>b <cmd>Telescope buffers<cr>
nmap <Leader>h <cmd>Telescope history<cr>
nmap <Leader>n :CocCommand explorer<CR>

nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
"Sneak
map f <Plug>Sneak_f
map F <Plug>Sneak_F
map t <Plug>Sneak_t
map T <Plug>Sneak_T
"Coc
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <C-x><C-z> coc#pum#visible() ? coc#pum#stop() : "\<C-x>\<C-z>"
" remap for complete to use tab and <cr>
inoremap <silent><expr> <TAB>
\ coc#pum#visible() ? coc#pum#next(1):
\ <SID>check_back_space() ? "\<Tab>" :
\ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <c-space> coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
 
let g:coc_snippet_next = '<tab>'

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>ar <Plug>(coc-rename)
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>aw  <Plug>(coc-codeaction-selected)w





"BufferLine
nnoremap <C-N> :bnext<CR>
nnoremap <C-P> :bprev<CR>
"Terminal
nmap <Leader>` :terminal<CR>
"Split
noremap <silent> <leader>ht :split <bar> :terminal<CR>
noremap <silent> <leader>vt :vsplit <bar> :terminal<CR>
"Java Stuff

"Navagation
nnoremap <C-L> <C-W><C-L>
nnoremap <C-J> <C-W><C-J>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-K> <C-W><C-K>
"Tests
nmap <Leader>tt :vs <bar> terminal yarn test <cr>
nmap <Leader>tn :TestNearest<CR> 
nmap <Leader>tf :TestFile<CR>    
nmap <Leader>ts :TestSuite<CR>   
nmap <Leader>tl :TestLast<CR>    
nmap <Leader>tv :TestVisit<CR>   
"Yarn
nmap <Leader>yg :vs <bar> terminal yarn generate <cr>
nmap <Leader>yy :vs <bar> terminal yarn start <cr>
nmap <Leader>ys :vs <bar> terminal yarn storybook <cr>
nmap <Leader>yb :vs <bar> terminal yarn build <cr>
nmap <Leader>yl :vs <bar> terminal yarn lint <cr>
nmap <Leader>yt :vs <bar> terminal yarn test <cr>
nmap <Leader>yd :vs <bar> terminal yarn run_dev <cr>
"Git
nmap <Leader>gf :diffgit //2<cr>
nmap <Leader>gj :diffgit //3<cr>
nmap <Leader>gs :Git<cr>
nmap <Leader>gc :Git commit -v<cr>
nmap <Leader>ga :Git add -p<cr>
nmap <Leader>gu :Gpull
nmap <Leader>gj :diffget //3<cr>
nmap <Leader>gf :diffget //5<cr>
nmap <Leader>gp :vs <bar> terminal git push  <cr>
nmap <Leader>gd :Gdiff<cr>
nmap <Leader>gw :Gwrite<cr>
" Auto Complete
nmap <Leader>to :call FindTest()<CR>
nmap <Leader>te :call FindExtra()<CR>
nmap <Leader>p  :call FixFile()<CR>
"DisableStuff
nmap <Leader>! :call DisablePrettyStuff()<CR>
"EndRegion

