sudo -E su

version=1.9.2-p290
req_gem_version=1.8.8

alt=`echo $version | sed -e "s/-.*//g" -e "s/\\.//g"`

if [ ! -x "/usr/bin/ruby$version" ]; then
  apt-get update
  apt-get install -y build-essential autoconf libc6-dev libssl-dev libssl-dev libreadline5-dev zlib1g-dev libyaml-0-2
  
  cd /tmp
  wget ftp://ftp.ruby-lang.org//pub/ruby/1.9/ruby-$version.tar.gz
  tar xvf ruby-$version.tar.gz
  cd ruby-$version
  autoconf
  ./configure --with-ruby-version=$version --prefix=/usr --program-suffix=$version \
    --with-openssl-dir=/usr --with-readline-dir=/usr --with-zlib-dir=/usr
  make
  make install-nodoc
  update-alternatives \
    --install /usr/bin/ruby ruby /usr/bin/ruby$version $alt \
    --slave /usr/bin/erb erb /usr/bin/erb$version \
    --slave /usr/bin/irb irb /usr/bin/irb$version \
    --slave /usr/bin/rdoc rdoc /usr/bin/rdoc$version \
    --slave /usr/bin/ri ri /usr/bin/ri$version
    --slave /usr/bin/rake rake /usr/bin/rake$version
  update-alternatives --install /usr/bin/gem gem /usr/bin/gem$version $alt
  update-alternatives --config ruby
  update-alternatives --config gem
fi

gem_version=$(gem$version --version | tr -d \\r\\n)
test $(echo $gem_version | sed -e "s/-.*//g" -e "s/\\.//g") -lt $(echo $req_gem_version | sed -e "s/-.*//g" -e "s/\\.//g") ||
  gem$version update --system
