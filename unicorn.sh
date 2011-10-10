sudo -E su

gem list unicorn | grep unicorn ||
  gem install unicorn --no-rdoc --no-ri

cat <<EOS > /etc/logrotate.d/unicorn
/var/log/unicorn/*.log {
  daily
  rotate 14
  compress
  missingok
  sharedscripts
  postrotate
    "/etc/init.d/unicorn reload > /dev/null"
  endscript
}
EOS
chmod 0644 /etc/logrotate.d/unicorn

mkdir -p /var/log/unicorn
chown root:root /var/log/unicorn
chmod 0755 /var/log/unicorn

mkdir -p /var/unicorn
chown admin:www-data /var/unicorn
chmod 0755 /var/unicorn

cat <<EOS > /etc/init.d/unicorn
#!/bin/sh
set -u
set -e

APP_ROOT=/srv/app/current/
PID=/var/run/unicorn.pid
ENV=\${RACK_ENV-"production"}
CMD="/usr/bin/unicorn -c config/unicorn.rb -D -E \$ENV"

old_pid="\$PID.oldbin"

cd \$APP_ROOT || exit 1

sig () {
  test -s "\$PID" && kill -\$1 \`cat \$PID\`
}

oldsig () {
  test -s \$old_pid && kill -\$1 \`cat \$old_pid\`
}

case \$1 in
start)
  sig 0 && echo >&2 "Already running" && exit 0
  \$CMD
  ;;
stop)
  sig QUIT && exit 0
  echo >&2 "Not running"
  ;;
force-stop)
  sig TERM && exit 0
  echo >&2 "Not running"
  ;;
restart|reload)
  sig HUP && echo reloaded OK && exit 0
  echo >&2 "Couldn't reload, starting '\$CMD' instead"
  \$CMD
  ;;
upgrade)
  sig USR2 && exit 0
  echo >&2 "Couldn't upgrade, starting '\$CMD' instead"
  \$CMD
  ;;
rotate)
        sig USR1 && echo rotated logs OK && exit 0
        echo >&2 "Couldn't rotate logs" && exit 1
        ;;
*)
  echo >&2 "Usage: \$0 <start|stop|restart|upgrade|rotate|force-stop>"
  exit 1
  ;;
esac
EOS
chown root:root /etc/init.d/unicorn
chmod 0755 /etc/init.d/unicorn

mkdir -p $SHARED_ROOT/config

cat <<EOS > $SHARED_ROOT/config/unicorn.rb
rack_env = ENV["RACK_ENV"] || "production"
worker_processes 3
preload_app true
timeout 30
listen "/var/unicorn/unicorn.sock", :backlog => 2048
stderr_path "/var/log/unicorn/unicorn.stderr.log"
stdout_path "/var/log/unicorn/unicorn.stdout.log"
pid "/var/run/unicorn.pid"

before_fork do |server, worker|
  old_pid = "/var/run/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  uid, gid = Process.euid, Process.egid
  user, group = "admin", "www-data"
  target_uid = Etc.getpwnam(user).uid
  target_gid = Etc.getgrnam(group).gid
  worker.tmp.chown(target_uid, target_gid)
  if uid != target_uid || gid != target_gid
    Process.initgroups(user, target_gid)
    Process::GID.change_privilege(target_gid)
    Process::UID.change_privilege(target_uid)
  end
end
EOS
chown root:root $SHARED_ROOT/config/unicorn.rb
chmod 0644 $SHARED_ROOT/config/unicorn.rb
