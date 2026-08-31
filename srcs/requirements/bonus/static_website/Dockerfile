FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*


COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY small-portfolio/* /var/www/html/



CMD ["nginx", "-g", "daemon off;"]