FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY small-portfolio/ /var/www/static/

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY --chmod=644 certs/server.crt /etc/nginx/ssl/server.crt

COPY --chmod=600 certs/server.key /etc/nginx/ssl/server.key

CMD ["nginx", "-g", "daemon off;"]