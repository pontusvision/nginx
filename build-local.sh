#!/bin/bash
VERSION=1.13.6
DIR="$( cd "$(dirname "$0")" ; pwd -P )"

OUT_DIR=$DIR/../pontus-dist/opt/pontus/nginx/nginx-$VERSION
if [[ ! -d $OUT_DIR ]]; then
  mkdir -p  $OUT_DIR
fi
CURDIR=`pwd`

cd $OUT_DIR/..
rm -rf *

cd $DIR

if [[ -f Makefile ]]; then
  make clean
fi
auto/configure --prefix=$OUT_DIR
make install


cd $OUT_DIR/..
ln -s nginx-$VERSION current

cat << 'EOF' > current/conf/nginx.conf
user  pontus;
worker_processes  1;

error_log  /opt/pontus/pontus-nginx/current/logs/error.log debug;
pid        /opt/pontus/pontus-nginx/current/nginx.pid;




events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    include       /etc/nginx/proxy.conf;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /opt/pontus/pontus-nginx/current/logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    gzip  on;

    include /opt/pontus/pontus-nginx/conf/conf.d/*.conf;

    upstream pvgdprgui {
      server 127.0.0.1:3000 weight=3;
    }

    server {
        client_max_body_size 80M;

        root /;
        ssl_protocols               TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers                 ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256;
        ssl_prefer_server_ciphers   on;
        ssl_ecdh_curve              secp384r1;

        listen       8443 ssl;
        server_name  pontus-sandbox.pontusvision.com;

        ssl_certificate      /etc/pki/java/localhost.crt;
        ssl_certificate_key  /etc/pki/java/localhost-nginx.pem;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        #ssl_ciphers  HIGH:!aNULL:!MD5;

        location ~ ^/auth.* {
           rewrite ^(/auth/.*) $1 break;
           proxy_set_header Host              $host:18443;
           proxy_set_header X-Real-IP         $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto https;

           proxy_set_header X-ProxyScheme https;
           proxy_set_header X-ProxyHost localhost;
           proxy_set_header X-ProxyPort 18443;
           proxy_set_header X-ProxyContextPath /;


           sub_filter_types text/html text/css text/xml;
           sub_filter http://localhost/auth https://localhost:18443/auth;


           #proxy_set_header    Upgrade $http_upgrade;
           #proxy_set_header    Connection "upgrade";
           #proxy_set_header    Host $host;
           proxy_set_header    X-NginX-Proxy true;

           proxy_http_version  1.1;
           proxy_redirect      off;

           proxy_pass      https://localhost:5005;


        }


        location ~ ^/nifi/.* {
           rewrite ^/nifi/(.*) /nifi/$1 break;
           rewrite ^(/nifi.*) $1 break;



           proxy_set_header X-ProxyScheme https;
           proxy_set_header X-ProxyHost localhost;
           proxy_set_header X-ProxyPort 18443;
           proxy_set_header X-ProxyContextPath /;

           proxy_set_header Host $host:18443;
           proxy_cache_bypass true;
           proxy_no_cache true;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_pass      http://127.0.0.1:5007;
        }

        location ~ ^/nifi-api.* {
           rewrite ^/nifi-api/(.*) /nifi-api/$1 break;
           rewrite ^(/nifi-api.*) $1 break;


           proxy_set_header X-ProxyScheme https;
           proxy_set_header X-ProxyHost localhost;
           proxy_set_header X-ProxyPort 18443;
           proxy_set_header X-ProxyContextPath /;

           proxy_set_header Host $host:18443;
           proxy_cache_bypass true;
           proxy_no_cache true;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_pass      http://127.0.0.1:5007;
        }

        location ~ ^/nifi-docs.* {
           rewrite ^/nifi-docs/(.*) /nifi-docs/$1 break;
           rewrite ^(/nifi-docs.*) $1 break;



           proxy_set_header X-ProxyScheme https;
           proxy_set_header X-ProxyHost localhost;
           proxy_set_header X-ProxyPort 18443;
           proxy_set_header X-ProxyContextPath /;

           proxy_set_header Host $host:18443;
           proxy_cache_bypass true;
           proxy_no_cache true;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_pass      http://127.0.0.1:5007;
        }


        location ~ ^/update-attribute-ui-.* {
           rewrite ^(/update-attribute-ui-.*) $1 break;


           proxy_set_header X-ProxyScheme https;
           proxy_set_header X-ProxyHost localhost;
           proxy_set_header X-ProxyPort 18443;
           proxy_set_header X-ProxyContextPath /;

           proxy_set_header Host $host:18443;
           proxy_cache_bypass true;
           proxy_no_cache true;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_pass      http://127.0.0.1:5007;
        }

        location ~ ^/nifi-content-viewer.* {
           rewrite ^/nifi-content-viewer/(.*) /nifi-content-viewer/$1 break;
           rewrite ^(/nifi-content-viewer.*) $1 break;


           sub_filter_types text/html text/css text/xml;
           sub_filter http://localhost/nifi-content-viewer/ https://localhost:18443/nifi-content-viewer/;

           proxy_set_header X-ProxyScheme https;
           proxy_set_header X-ProxyHost localhost;
           proxy_set_header X-ProxyPort 18443;
           proxy_set_header X-ProxyContextPath /;

           proxy_set_header Host $host:18443;
           proxy_cache_bypass true;
           proxy_no_cache true;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_pass      http://127.0.0.1:5007;
        }


        location ~ ^/gateway/sandbox/pvgdpr_server.* {
           rewrite ^/gateway/sandbox/pvgdpr_server/(.*)$ /$1 break;
           proxy_pass      http://127.0.0.1:3001;
        }

        location ~ ^/gateway/sandbox/pvgdpr_graph.*  {
           rewrite ^/gateway/sandbox/pvgdpr_graph/(.*)$ /$1 break;
           rewrite ^/gateway/sandbox/pvgdpr_graph(/.*)$ $1 break;
           rewrite ^/gateway/sandbox/pvgdpr_graph(.*)$ /$1 break;
           proxy_pass      http://127.0.0.1:8182;
        }


        #location ~  ^/full.* {
        #   rewrite_log on;
        #   rewrite ^/full/(.*) /pvgdpr/$1 break;
#
#           proxy_pass      http://127.0.0.1:3000;
#
#           #sub_filter_types text/html text/css text/xml;
#           #sub_filter /pvgdpr/pvgdpr /pvgdpr;
#
#           proxy_set_header Host $host;
#           proxy_cache_bypass true;
#           proxy_no_cache true;
#           proxy_set_header X-Real-IP $remote_addr;
#           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#
#          }
        location ~ ^/gateway/sandbox/pvgdpr_gui.* {
           rewrite_log on;
           rewrite ^/gateway/sandbox/pvgdpr_gui/pvgdpr(/.*) $1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/pvgdpr_gui(/.*) $1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/../static/(.*) /static/$1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/full/(.*) /$1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/full(.*)  /$1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/expert/(.*) /$1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/expert(.*) /$1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/re/(.*) /$1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui/re(.*) /$1 break;
           #rewrite ^/gateway/sandbox/pvgdpr_gui(/.*) $1 break;
           rewrite ^/gateway/sandbox/pvgdpr_gui(.*) /$1 break;


           root /opt/pontus/pontus-gui/current/lib/;
           #proxy_pass      http://127.0.0.1:3000;

           #sub_filter_types text/html text/css text/xml;
           #sub_filter /pvgdpr/pvgdpr /pvgdpr;

           #proxy_set_header Host $host;
           #proxy_cache_bypass true;
           #proxy_no_cache true;
           #proxy_set_header X-Real-IP $remote_addr;
           #proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;


        }
        location ~ ^/formio.* {
           rewrite ^/formio(.*) $1 break;
           proxy_pass      http://127.0.0.1:3005;

        }

        location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to displaying a 404.
            #try_files $uri $uri/ /index.html /index.js;

            try_files $uri $uri/ /index.html ;
           root /opt/pontus/pontus-gui/current/lib/;
        }

    }
}


EOF

