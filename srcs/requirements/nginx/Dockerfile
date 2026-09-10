FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -newkey rsa:2048 -days 365 -nodes \
    -subj "/CN=mradouan.42.fr" \ 
    -keyout /etc/nginx/ssl/server.key
    -out /etc/nginx/ssl/server.crt
    

COPY conf/nginx.conf /etc/nginx/conf.d/nginx.conf

CMD ["nginx", "-g", "daemon off;"]