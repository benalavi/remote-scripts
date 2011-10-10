sudo -E su

lib="/var/lib/nginx"

if [ ! -x "/usr/sbin/nginx" ];then
  apt-get install libssl-dev -y
  
  cd /tmp
  apt-get build-dep nginx -y
  wget http://sysoev.ru/nginx/nginx-0.8.54.tar.gz
  tar zxf nginx-0.8.54.tar.gz
  cd nginx-0.8.54
  ./configure \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --http-log-path=/var/log/nginx/access.log \
    --with-http_dav_module \
    --http-client-body-temp-path=$lib/body \
    --with-http_ssl_module \
    --http-proxy-temp-path=$lib/proxy \
    --with-http_stub_status_module \
    --http-fastcgi-temp-path=$lib/fastcgi \
    --with-debug \
    --with-http_flv_module 
  make
  make install
  ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
fi

dirs=( "$lib/body" "$lib/proxy" "$lib/fastcgi" )
for dir in "${dirs[@]}"; do
  mkdir -p $dir
  chown www-data:www-data $dir
  chmod 700 $dir
done

mkdir -p /var/log/nginx
chown www-data:www-data /var/log/nginx
chmod 0755 /var/log/nginx

cat <<EOS > /etc/init.d/nginx
#! /bin/sh

### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    \$all
# Required-Stop:     \$all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server
# Description:       starts nginx using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/nginx
NAME=nginx
DESC=nginx
PIDFILE=/var/run/nginx.pid

test -x \$DAEMON || exit 0

# Include nginx defaults if available
if [ -f /etc/default/nginx ] ; then
  . /etc/default/nginx
fi

set -e

. /lib/lsb/init-functions

case "\$1" in
  start)
    echo -n "Starting \$DESC: "
    start-stop-daemon --start --quiet --pidfile \$PIDFILE --exec \$DAEMON -- \$DAEMON_OPTS || true
    echo "\$NAME."
    ;;
  stop)
    echo -n "Stopping \$DESC: "
    start-stop-daemon --stop --quiet --pidfile \$PIDFILE --exec \$DAEMON || true
    echo "\$NAME."
    ;;
  restart|force-reload)
    echo -n "Restarting \$DESC: "
    start-stop-daemon --stop --quiet --pidfile \$PIDFILE --exec \$DAEMON || true
    sleep 1
    start-stop-daemon --start --quiet --pidfile \$PIDFILE --exec \$DAEMON -- \$DAEMON_OPTS || true
    echo "\$NAME."
    ;;
  reload)
      echo -n "Reloading \$DESC configuration: "
      start-stop-daemon --stop --signal HUP --quiet --pidfile \$PIDFILE --exec \$DAEMON || true
      echo "\$NAME."
      ;;
  status)
  status_of_proc -p \$PIDFILE "\$DAEMON" nginx && exit 0 || exit \$?
      ;;
  *)
    N=/etc/init.d/\$NAME
    echo "Usage: \$N {start|stop|restart|reload|force-reload|status}" >&2
    exit 1
    ;;
esac

exit 0
EOS
chown root:root /etc/init.d/nginx
chmod 0755 /etc/init.d/nginx

test -f "/etc/rc5.d/nginx" ||
  /usr/sbin/update-rc.d -f nginx defaults

cat <<EOS > /etc/nginx/nginx.conf
user www-data;
worker_processes 1;

error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  access_log /var/log/nginx/access.log;

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;

  keepalive_timeout 65;

  gzip on;
  gzip_http_version 1.0;
  gzip_comp_level 2;
  gzip_proxied any;
  gzip_types text/plain text/html text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript;

  server_names_hash_bucket_size 64;

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/app.conf;
}
EOS
chown root:root /etc/nginx/nginx.conf
chmod 0644 /etc/nginx/nginx.conf

cat <<EOS > /etc/nginx/app.conf
upstream app {
  server unix:/var/unicorn/unicorn.sock;
}

server {
  listen 80 default_server;
  
  access_log /var/log/nginx/app.log;
  error_log /var/log/nginx/app.error.log;
  
  root /srv/app/current/public/;
  index index.html;
  
  location / {
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$http_host;
    proxy_redirect off;

    if (-f \$request_filename/index.html) {
      rewrite (.*) \$1/index.html break;
    }
    
    if (-f \$request_filename.html) {
      rewrite (.*) \$1.html break;
    }

    if (!-f \$request_filename) {
      proxy_pass http://app;
      break;
    }
  }
}
EOS
chown root:root /etc/nginx/app.conf
chmod 0644 /etc/nginx/app.conf

cat <<EOS > /etc/logrotate.d/nginx
/var/log/nginx/*.log {
  daily
  rotate 14
  compress
  missingok
  sharedscripts
  postrotate
    "/etc/init.d/nginx reload > /dev/null"
  endscript
}
EOS
chown root:root /etc/logrotate.d/nginx
chmod 0644 /etc/logrotate.d/nginx

/etc/init.d/nginx start
/etc/init.d/nginx reload
