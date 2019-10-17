#!/bin/sh

cat <<EOF
  events { }


  http {
    error_log /etc/nginx/error_log.log warn;
    client_max_body_size 20m;

    proxy_cache_path /etc/nginx/cache keys_zone=one:500m max_size=1000m;

    server {
        listen 80;
        server_name localhost;
        server_tokens off;

        location / {
          return 301 https://\$host\$request_uri;
        }
        
        location /.well-known/acme-challenge/ {
          root /var/www/certbot;
        }
    }
    
    server {
      listen 443 ssl;
      server_name localhost;

      ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
      ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
      include /etc/letsencrypt/options-ssl-nginx.conf;
      ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

      location / {
        proxy_pass http://web:9000;
        proxy_set_header    Host                \$http_host;
        proxy_set_header    X-Real-IP           \$remote_addr;
        proxy_set_header    X-Forwarded-For     \$proxy_add_x_forwarded_for;
      }
    }
  }

EOF
