sudo -E su

id www-data ||
  addgroup www-data
  
id admin ||
  useradd --gid=www-data --home-dir=/home/admin --create-home --shell=/bin/bash admin

cat /etc/sudoers | grep "admin ALL=(ALL) NOPASSWD" ||
  echo "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
