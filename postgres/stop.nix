{ writeShellScriptBin
}:
writeShellScriptBin "postgres-stop" ''
  pg_ctl \
    -D "$PGHOST/db" \
    -l "$PGHOST/log" \
    -o "--unix_socket_directories=$PGHOST" \
    stop
''
