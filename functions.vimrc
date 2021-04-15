"Region Functions
"Disable everything
 function DisablePrettyStuff()
	 NumbersDisable
	 CocDisable
	 :syntax off
	 :set norelativenumber
	 :set nonumber
endfunction
"Find Run Auto format
 function FixFile()
   let fileType = expand('%:e')
   if fileType == 'py'
	  :Black
   elseif fileType == 'js' || fileType == 'json' || fileType == 'tsx' || fileType == 'ts' 
	  command! -nargs=0 Prettier :CocCommand prettier.formatFile
	  :Prettier
   endif
endfunction
"Find Config/Dux
  function FindExtra()
    let fileType = expand('%:e')
    let fileName = expand('%:r')
    let newFilePath = fileName . '.stories.' . fileType
    execute "vsplit" newFilePath
  endfunction
"Find Test
 function FindTest()
   let fileName = expand('%:r')
   let fileType = expand('%:e')
   let newFilePath = fileName . '.test.' . fileType
   execute "vsplit" newFilePath
 endfunction

 function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction
"EndRegion
