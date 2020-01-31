" Pager used to parse psql output
let g:pager = 'PAGER="pspg -s 6 --no-commandbar --force-uniborder"'
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
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute ':!clear && ' . g:pager . ' psql -U ' . g:psql_user . ' -f % -d ' . g:psql_db
  endif
endfunction

" RunPGSQLQueryVisual executes only the visual selection.
fun! RunPGSQLQueryVisual() range
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute "'<,'>w! /tmp/vim_psql.sql"
    execute '!clear && ' . g:pager . ' psql -U ' . g:psql_user . ' -f /tmp/vim_psql.sql -d ' . g:psql_db
  endif
endfunction

" RunPGSQLQueryToCsv prompts for the save path, then executes the visual
" selection and saves as csv to the given path.
fun! RunPGSQLQueryToCsv() range
  call RunPGSQLCheckConnecionParams()

  if g:psql_conn_state == 'ok'
    execute "'<,'>w! /tmp/vim_psql_to_csv.sql"
    let curline = getline('.')
    call inputsave()
    let l:csv_save_path = input('File name to save csv: ')
    call inputrestore()
    execute '!clear && ' . g:pager . ' psql -U ' . g:psql_user . ' --csv -o ' . l:csv_save_path . ' -f /tmp/vim_psql_to_csv.sql -d ' . g:psql_db
  endif
endfunction
