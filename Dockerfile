# Use Alpine base for secure image base
FROM alpine:3.21 AS bugzilla

# Prepare package inastallation
RUN apk upgrade --no-cache

# Install Bugzilla Dependencies
RUN apk add apache2=2.4.62-r0 && \
    apk add apache2-dev=2.4.62-r0 && \
    apk add mariadb-client=11.4.5-r0 && \
    apk add netcat-openbsd=1.226.1.1-r0 && \
    apk add perl=5.40.1-r1 && \
    apk add libgd=2.3.3-r9 && \
    apk add mariadb-connector-c-dev=3.3.10-r0 && \
    apk add graphviz=12.2.0-r0 && \
    apk add vim-common=9.1.1105-r0 && \
    apk add perl-app-cpanminus=1.7048-r0 && \
    apk add perl-appconfig=1.71-r5 \
            perl-date-calc=6.4-r3 \
            perl-dbd-mysql=4.052-r1 \
            perl-template-toolkit=3.102-r0 \
            perl-datetime-timezone=2.63-r0  \
            perl-datetime=1.65-r1 \
            perl-email-address=1.913-r1 \
            perl-email-sender=2.601-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
            perl-email-mime=1.954-r0 \
            perl-dbi=1.645-r0 \
            perl-dbix-connector=0.60-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
            perl-cgi=4.67-r0 \
            perl-locale-codes=3.80-r0 \
            perl-math-random-isaac=1.004-r0 \
            perl-math-random-isaac-xs=1.004-r8 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
            perl-graph=0.9732-r0 \
            perl-xml-parser=2.47-r1 \
            perl-xml-twig=3.52-r5 \
            perl-gdgraph=1.56-r2 \
            # perl-template-plugin-gd \
            perl-soap-lite=1.27-r5 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing  \
            perl-html-scrubber=0.19-r3 \
            # perl-json-rpc=4.10-r1 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
            perl-http-daemon=6.16-r2 \
            perl-test-taint=1.08-r9  \
            perl-authen-radius=0.33-r0  \
            perl-file-slurp=9999.32-r3 \
            perl-module-build=0.4234-r1 \
            perl-net-ldap=0.68-r2 \
            perl-authen-sasl=2.1700-r0 \
            perl-file-mimeinfo=0.35-r0 \
            perl-html-formatter=2.16-r3 \
            imagemagick=7.1.1.41-r0 \
            build-base=0.5-r3 \
            curl=8.12.1-r1

# Version checks
RUN httpd --version && \
    perl --version && \
    cpanm --version

# Install Bugzilla d3pendencies through cpanm
RUN cpanm --notest --skip-installed Template::Toolkit \
            --notest --skip-installed Email::Address::XS \
            --notest --skip-installed Email::Sender \
            --notest --skip-installed Email::MIME::Modifier
# Check if Daemon Generic can run with no test and skip installed flag
# RUN cpanm Daemon::Generic
RUN cpanm --notest --skip-installed mod_perl2 -v
# Check if Apache 2 can be covered by mod_perl2
# RUN cpanm Apache2::Request
# RUN cpanm Apache2::Build
RUN cpanm --notest --skip-installed XML::Parser
# RUN cpanm Encode::Detect
# RUN cpanm TheSchwartz
# RUN cpanm CGI::JSONRPC
RUN cpanm --notest --skip-installed Net::LDAP
# RUN cpanm HTML
RUN cpanm --notest --skip-installed CGI \
            --notest --skip-installed GD::Graph \
            --notest --skip-installed Template::Plugin::GD \
            --notest --skip-installed HTML::FormatText::WithLinks

# WORKDIR /var/www/html
# COPY --chown=root:www-data . /var/www/html

# # We don't want Docker droppings accessible by the web browser since they
# # might contain setup info you don't want public
# RUN rm -rf /var/www/html/docker* /var/www/html/Dockerfile*
# RUN rm -rf /var/www/html/data /var/www/html/localconfig /var/www/html/index.html && \
#     mkdir /var/www/html/data

# EXPOSE 80/tcp
# ENTRYPOINT ["docker/startup.sh"]
