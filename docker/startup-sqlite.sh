#!/bin/bash
set -euo pipefail

BUGZILLA_HOME="${BUGZILLA_HOME:-/var/www/html/bugzilla}"
ANSWER_TEMPLATE="/usr/local/share/bugzilla/checksetup_answers_sqlite.txt"
ANSWER_FILE="/tmp/checksetup_answers_sqlite.txt"
URLBASE="${BUGZILLA_URLBASE:-http://localhost:8080/}"
ADMIN_EMAIL="${BUGZILLA_ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${BUGZILLA_ADMIN_PASSWORD:-BugzillaAdmin123!}"
ADMIN_REALNAME="${BUGZILLA_ADMIN_REALNAME:-Bugzilla Administrator}"
SQLITE_DB="${BUGZILLA_SQLITE_DB:-bugs.db}"
case "${URLBASE}" in
  */) ;;
  *) URLBASE="${URLBASE}/" ;;
esac
export URLBASE ADMIN_EMAIL ADMIN_PASSWORD ADMIN_REALNAME SQLITE_DB

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
perl -0pi -e 'sub sq { my $s = shift; $s =~ s/\\/\\\\/g; $s =~ s/'"'"'/\\'"'"'/g; return $s; } s/__ADMIN_EMAIL__/sq($ENV{ADMIN_EMAIL})/ge; s/__ADMIN_PASSWORD__/sq($ENV{ADMIN_PASSWORD})/ge; s/__ADMIN_REALNAME__/sq($ENV{ADMIN_REALNAME})/ge; s#__URLBASE__#sq($ENV{URLBASE})#ge; s/__SQLITE_DB__/sq($ENV{SQLITE_DB})/ge;' "${ANSWER_FILE}"

cd "${BUGZILLA_HOME}"

if [ -f "${BUGZILLA_HOME}/extensions/Voting/disabled" ]; then
  rm -f \
    "${BUGZILLA_HOME}/extensions/MoreBugUrl/disabled" \
    "${BUGZILLA_HOME}/extensions/OldBugMove/disabled" \
    "${BUGZILLA_HOME}/extensions/Voting/disabled"
fi

perl checksetup.pl "${ANSWER_FILE}"
rm -f "${ANSWER_FILE}"

exec apache2ctl -D FOREGROUND
