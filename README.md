# vim-pgsql-query
                             Reference Manual~


===================================================================================
CONTENTS                                                 *vim-pgsql-query-contents*

    1. Usage................................................|vim-pgsql-query-usage|

===================================================================================
1. Dependencies.                                      vim-pgsql-query-dependencies*

  - psql -> https://www.postgresql.org/docs/11/app-psql.html
  - pspg -> https://github.com/okbob/pspg

----------------------------------------------------------------------------------

2. Usage                                                    *vim-pgsql-query-usage*

  Add these two mappings:

  nnoremap <F9> :call RunPGSQLQuery("n")<CR> " To run query on the current buffer
  xnoremap <F9> :call RunPGSQLQuery("v")<CR> " To run query on the visual selection

  Add this autocmd:

  au BufRead,BufNewFile *.sql call RunPGSQLQuery("init")

  Add a header comment to the every SQL file if you want to use this plugin. The
  whitespace is required!

  --USER: [db-user-name]
  --POSTGRES: [db-name]
