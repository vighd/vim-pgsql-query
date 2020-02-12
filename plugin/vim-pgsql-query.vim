" Pager used to parse psql output
let g:pager = 'PAGER="pspg -s 5 --no-commandbar --force-uniborder --less-status-bar --null string --bold-labels -I"'
" Init variables
let g:psql_user = 'postgres'
let g:psql_db = ''
let g:psql_host = 'localhost'
let g:psql_conn_state = ""

" This function check for the required parameters
fun! InitPGSQLQuery()
  " User
  if system("grep -Po '(?<=--USER: ).+' " . expand('%:p'))[:-2]
    let g:psql_host = system("grep -Po '(?<=--USER: ).+' " . expand('%:p'))[:-2]
  endif
  " Database
  let g:psql_db = system("grep -Po '(?<=--DATABASE: ).+' " . expand('%:p'))[:-2]
  " Host
  if system("grep -Po '(?<=--HOST: ).+' " . expand('%:p'))[:-2]
    let g:psql_host = system("grep -Po '(?<=--HOST: ).+' " . expand('%:p'))[:-2]
  endif
  " The connection is Ok so set it globally
  let g:psql_conn_state = 'ok'

  " Open the terminal if not opened yet
  if term_getstatus('vim-pgsql-query') == ""
    au BufWinLeave * if term_getstatus('vim-pgsql-query') != "" | bdelete! vim-pgsql-query | endif
    call term_start(['/bin/bash'], {'term_name': 'vim-pgsql-query', 'term_rows': 20})
    wincmd w
    " Remove shell prompt
    call TerminalRunCommand("PS1=''")
    " Disable echo of keypresses to look much more like a console
    call TerminalRunCommand("stty -echo")
    " Change directory into a safe place
    call TerminalRunCommand("[ ! -d /tmp/vim-pgsql-query ] && mkdir /tmp/vim-pgsql-query")
    call TerminalRunCommand("cd /tmp/vim-pgsql-query")  
    " Init console with a clear
    call TerminalRunCommand("clear")
    tnoremap <C-a> <C-w>N
    tnoremap <C-k> <C-w>+
    tnoremap <C-j> <C-w>-
  endif
endfunction

" This function checks the connection parameters, if any of the parameter is
" empty, call te Init function
fun! RunPGSQLCheckConnecionParams()
  let g:psql_db = system("grep -Po '(?<=--DATABASE: ).+' " . expand('%:p'))[:-2]

  if g:psql_db != ''
    call InitPGSQLQuery()
  else
    " Return error message to inform the user to set required parameters and
    " set back the variable to the initial state
    echo 'Required database connection parameters (--DATABASE: [database]) is not set at top of the file!'
    let g:psql_conn_state = ''
    let g:psql_db = ''
  endif
endfunction

" RunPGSQLQuery executes the current file.
fun! RunPGSQLQuery()
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    silent execute ':!echo ''' . g:pager . ' psql -U ' . g:psql_user . ' -h ' . g:psql_host . ' -f ' . expand('%:p') . ' -d ' . g:psql_db . ''' > /tmp/query'
    redraw!
    call TerminalRunCommand("time eval $(cat /tmp/query)")
  endif
endfunction

" RunPGSQLQueryVisual executes only the visual selection.
fun! RunPGSQLQueryVisual() range
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute "'<,'>w! /tmp/visual_query.sql"
    silent execute ':!echo ''' . g:pager . ' psql -U ' . g:psql_user . ' -h ' . g:psql_host . ' -f /tmp/visual_query.sql -d ' . g:psql_db . ''' > /tmp/query'
    redraw!
    call TerminalRunCommand("time eval $(cat /tmp/query)")
  endif
endfunction

" RunPGSQLQueryToCsv prompts for the save path, then executes the visual
" selection and saves as csv to the given path.
fun! RunPGSQLQueryToCsv() range
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    " Write out the query what we want to export as CSV
    execute "'<,'>w! /tmp/vim_psql_to_csv.sql"

    " Prompt for the path of the CSV and handle errors
    call inputsave()
    let l:csv_save_path = input('File name to save csv: ')
    call inputrestore()
    if l:csv_save_path == ""
      echoerr 'The filename is not be empty!'
      return
    endif

    " Prompt for the CSV separator string and handle errors
    call inputsave()
    let l:separator_string = input('Separator string: ')
    call inputrestore()
    if l:separator_string == ""
      let l:separator_string = ';'
    endif

    " Silently run the query and handle errors
    silent execute '!clear && ' . g:pager . ' psql -U ' . g:psql_user . ' -h ' . g:psql_host . ' -t --csv -o ' . l:csv_save_path . ' -A --field-separator=\' . l:separator_string . ' -f /tmp/vim_psql_to_csv.sql -d ' . g:psql_db
    redraw!
    if v:shell_error == 0
      echo 'The CSV successfully written to: ' . l:csv_save_path
    else
      echo 'Failed to write CSV to: ' . l:csv_save_path
    endif
  endif
endfunction

" TerminalRunCommand is a helper function to run commands in a terminal
fun! TerminalRunCommand(command)
  " Exit pgsql if running
  call term_sendkeys('vim-pgsql-query', "q")
  " Stop everything before running a new command
  " and clear every user input
  sleep 10m
  call term_sendkeys('vim-pgsql-query', "\<C-c>")
  sleep 10m
  call term_sendkeys('vim-pgsql-query', "clear\<CR>")
  " Run a command
  sleep 10m
  call term_sendkeys('vim-pgsql-query', a:command . " \<CR>")
endfunction
