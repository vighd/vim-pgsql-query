function RunPGSQLQuery(select_type)
  if (match('--USER: ', getline(1)) && getline(1)[8:] != '') && (match('--DATABASE: ', getline(2)) && getline(2)[12:] != '')
    if a:select_type == "init"
      let g:user = getline(1)[8:]
      let g:db = getline(2)[12:]
      let l:dictpath = '/tmp/' . g:db . '_dict.txt'
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
      if filereadable(l:dictpath)
        execute 'set dictionary+=' . l:dictpath
      else
        call system("echo \"" . join(l:gen_sql_dict) . "\" \| psql -A --csv -qt -U " . g:user . " " . g:db . " > " . l:dictpath)
        execute 'set dictionary+=' . l:dictpath
      endif
    elseif a:select_type == "n"
      execute '!clear && PAGER="pspg -s 6 --no-commandbar --force-uniborder" psql -U ' . g:user . ' -f % ' . g:db
      return
    else
      silent execute "'<,'>w! /tmp/vim_psql.sql"
      execute '!clear && PAGER="pspg -s 6 --no-commandbar --force-uniborder" psql -U ' . g:user . ' -f /tmp/vim_psql.sql ' . g:db
      return
    endif
  else
    echo 'Database connection parameters (USER, DATABASE) is not set!'
    return
  endif
endfunction
