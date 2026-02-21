{ writeShellScriptBin
, postgresql
}:
writeShellScriptBin "postgres-start" ''
  [[ -d "$PGHOST" ]] || \
    ${postgresql}/bin/initdb -D "$PGHOST/db"
  ${postgresql}/bin/pg_ctl \
    -D "$PGHOST/db" \
    -l "$PGHOST/log" \
    -o "--unix_socket_directories='$PGHOST'" \
    -o "--listen_addresses=" \
    start
''
