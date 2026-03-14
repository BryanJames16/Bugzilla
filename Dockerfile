FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    BUGZILLA_HOME=/var/www/html/bugzilla \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    pkgver() { \
      local pkg="$1"; \
      local version; \
      version="$(apt-cache policy "$pkg" | awk '/Candidate:/ {print $2}')"; \
      if [[ -z "$version" || "$version" == "(none)" ]]; then \
        echo "No install candidate found for package: $pkg" >&2; \
        exit 1; \
      fi; \
      printf '%s=%s\n' "$pkg" "$version"; \
    }; \
    mapfile -t apt_packages < <(printf '%s\n' \
      apache2 \
      build-essential \
      ca-certificates \
      cpanminus \
      curl \
      graphviz \
      imagemagick \
      libapache2-mod-perl2 \
      libappconfig-perl \
      libcgi-pm-perl \
      libdate-calc-perl \
      libdbd-mysql-perl \
      libdbd-pg-perl \
      libdbd-sqlite3-perl \
      libdbi-perl \
      libdbix-connector-perl \
      libdigest-sha-perl \
      libexpat1-dev \
      libgd-dev \
      libhtml-parser-perl \
      libicu-dev \
      libmime-tools-perl \
      libmodule-build-perl \
      libssl-dev \
      libsqlite3-dev \
      libtimedate-perl \
      liburi-perl \
      libwww-perl \
      libxml-parser-perl \
      make \
      netcat-openbsd \
      patchutils \
      perl \
      perlmagick \
      procps \
      shared-mime-info \
      sqlite3 \
      tini \
      zlib1g-dev); \
    install_args=(); \
    for pkg in "${apt_packages[@]}"; do \
      install_args+=("$(pkgver "$pkg")"); \
    done; \
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

# Bugzilla's own Build.PL is the authoritative source for required and
# recommended Perl module versions, so we install from it directly.
RUN set -eux; \
    cd ${BUGZILLA_HOME}; \
    perl Build.PL; \
    cpanm \
      --from https://cpan.metacpan.org \
      --mirror-only \
      --notest \
      --skip-installed \
      --with-recommends \
      --installdeps .; \
    a2ensite bugzilla; \
    chmod 0755 /usr/local/bin/bugzilla-startup; \
    mkdir -p ${BUGZILLA_HOME}/data ${BUGZILLA_HOME}/data/db ${BUGZILLA_HOME}/data/extensions ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR}; \
    chown -R root:www-data ${BUGZILLA_HOME}; \
    chown -R www-data:www-data ${BUGZILLA_HOME}/data ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR}; \
    find ${BUGZILLA_HOME} -type d -exec chmod 0755 {} +; \
    find ${BUGZILLA_HOME} -type f -exec chmod 0644 {} +; \
    find ${BUGZILLA_HOME} -name '*.cgi' -exec chmod 0755 {} +; \
    find ${BUGZILLA_HOME} -name '*.pl' -exec chmod 0755 {} +; \
    chmod 0755 ${BUGZILLA_HOME}/mod_perl.pl; \
    rm -rf ${BUGZILLA_HOME}/docker ${BUGZILLA_HOME}/Dockerfile ${BUGZILLA_HOME}/Dockerfile.mariadb ${BUGZILLA_HOME}/docker-compose.yml

VOLUME ["/var/www/html/bugzilla/data"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8080/index.cgi >/dev/null || exit 1

ENTRYPOINT ["tini", "--", "/usr/local/bin/bugzilla-startup"]
