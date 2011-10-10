export DEPLOY_ROOT="/srv/app"

export SHARED_ROOT="$DEPLOY_ROOT/shared"
export RELEASE_ROOT="$DEPLOY_ROOT/releases"
export CURRENT_ROOT="$DEPLOY_ROOT/current"

export RELEASE="$RELEASE_ROOT/$(date +%s)"

sudo sh -c "echo 'export RACK_ENV=\"$DEPLOY_ENV\"' > /etc/profile.d/app.sh"
export RACK_ENV="$DEPLOY_ENV"
