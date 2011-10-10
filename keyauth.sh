echo "$SSH_KEY"

mkdir -p ~/.ssh

grep "$SSH_KEY" ~/.ssh/authorized_keys ||
  echo "$SSH_KEY" >> ~/.ssh/authorized_keys

chmod 0600 ~/.ssh/authorized_keys
