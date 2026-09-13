FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*


COPY conf/nginx.conf /etc/nginx/conf.d/nginx.conf

COPY small-portfolio/index.html /var/www/html/index.html



CMD ["nginx", "-g", "daemon off;"]