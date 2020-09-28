"KeyBindings
let mapleader=" "
nnoremap Q <Nop> 
"Gradle
nmap <Leader>gb :vs <bar> terminal ./gradlew build <cr>
nmap <Leader>gt :vs <bar> terminal ./gradlew test --info <cr>
"Subverse
nmap <Leader>r <plug>(SubversiveSubstitute)
nmap <Leader>rr <plug>(SubversiveSubstituteLine)
nmap <Leader>R <plug>(SubversiveSubstituteToEndOfLine)
"Fuzzy Finder
nmap <Leader>b :Buffers<CR>
nmap <Leader>f :Files<CR>
nmap <Leader>h :History<CR>
nmap <Leader>n :CocCommand explorer<CR>

nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
"Sneak
map f <Plug>Sneak_f
map F <Plug>Sneak_F
map t <Plug>Sneak_t
map T <Plug>Sneak_T
"Coc
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
 
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
 
let g:coc_snippet_next = '<tab>'

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader> gf <Plug>(coc-format-selected)
nmap <leader>rn <Plug>(coc-rename)


"BufferLine
nnoremap <C-N> :bnext<CR>
nnoremap <C-P> :bprev<CR>
"Terminal
" nmap <Leader>` :terminal<CR>
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
nmap <Leader>tt :terminal npm run test<CR> 
nmap <Leader>tn :TestNearest<CR> 
nmap <Leader>tf :TestFile<CR>    
nmap <Leader>ts :TestSuite<CR>   
nmap <Leader>tl :TestLast<CR>    
nmap <Leader>tv :TestVisit<CR>   
"Git
nmap <Leader>gs :Gstatus<cr>
nmap <Leader>gc :Gcommit -v<cr>
nmap <Leader>ga :Git add -p<cr>
nmap <Leader>gm :Gcommit --amend<cr>
nmap <Leader>gp :Git push<cr>
nmap <Leader>gd :Gdiff<cr>
nmap <Leader>gw :Gwrite<cr>
" Auto Complete
nmap <Leader>to :call FindTest()<CR>
nmap <Leader>te :call FindExtra()<CR>
nmap <Leader>p  :call FixFile()<CR>
"DisableStuff
nmap <Leader>! :call DisablePrettyStuff()<CR>
"EndRegion
