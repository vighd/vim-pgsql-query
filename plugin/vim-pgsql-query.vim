" Pager used to parse psql output
let g:pager = 'PAGER="pspg -s 5 --no-commandbar --force-uniborder --less-status-bar --null string --bold-labels -I"'
" Init variables
let g:psql_user = ''
let g:psql_db = ''
let g:psql_dictpath = ''
let g:psql_conn_state = ""

" This function check for the required parameters and saves the database dict
" for keyword completion.
fun! InitPGSQLQuery()
  " User
  let g:psql_user = getline(1)[8:]
  " Database
  let g:psql_db = getline(2)[12:]
  " Dictionary location
  let g:psql_dictpath = '/tmp/' . g:psql_db . '_dict.txt'
  " Dict generator SQL query
  let l:gen_sql_dict =<< trim END
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

  " If dict is not exists generate dict and set it. Else set it.
  if filereadable(g:psql_dictpath)
    execute 'set dictionary+=' . g:psql_dictpath
  else
    call system("echo \"" . join(l:gen_sql_dict) . "\" \| psql -A --csv -qt -U " . g:psql_user . " " . g:psql_db . " > " . g:psql_dictpath)
    execute 'set dictionary+=' . g:psql_dictpath
  endif

  " The connection is Ok so set it globally
  let g:psql_conn_state = 'ok'

  " Open the terminal if not opened yet
  if term_getstatus('vim-pgsql-query') == ""
    au BufWinLeave * if term_getstatus('vim-pgsql-query') != "" | bdelete! vim-pgsql-query | endif
    call term_start(['/bin/bash'], {'term_name': 'vim-pgsql-query', 'term_rows': 20})
    call term_sendkeys('vim-pgsql-query', "PS1='' \<CR>")  
    wincmd w
    tnoremap <C-a> <C-W>N
    tnoremap <C-k> <C-W>+
    tnoremap <C-j> <C-W>-
  endif
endfunction

" This function checks the connection parameters, if any of the parameter is
" empty, call te Init function
fun! RunPGSQLCheckConnecionParams()
  if (match('--USER: ', getline(1)) && getline(1)[8:] != '') && (match('--DATABASE: ', getline(2)) && getline(2)[12:] != '')
    call InitPGSQLQuery()
  else
    " Return error message to inform the user to set required parameters and
    " set back the variable to the initial state
    echo 'Database connection parameters (--USER: [username], --DATABASE: [database]) is not set at top of the file!'
    let g:psql_conn_state = ''
    let g:psql_user = ''
    let g:psql_db = ''
  endif
endfunction

" RunPGSQLQuery executes the current file.
fun! RunPGSQLQuery()
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    silent execute ':!echo ''' . g:pager . ' psql -U ' . g:psql_user . ' -f ' . expand('%:p') . ' -d ' . g:psql_db . ''' > /tmp/query'
    redraw!
    call RunPGSQLQueryInTerminal()
  endif
endfunction

" RunPGSQLQueryVisual executes only the visual selection.
fun! RunPGSQLQueryVisual() range
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute "'<,'>w! /tmp/visual_query.sql"
    silent execute ':!echo ''' . g:pager . ' psql -U ' . g:psql_user . ' -f /tmp/visual_query.sql -d ' . g:psql_db . ''' > /tmp/query'
    redraw!
    call RunPGSQLQueryInTerminal()
  endif
endfunction

" RunPGSQLQueryToCsv prompts for the save path, then executes the visual
" selection and saves as csv to the given path.
fun! RunPGSQLQueryToCsv() range
  " Check the file header for connection parameters
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute "'<,'>w! /tmp/vim_psql_to_csv.sql"
    let curline = getline('.')
    call inputsave()
    let l:csv_save_path = input('File name to save csv: ')
    call inputrestore()
    call inputsave()
    let l:separator_string = input('Separator string: ')
    call inputrestore()
    execute '!clear && ' . g:pager . ' psql -U ' . g:psql_user . ' -t --csv -o ' . l:csv_save_path . ' -A --field-separator=\' . l:separator_string . ' -f /tmp/vim_psql_to_csv.sql -d ' . g:psql_db
  endif
endfunction

" RunPGSQLQueryInTerminal is a helper function which determines the mode needed to run a query
fun! RunPGSQLQueryInTerminal()
  " If pspg running, exit first then run the query else simply run the query
  if system('pidof pspg') != ""
    call term_setsize('vim-pgsql-query', 20, 0)
    call term_sendkeys('vim-pgsql-query', "q clear && time eval $(cat /tmp/query) \<CR>")  
  else
    call term_setsize('vim-pgsql-query', 20, 0)
    call term_sendkeys('vim-pgsql-query', "clear && time eval $(cat /tmp/query) \<CR>")  
  endif
endfunction
