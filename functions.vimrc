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
   elseif fileType == 'js' || fileType == 'json' || fileType == 'java'|| fileType == 'tsx' || fileType == 'ts' ||'groovy'
	  command! -nargs=0 Prettier :CocCommand prettier.formatFile
	  :Prettier
   endif
endfunction
"Find Config/Dux
  function FindExtra()
    let fileType = expand('%:e')
    let fileName = expand('%:r')
    if fileType == 'py'
  	let config_dir = substitute(fileName,"Commands","Config","")
        let newFilePath = config_dir .'.config.json'
    elseif fileType == 'tsx'
         let newFilePath = './' . fileName . ".stories.tsx"
    endif

    execute "vsplit" newFilePath
  endfunction
"Find Test
 function FindTest()
   let fileName = expand('%:r')
   let fileType = expand('%:e')
   let fileDir = expand('%:p:h')
   if fileType == 'py'
        let newFilePath = fileDir . "/tests/" . "test_" . fileName
   elseif fileType == 'js'
        let newFilePath = fileDir . "/__tests__/" . "test_" . fileName
   elseif fileType == 'tsx'
        let newFilePath = fileDir . ".test.tsx"
   elseif fileType == 'java'
	let fileDir = substitute(fileName,"main","test","")
	let fileDir = substitute(fileDir,"java","groovy","")
	let newFilePath = fileDir  . 'Spec.groovy'
   elseif fileType == 'groovy'
	let fileDir = substitute(fileName,"test","main","")
	let fileDir = substitute(fileDir,"groovy","java","")
	let fileDir = substitute(fileDir,"Spec","","")
	let newFilePath = fileDir  . '.java'
   endif
   execute "vsplit" newFilePath
 endfunction

 function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction
"EndRegion
