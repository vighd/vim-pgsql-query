*vim-pgsql-query.txt* A minimal plugin used to query PGSQL databases with psql and pspg

========================================================================================
CONTENTS                                                      *vim-pgsql-query-contents*

    1. Usage.....................................................|vim-pgsql-query-usage|

========================================================================================
1. Dependencies.                                           vim-pgsql-query-dependencies*

  - psql -> https://www.postgresql.org/docs/12/app-psql.html
  - pspg -> https://github.com/okbob/pspg

----------------------------------------------------------------------------------------

2. Usage                                                         *vim-pgsql-query-usage*

  Add these two mappings:

  nnoremap <F9>   :call RunPGSQLQuery<CR>         " To run query on the current buffer
  xnoremap <F9>   :call RunPGSQLQueryVisual()<CR> " To run query on the visual selection
  xnoremap <S-F9> :call RunPGSQLQueryToCsv()<CR>  " To run query on the visual selection
                                                  " and saves the query output the given
                                                  " csv path (it will includes the column
                                                  " names as header)

  Add connection parameter comment start at the every SQL file if you want to use this
  plugin. The whitespace is required!

  --USER: [db-user-name]
  --POSTGRES: [db-name]

  If you executes a query, it will opens a terminal window below. Now, when you executes
  a query, the query-s output will be written into the terminal.

  You can switch between the opened windows with <C-W><C-W> (CTRL-W twice). If you want
  to scroll the terminal first press <C-a>(CTRL-a) to enter normal mode, use j-k to scroll,
  then exit from normal mode with <a>.
