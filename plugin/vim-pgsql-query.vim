" Pager used to parse psql output
let g:pager = " |& pspg -s 5 --no-commandbar --force-uniborder --less-status-bar --bold-labels -I"
" Command used to enable timing
let g:timing = '"\\timing"'
" Init variables
let g:psql_user = ''
let g:psql_db = ''
let g:psql_host = ''
let g:psql_conn_state = ''
let g:psql_command = ''

" This function check for the required parameters
fun! InitPGSQLQuery()
  " Open the terminal if not opened yet
  if term_getstatus('vim-pgsql-query') == ""
    au BufWinLeave * call DeInitPGSQLQuery()
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
  
  " Init dictionary
  call PGSQLQueryGenDict()
endfunction

" DeInitPGSQLQuery clears the temporary files and closes the therminal
fun! DeInitPGSQLQuery()
  if term_getstatus('vim-pgsql-query') != ""
    bdelete! vim-pgsql-query
  endif
  call system('[ -f /tmp/query ] && rm /tmp/query')
  call system('[ -f /tmp/visual_query.sql ] && rm /tmp/visual_query.sql')
  call system('[ -f /tmp/vim_pgsql_query_dict.txt ] && rm /tmp/vim_pgsql_query_dict.txt')
endfunction

" PGSQLQueryGenDict generates a dictionary file for keyword completion
fun! PGSQLQueryGenDict()
  let l:dictpath = '/tmp/vim_pgsql_query_dict.txt'
  let l:gen_sql_dict_query =<< trim END
    SELECT
    t.table_name,
    array_agg(c.column_name::text) AS columns
    FROM
    information_schema.tables t
    INNER JOIN information_schema.columns c ON
    t.table_name = c.table_name
    WHERE
    t.table_schema = 'public'
    AND t.table_type= 'BASE TABLE'
    AND c.table_schema = 'public'
    GROUP BY t.table_name;
    SELECT
    routine_name
    FROM information_schema.routines
    WHERE
    specific_schema = 'public';
  END

  call system("echo \"" . join(l:gen_sql_dict_query) . "\" \| psql -A --csv -qt -h " . g:psql_host . " -U " . g:psql_user . " -d " . g:psql_db . " > /tmp/dict")
  call system('sed -r "s/(\"|\{|\})//g" /tmp/dict | sed "s/,/\n/g" | sort | uniq > ' . l:dictpath)
  execute 'set dictionary+=' . l:dictpath
endfunction

" RunPGSQLCheckConnecionParams checks the connection parameters, if any of the parameter is
" empty, call te Init function
fun! RunPGSQLCheckConnecionParams()
  " User
  if system("grep -Poi '(?<=--USER: ).+' " . expand('%:p'))[:-2] != ""
    let g:psql_user = system("grep -Po '(?<=--USER: ).+' " . expand('%:p'))[:-2]
  else
    let g:psql_user = 'postgres'
  endif

  " Database
  let g:psql_db = system("grep -Poi '(?<=--DATABASE: ).+' " . expand('%:p'))[:-2]

  " Host
  if system("grep -Poi '(?<=--HOST: ).+' " . expand('%:p'))[:-2] != ""
    let g:psql_host = system("grep -Poi '(?<=--HOST: ).+' " . expand('%:p'))[:-2]
  else
    let g:psql_host = 'localhost'
  endif

  " The connection is Ok so set it globally
  let g:psql_conn_state = 'ok'
  " Build psql command
  let g:psql_command = "psql -U " . g:psql_user . " -h " . g:psql_host . " -d " . g:psql_db

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
    call system("echo '" . g:psql_command . " -q -c " . g:timing . " -f " . expand('%:p') . " -c " . g:timing ."' > /tmp/query")
    call TerminalRunCommand("eval $(cat /tmp/query) " . g:pager)
  endif
endfunction

" RunPGSQLVisualQuery executes only the visual selection.
fun! RunPGSQLVisualQuery() range
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute "'<,'>w! /tmp/visual_query.sql"
    call system("echo '" . g:psql_command . " -q -c " . g:timing . " -f /tmp/visual_query.sql -c " . g:timing . "' > /tmp/query")
    call TerminalRunCommand("eval $(cat /tmp/query) " . g:pager)
  endif
endfunction

" RunPGSQLVisualQueryAsJSON executes only the visual selection then format the
" output as JSON with jq.
fun! RunPGSQLVisualQueryAsJSON() range
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute "'<,'>w! /tmp/visual_query.sql"
    call system("echo '" . g:psql_command . " -Atq -f /tmp/visual_query.sql' > /tmp/query")
    call TerminalRunCommand('eval $(cat /tmp/query) \| jq .')
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
  call term_sendkeys('vim-pgsql-query', "echo $(date +%H:%m:%S) Executing query... && " . a:command . " && echo $(date +%H:%m:%S) Done. \<CR>")
endfunction
