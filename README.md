# VIM-PGSQL-QUERY

A minimal plugin used to query PGSQL databases with psql and pspg

### Dependencies

  - psql -> https://www.postgresql.org/docs/13/app-psql.html
  - pspg -> https://github.com/okbob/pspg
  - jq -> https://stedolan.github.io/jq

### Usage

  Add these mappings:

```vim
  nnoremap <F9>   :call RunPGSQLQuery<CR>               " To run query on the current buffer
  xnoremap <F9>   :call RunPGSQLQueryVisual()<CR>       " To run query on the visual selection
  xnoremap <C-F9> :call RunPGSQLVisualQueryAsJSON()<CR> " To run query on visual selection
                                                        " then format the output as JSON
```

  Add connection parameter comment start at the every SQL file if you want to use this
  plugin. The whitespace is required!

  ```postgresql
  --USER: foo
  --DATABASE: bar_db
  --HOST: localhost (default is localhost so it is optional) 

  SELECT a FROM sample_query;
  ```

  If you executes a query, it will opens a terminal window below and the output of the query (based on the method) will be
  written to the terminal.

  You can switch between the opened windows with \<C-W>\<C-W> (CTRL-W twice). If you want
  to scroll the terminal first press \<C-a>(CTRL-a) to enter normal mode, use j-k to scroll,
  then exit from normal mode with \<a>(a).
