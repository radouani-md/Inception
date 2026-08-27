FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY certs/server.crt /etc/nginx/ssl/server.crt

COPY certs/server.key /etc/nginx/ssl/server.key

CMD ["nginx", "-g", "daemon off;"]