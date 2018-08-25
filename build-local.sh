#!/bin/bash

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
VERSION=1.15.2
DISTDIR="/root/work/pontus-git/pontus-dist/opt/pontus/pontus-nginx";
TARFILE=$DIR/pontus-nginx-${VERSION}.tar.gz

CURDIR=`pwd`
cd $DIR

echo DIR is $DIR
echo TARFILE is $TARFILE

if [[ ! -d $DISTDIR ]]; then
  mkdir -p $DISTDIR;
fi

if [[ ! -f $TARFILE ]]; then

yum -y install attr bind-utils docbook-style-xsl gcc gdb krb5-workstation        libsemanage-python libxslt perl perl-ExtUtils-MakeMaker        perl-Parse-Yapp perl-Test-Base pkgconfig policycoreutils-python        python-crypto gnutls-devel libattr-devel keyutils-libs-devel        libacl-devel libaio-devel libblkid-devel libxml2-devel openldap-devel        pam-devel popt-devel python-devel readline-devel zlib-devel systemd-devel openssl-devel

./auto/configure  --prefix=/opt/pontus/pontus-nginx/nginx-${VERSION} --with-http_ssl_module --with-threads  --with-poll_module --with-http_gzip_static_module --with-http_secure_link_module  --with-http_sub_module --with-http_v2_module --user=pontus
make -j 4
make install


tar cpzvf ${TARFILE} /opt/pontus/pontus-nginx

fi

if [[ ! -d $DISTDIR ]]; then
  mkdir -p $DISTDIR
fi

cd $DISTDIR
rm -rf *
cd $DISTDIR/../../../
tar xvfz $TARFILE
cd $DISTDIR
ln -s nginx-$VERSION current
cd current

cat <<"EOF" >> config-nginx.sh
#!/bin/bash

if [[ -f /opt/pontus/pontus-nginx/current/conf/nginx.conf ]]; then
  mv /opt/pontus/pontus-nginx/current/conf/nginx.conf  /opt/pontus/pontus-nginx/current/conf/nginx.conf.orig
fi


> /opt/pontus/pontus-nginx/current/conf/proxy.conf
cat << 'EOF2' >> /opt/pontus/pontus-nginx/current/conf/proxy.conf
proxy_redirect          off;
proxy_set_header        Host            $host;
proxy_set_header        X-Real-IP       $remote_addr;
proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
client_max_body_size    10m;
client_body_buffer_size 128k;
proxy_connect_timeout   90;
proxy_send_timeout      90;
proxy_read_timeout      90;
proxy_buffers           32 4k;

EOF2


> /opt/pontus/pontus-nginx/current/conf/nginx.conf

cat << 'EOF2' >> /opt/pontus/pontus-nginx/current/conf/nginx.conf
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

    #gzip  on;

    include /opt/pontus/pontus-nginx/conf/conf.d/*.conf;

    upstream pvgdprgui {
      server 127.0.0.1:3000 weight=3;
    }

    server {
        root /;
        ssl_protocols               TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers                 ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256;
        ssl_prefer_server_ciphers   on;
        ssl_ecdh_curve              secp384r1;

        listen       8443 ssl;
        server_name  pontus-sandbox.pontusvision.com;

        ssl_certificate      /etc/pki/private/localhost.crt;
        ssl_certificate_key  /etc/pki/private/localhost.pem;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        #ssl_ciphers  HIGH:!aNULL:!MD5;

        location ~ ^/auth.* {
           rewrite ^(/auth/.*) $1 break;
           proxy_pass      https://localhost:5005;
           proxy_set_header Host              $host;
           proxy_set_header X-Real-IP         $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto https;

           #proxy_set_header    Upgrade $http_upgrade;
           #proxy_set_header    Connection "upgrade";
           #proxy_set_header    Host $host;
           proxy_set_header    X-NginX-Proxy true;

           proxy_http_version  1.1;
           proxy_redirect      off;


        }

        location ~ ^/nifi.* {
           rewrite ^(/nifi.*) $1 break;
           proxy_pass      http://127.0.0.1:5007;
        }


        location ~ ^/gateway/sandbox/pvgdpr_server.* {
           rewrite ^/gateway/sandbox/pvgdpr_server/(.*)$ /$1 break;
           proxy_pass      http://127.0.0.1:3001;
        }

        location ~ ^/gateway/sandbox/pvgdpr_graph.*  {
           rewrite ^/gateway/sandbox/pvgdpr_graph/(.*)$ /$1 break;
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

        location ~ ^/pvgdpr.* {
           rewrite_log on;
           rewrite ^/pvgdpr/pvgdpr(/.*) $1 break;
           rewrite ^/pvgdpr/pvgdpr_gui(/.*) $1 break;
           rewrite ^/pvgdpr/../static/(.*) /static/$1 break;
           rewrite ^/pvgdpr/full/(.*) /$1 break;
           rewrite ^/pvgdpr/full(.*)  /$1 break;
           rewrite ^/pvgdpr/expert/(.*) /$1 break;
           rewrite ^/pvgdpr/expert(.*) /$1 break;
           rewrite ^/pvgdpr/re/(.*) /$1 break;
           rewrite ^/pvgdpr/re(.*) /$1 break;
           rewrite ^/pvgdpr(/.*) $1 break;

           proxy_pass      http://127.0.0.1:3000;

           #sub_filter_types text/html text/css text/xml;
           #sub_filter /pvgdpr/pvgdpr /pvgdpr;

           proxy_set_header Host $host;
           proxy_cache_bypass true;
           proxy_no_cache true;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;


        }

        location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to displaying a 404.
            #try_files $uri $uri/ /index.html /index.js;
            try_files $uri $uri/ /index.html ;
        }

    }
}

EOF2

> /etc/systemd/system/pontus-nginx.service
cat << 'EOF2' >> /etc/systemd/system/pontus-nginx.service
[Unit]
Description=Pontus Nginx
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/opt/pontus/pontus-nginx/current/sbin/nginx -c /opt/pontus/pontus-nginx/current/conf/nginx.conf
PIDFile=/opt/pontus/pontus-nginx/current/nginx.pid
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target

EOF2

ln -s /opt/pontus/pontus-nginx/current/conf /etc/nginx
chown -R pontus: /opt/pontus/pontus-nginx
systemctl enable pontus-nginx
systemctl daemon-reload
systemctl start pontus-nginx

EOF

chmod 755 config-nginx.sh
cd $CURDIR

echo DISTDIR is $DISTDIR
