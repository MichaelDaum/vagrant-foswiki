hostname=$1

echo "configuring nginx for $hostname"
foswiki_conf="/etc/nginx/sites-available/foswiki.vhost"
fcgi_cache_conf="/etc/nginx/conf.d/fcgi_cache.conf"

rm -f /etc/nginx/conf.d/default.conf

if test -f $foswiki_conf; then
  echo "... already configured, skipping"
  exit
fi

mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

cat <<"EOF" > $foswiki_conf
server {
  listen 80;
  return 301 https://$host$request_uri;
}
EOF

cat <<EOF >> $foswiki_conf
server {
  listen 443 ssl http2;
  ssl_certificate /etc/nginx/$hostname.crt;
  ssl_certificate_key /etc/nginx/$hostname.key;
EOF

cat <<"EOF" >> $foswiki_conf
  include /etc/nginx/bots.d/ddos.conf; 
  include /etc/nginx/bots.d/blockbots.conf;

  server_name  ~^(www\.)?(?<domain>.+)$;
  set $foswiki_root /var/www/foswiki;

  root $foswiki_root;
  index index.html index.htm;

  set $fastcgi_skipcache 0;
  set $fastcgi_skipreason "";

  if ($request_method = POST) {
     set $fastcgi_skipcache 1;
     set $fastcgi_skipreason "${fastcgi_skipreason} post";
  }
  if ($http_x_nginx_skip_cache) {
     set $fastcgi_skipcache 1;
     set $fastcgi_skipreason "${fastcgi_skipreason} header";
  }

  if ($http_cookie ~* "FOSWIKISID") {
     set $fastcgi_skipcache 1;
     set $fastcgi_skipreason "${fastcgi_skipreason} cookie";
  }

  location = /favicon.ico {
    log_not_found off;
    access_log off;
  }

  location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
  }

  location = / {
    try_files $uri @foswiki;
  }

  location /bin {
    try_files /html/$uri @foswiki;
  }

  location ~ ^/(?:bin/)?([A-Z_].*)$ {
    rewrite ^/(.*)$ /bin/view/$1 last;
  }

  location ~ ^/pub/(System|Applications)|(.*/igp_) {
    access_log off;
    expires 8h;
    gzip_static on;
  }

  location /pub {
    rewrite ^/pub/(.*)$ /bin/viewfile/$1;
    #rewrite ^/pub/(.*)$ /bin/xsendfile/$1;

    access_log on;

    valid_referers server_names $server_name;
    if ($invalid_referer)  {
       return 403;
    }

    expires 8h;
    gzip_static on;
  }

  location /files {
    internal;
    alias $foswiki_root/pub;
    expires 8h;
  }

  location /files/pdf {
    internal;
    alias $foswiki_root/pub;
    expires 8h;
    max_ranges 0;
  }

  location @foswiki {
    gzip off;

    fastcgi_pass   127.0.0.1:9001;
    fastcgi_read_timeout 120s;

    fastcgi_split_path_info ^/bin/(.+?)(/.*)$;
    fastcgi_param  SCRIPT_FILENAME  $foswiki_root/bin/foswiki.fcgi;
    fastcgi_param  SCRIPT_NAME $fastcgi_script_name;
    fastcgi_param  PATH_INFO $fastcgi_path_info;
    fastcgi_param  HTTP2 $http2;

#   add_header X-Nginx-Page-Cache $upstream_cache_status;
#   add_header X-Nginx-Page-Skip-Reason $fastcgi_skipreason;
#
#   fastcgi_cache FASTCGICACHE;
#   fastcgi_cache_bypass $fastcgi_skipcache;
#   fastcgi_no_cache $fastcgi_skipcache;
#   fastcgi_cache_valid 8h;
#   fastcgi_cache_valid 404 1m;

    include fastcgi_params;
  }

  location ~ (^/lib|^/data|^/locale|^/templates|^/tools|^/work) {
     deny all;
  }
}
EOF

cat <<"EOF" > $fcgi_cache_conf
map $http_accept_language $lang {
  default en;
  ~de de;
}

fastcgi_cache_path /var/run/nginx-fastcgi-cache levels=1:2 keys_zone=FASTCGICACHE:100m inactive=8h;
fastcgi_cache_key "$scheme$request_method$host$request_uri$lang";
fastcgi_ignore_headers Set-Cookie Vary Cache-Control;

fastcgi_cache_use_stale error timeout updating invalid_header http_500 http_503;
fastcgi_cache_revalidate on;
fastcgi_cache_lock on;
fastcgi_cache_background_update on;
fastcgi_cache_min_uses 1;
EOF

ln -s $foswiki_conf /etc/nginx/sites-enabled/

grep -q "sites-enabled" /etc/nginx/nginx.conf || sed -i "/include \/etc\/nginx.conf.d\/\*\.conf;/a\\\tinclude \/etc\/nginx\/sites-enabled\/*;" /etc/nginx/nginx.conf

echo "installing bad-bot-blocker"
mkdir -p /usr/local/sbin
wget -q https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker
chmod +x /usr/local/sbin/install-ngxblocker
install-ngxblocker -q -x
setup-ngxblocker -z

chown -R nginx:nginx /etc/nginx/
rc-update add nginx default
service nginx restart >/dev/null
