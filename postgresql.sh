sudo -E su

apt-get install postgresql postgresql-client libpq-dev -y

cat <<EOS > /etc/postgresql/8.4/main/pg_hba.conf
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
local   sameuser    postgres                          ident
local   all         all                               md5
local   sameuser    all                               ident
host    all         all         127.0.0.1/32          md5
host    all         all         ::1/128               md5
EOS
chown postgres:postgres /etc/postgresql/8.4/main/pg_hba.conf
chmod 0600 /etc/postgresql/8.4/main/pg_hba.conf

cat <<EOS > /etc/postgresql/8.4/main/postgresql.conf
data_directory = '/var/lib/postgresql/8.4/main'
hba_file = '/etc/postgresql/8.4/main/pg_hba.conf'
ident_file = '/etc/postgresql/8.4/main/pg_ident.conf'
external_pid_file = '/var/run/postgresql/8.4-main.pid'
listen_addresses = 'localhost'
port = 5432
ssl = false
max_connections = 100
unix_socket_directory = '/var/run/postgresql'
shared_buffers = 24MB
log_line_prefix = '%t '
datestyle = 'iso, mdy'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
EOS
chown postgres:postgres /etc/postgresql/8.4/main/postgresql.conf
chmod 0600 /etc/postgresql/8.4/main/postgresql.conf

sudo /etc/init.d/postgresql-8.4 reload

gem list pg | grep pg ||
  gem install pg --no-rdoc --no-ri

sudo -u postgres psql -c "SELECT u.usename FROM pg_catalog.pg_user u" | grep admin ||
  sudo -u postgres createuser --no-superuser --no-createdb --no-createrole -e admin

# FIXME: read DB password from encrypted env var
sudo -u postgres psql -c "ALTER USER admin ENCRYPTED PASSWORD '123456';"

sudo -u postgres psql -c "SELECT d.datname FROM pg_catalog.pg_database d" | grep app ||
  sudo -u postgres createdb app

mkdir -p $SHARED_ROOT/config

cat <<EOS > $SHARED_ROOT/config/database.yml
$RACK_ENV:
  adapter: postgresql
  database: app
  username: admin
  password: 123456
  uri: postgres://admin:123456@localhost/app
EOS
chown admin:www-data $SHARED_ROOT/config/database.yml
chmod 0644 $SHARED_ROOT/config/database.yml
