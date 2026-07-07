FROM iprobedroid/swgoh-arena-tracker:beta-24

RUN apk add --no-cache python3

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PORT=8080 \
    KEEPALIVE_INTERVAL=420

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
