FROM debian:bookworm-slim

LABEL maintainer="Bryan James"
LABEL description="Docker image for Bugzilla 5.2."

ENV DEBIAN_FRONTEND=noninteractive \
    BUGZILLA_HOME=/var/www/html/bugzilla \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY docker/apt-packages.lock /tmp/apt-packages.lock
COPY docker/cpan-modules.lock /tmp/cpan-modules.lock

RUN set -eux; \
    apt-get update; \
    mapfile -t install_args < /tmp/apt-packages.lock; \
    apt-get install -y --no-install-recommends "${install_args[@]}"; \
    sed -ri 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf; \
    printf 'ServerName localhost\n' > /etc/apache2/conf-available/servername.conf; \
    a2dissite 000-default; \
    a2enconf servername; \
    a2enmod cgi expires headers rewrite; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY --chown=root:www-data bugzilla-5.2/ ${BUGZILLA_HOME}/
COPY docker/apache-bugzilla.conf /etc/apache2/sites-available/bugzilla.conf
COPY docker/checksetup_answers.txt /usr/local/share/bugzilla/checksetup_answers.txt
COPY docker/startup-sqlite.sh /usr/local/bin/bugzilla-startup

RUN set -eux; \
    cd ${BUGZILLA_HOME}; \
    perl Build.PL; \
    mapfile -t cpan_modules < /tmp/cpan-modules.lock; \
    cpanm \
      --from https://cpan.metacpan.org \
      --mirror-only \
      --notest \
      --skip-installed \
      "${cpan_modules[@]}"; \
    a2ensite bugzilla; \
    chmod 0755 /usr/local/bin/bugzilla-startup; \
    mkdir -p ${BUGZILLA_HOME}/data ${BUGZILLA_HOME}/data/db ${BUGZILLA_HOME}/data/extensions ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR}; \
    chown -R www-data:www-data ${BUGZILLA_HOME} ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR}; \
    find ${BUGZILLA_HOME} -type d -exec chmod 0755 {} +; \
    find ${BUGZILLA_HOME} -type f -exec chmod 0644 {} +; \
    find ${BUGZILLA_HOME} -name '*.cgi' -exec chmod 0755 {} +; \
    find ${BUGZILLA_HOME} -name '*.pl' -exec chmod 0755 {} +; \
    chmod 0755 ${BUGZILLA_HOME}/mod_perl.pl; \
    rm -f /tmp/apt-packages.lock /tmp/cpan-modules.lock; \
    rm -rf ${BUGZILLA_HOME}/docker ${BUGZILLA_HOME}/Dockerfile ${BUGZILLA_HOME}/Dockerfile.mariadb ${BUGZILLA_HOME}/docker-compose.yml

VOLUME ["/var/www/html/bugzilla/data"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8080/index.cgi >/dev/null || exit 1

USER www-data

ENTRYPOINT ["tini", "--", "/usr/local/bin/bugzilla-startup"]
