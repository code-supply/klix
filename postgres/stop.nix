{
  postgresql_18,
  writeShellScriptBin,
}:
writeShellScriptBin "postgres-stop" ''
  ${postgresql_18}/bin/pg_ctl \
    -D "$PGHOST/db" \
    -l "$PGHOST/log" \
    -o "--unix_socket_directories=$PGHOST" \
    stop
''
