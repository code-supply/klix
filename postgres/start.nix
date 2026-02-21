{
  postgresql_18,
  writeShellScriptBin,
}:
writeShellScriptBin "postgres-start" ''
  [[ -d "$PGHOST" ]] || \
    ${postgresql_18}/bin/initdb -D "$PGHOST/db"
  ${postgresql_18}/bin/pg_ctl \
    -D "$PGHOST/db" \
    -l "$PGHOST/log" \
    -o "--unix_socket_directories='$PGHOST'" \
    -o "--listen_addresses=" \
    start
''
