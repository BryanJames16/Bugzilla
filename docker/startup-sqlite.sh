#!/bin/bash
set -euo pipefail

BUGZILLA_HOME="${BUGZILLA_HOME:-/var/www/html/bugzilla}"
ANSWER_TEMPLATE="/usr/local/share/bugzilla/checksetup_answers.txt"
ANSWER_FILE="/tmp/checksetup_answers.txt"
URLBASE="${BUGZILLA_URLBASE:-http://localhost:8080/}"
ADMIN_EMAIL="${BUGZILLA_ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${BUGZILLA_ADMIN_PASSWORD:-BugzillaAdmin123!}"
ADMIN_REALNAME="${BUGZILLA_ADMIN_REALNAME:-Bugzilla Administrator}"
DB_DRIVER="${BUGZILLA_DB_DRIVER:-sqlite}"
DB_HOST="${BUGZILLA_DB_HOST:-}"
DB_PORT="${BUGZILLA_DB_PORT:-0}"
DB_SOCK="${BUGZILLA_DB_SOCK:-}"
DB_NAME="${BUGZILLA_DB_NAME:-}"
DB_USER="${BUGZILLA_DB_USER:-}"
DB_PASS="${BUGZILLA_DB_PASS:-}"
SQLITE_DB="${BUGZILLA_SQLITE_DB:-bugs.db}"

case "${DB_DRIVER}" in
  sqlite)
    DB_HOST=""
    DB_PORT="0"
    DB_SOCK=""
    DB_NAME="${SQLITE_DB}"
    DB_USER=""
    DB_PASS=""
    ;;
  mysql)
    if [ -z "${DB_PORT}" ] || [ "${DB_PORT}" = "0" ]; then
      DB_PORT="3306"
    fi
    ;;
  mariadb)
    if [ -z "${DB_PORT}" ] || [ "${DB_PORT}" = "0" ]; then
      DB_PORT="3306"
    fi
    ;;
  Pg|pg|postgres|postgresql)
    DB_DRIVER="Pg"
    if [ -z "${DB_PORT}" ] || [ "${DB_PORT}" = "0" ]; then
      DB_PORT="5432"
    fi
    ;;
  *)
    echo "Unsupported BUGZILLA_DB_DRIVER: ${DB_DRIVER}" >&2
    echo "Supported values: sqlite, mysql, mariadb, Pg" >&2
    exit 1
    ;;
esac

if [ "${DB_DRIVER}" != "sqlite" ]; then
  : "${DB_HOST:?BUGZILLA_DB_HOST is required when BUGZILLA_DB_DRIVER is not sqlite}"
  : "${DB_NAME:?BUGZILLA_DB_NAME is required when BUGZILLA_DB_DRIVER is not sqlite}"
  : "${DB_USER:?BUGZILLA_DB_USER is required when BUGZILLA_DB_DRIVER is not sqlite}"
  : "${DB_PASS:?BUGZILLA_DB_PASS is required when BUGZILLA_DB_DRIVER is not sqlite}"
fi

case "${URLBASE}" in
  */) ;;
  *) URLBASE="${URLBASE}/" ;;
esac
export URLBASE ADMIN_EMAIL ADMIN_PASSWORD ADMIN_REALNAME
export DB_DRIVER DB_HOST DB_PORT DB_SOCK DB_NAME DB_USER DB_PASS

mkdir -p \
  "${BUGZILLA_HOME}/data/db" \
  "${BUGZILLA_HOME}/data/extensions" \
  "${APACHE_RUN_DIR:-/var/run/apache2}" \
  "${APACHE_LOCK_DIR:-/var/lock/apache2}" \
  "${APACHE_LOG_DIR:-/var/log/apache2}"

chown -R www-data:www-data \
  "${BUGZILLA_HOME}/data" \
  "${APACHE_RUN_DIR:-/var/run/apache2}" \
  "${APACHE_LOCK_DIR:-/var/lock/apache2}" \
  "${APACHE_LOG_DIR:-/var/log/apache2}"

cp "${ANSWER_TEMPLATE}" "${ANSWER_FILE}"
perl -0pi -e 'sub sq { my $s = shift; $s =~ s/\\/\\\\/g; $s =~ s/'"'"'/\\'"'"'/g; return $s; } s/__ADMIN_EMAIL__/sq($ENV{ADMIN_EMAIL})/ge; s/__ADMIN_PASSWORD__/sq($ENV{ADMIN_PASSWORD})/ge; s/__ADMIN_REALNAME__/sq($ENV{ADMIN_REALNAME})/ge; s/__DB_DRIVER__/sq($ENV{DB_DRIVER})/ge; s/__DB_HOST__/sq($ENV{DB_HOST})/ge; s/__DB_SOCK__/sq($ENV{DB_SOCK})/ge; s/__DB_NAME__/sq($ENV{DB_NAME})/ge; s/__DB_USER__/sq($ENV{DB_USER})/ge; s/__DB_PASS__/sq($ENV{DB_PASS})/ge; s/__DB_PORT__/$ENV{DB_PORT}/g; s#__URLBASE__#sq($ENV{URLBASE})#ge;' "${ANSWER_FILE}"

cd "${BUGZILLA_HOME}"

if [ -f "${BUGZILLA_HOME}/extensions/Voting/disabled" ]; then
  rm -f \
    "${BUGZILLA_HOME}/extensions/MoreBugUrl/disabled" \
    "${BUGZILLA_HOME}/extensions/OldBugMove/disabled" \
    "${BUGZILLA_HOME}/extensions/Voting/disabled"
fi

if [ "${DB_DRIVER}" != "sqlite" ] && [ -n "${DB_HOST}" ]; then
  echo "Waiting for ${DB_DRIVER} database at ${DB_HOST}:${DB_PORT}..."
  for _ in $(seq 1 60); do
    if nc -z "${DB_HOST}" "${DB_PORT}" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
  if ! nc -z "${DB_HOST}" "${DB_PORT}" >/dev/null 2>&1; then
    echo "Database ${DB_HOST}:${DB_PORT} is unreachable." >&2
    exit 1
  fi
fi

perl checksetup.pl "${ANSWER_FILE}"
rm -f "${ANSWER_FILE}"

exec apache2ctl -D FOREGROUND
