set quiet

[default]
_list-recipes:
  {{quote(just_executable())}} --list --justfile={{quote(justfile())}}

# Back up Formbricks' PostgreSQL DB
backup:
  PGSSLROOTCERT=./aiven.io_ca.pem pg_dump \
    --clean \
    --if-exists \
    --format=custom \
    --compress=zstd:9 \
    --no-password \
    --dbname=$(grep -Po "(?<=^DATABASE_URL=').+(?='$)" .secrets) \
    --file=backups/formbricks.$(date --iso-8601=seconds).dump

# Restore Formbricks' PostgreSQL DB
restore datetime=`find ./backups -maxdepth 1 -name 'formbricks.*.dump' -print0 | xargs -0 -n1 basename | grep -oP 'formbricks\.\K.*(?=\.dump$)' | sort | tail -1`:
  PGSSLROOTCERT=./aiven.io_ca.pem pg_restore \
    --clean \
    --if-exists \
    --single-transaction \
    --no-owner \
    --no-acl \
    --no-password \
    --dbname=$(grep -Po "(?<=^DATABASE_URL=').+(?='$)" .secrets) \
    backups/formbricks.{{datetime}}.dump

# Update Dockerfile to latest stable Formbricks release
update:
  bump update

# Deploy new Formbricks release on fly.io
deploy:
  flyctl deploy --ha=false --app=digiges-forms

# Backup + Update + Deploy + Git-Commit-Push
boomp: backup update deploy
  #!/usr/bin/env bash
  VERSION=$(
    grep --perl-regexp --only-matching '^FROM\b.+?:v?\K\S+' Dockerfile \
      | tail --lines=1
  )
  git add Dockerfile && git commit -m "chore: update Formbricks to v${VERSION}" && git push
