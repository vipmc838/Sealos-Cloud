FROM ghcr.io/nezhahq/nezha AS app

FROM nginx:stable-alpine

RUN apk add --no-cache wget unzip bash curl git tar openssl jq procps tzdata zip sqlite sqlite-libs

COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=app /etc/ssl/certs /etc/ssl/certs

COPY main.conf /etc/nginx/conf.d/main.conf

ENV TZ=Asia/Shanghai

WORKDIR /dashboard

COPY --from=app /dashboard/app /dashboard/app

RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

EXPOSE 8008

ENV ARGO_DOMAIN="" \
    ARGO_AUTH="" \
    GITHUB_TOKEN="" \
    GITHUB_REPO_OWNER="" \
    GITHUB_REPO_NAME="" \
    BACKUP_BRANCH="" \
    NZ_UUID="" \
    NZ_CLIENT_SECRET="" \
    NZ_TLS="" \
    DASHBOARD_VERSION="" \
    NZ2_DOMAIN="" \
    NZ2_UUID="" \
    NZ2_TLS=""


COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /backup.sh && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
