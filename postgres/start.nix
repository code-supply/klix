{
  postgresql_18,
  writeShellScriptBin,
}:
writeShellScriptBin "postgres-start" ''
  [[ -d "$PGHOST" ]] || \
    ${postgresql_18}/bin/initdb \
    --pgdata "$PGHOST/db" \
    --username postgres

  > "$PGHOST/db/pg_ident.conf"
  echo "runner_can_be_postgres runner postgres" >> "$PGHOST/db/pg_ident.conf"
  echo "andrew_can_be_postgres andrew postgres" >> "$PGHOST/db/pg_ident.conf"

  ${postgresql_18}/bin/pg_ctl \
    -D "$PGHOST/db" \
    -l "$PGHOST/log" \
    -o "--unix_socket_directories='$PGHOST'" \
    -o "--listen_addresses=" \
    start
''
