"KeyBindings
let mapleader=" "
nnoremap Q <Nop> 
"Subverse
nmap <Leader>r <plug>(SubversiveSubstitute)
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
nmap <silent> gr <Plug>(coc-references)
nmap <leader>ar <Plug>(coc-rename)



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
nmap <Leader>tt :vs <bar> terminal yarn test <cr>
nmap <Leader>tn :TestNearest<CR> 
nmap <Leader>tf :TestFile<CR>    
nmap <Leader>ts :TestSuite<CR>   
nmap <Leader>tl :TestLast<CR>    
nmap <Leader>tv :TestVisit<CR>   
"Yarn
nmap <Leader>yg :vs <bar> terminal yarn generate <cr>
nmap <Leader>yb :vs <bar> terminal yarn build <cr>
nmap <Leader>yl :vs <bar> terminal yarn lint <cr>
nmap <Leader>yt :vs <bar> terminal yarn test <cr>
"Git
nmap <Leader>gs :Gstatus<cr>
nmap <Leader>gc :Gcommit -v<cr>
nmap <Leader>ga :Git add -p<cr>
nmap <Leader>gm :Gcommit --amend<cr>
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
