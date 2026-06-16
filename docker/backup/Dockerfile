FROM alpine:3.20

RUN apk add --no-cache \
        docker-cli \
        zip \
        bash \
        findutils \
        bc \
        tzdata \
    && rm -rf /var/cache/apk/*

COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

COPY crontab /var/spool/cron/crontabs/root
RUN chmod 0644 /var/spool/cron/crontabs/root

WORKDIR /data

CMD ["crond", "-f", "-l", "2"]
