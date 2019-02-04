#!/bin/bash
# Setup WordPress for contributing.

if [[ -z "$LANDO_MOUNT" ]]; then
    echo "Error: Must be run the appserver.";
    exit 1
fi

set -e
set -x

# TODO: Get rid of this?
if [[ ! -e "$LANDO_MOUNT/wp-cli.yml" ]]; then
    cp "$LANDO_MOUNT/config/wp-cli.yml" "$LANDO_MOUNT/wp-cli.yml"
fi

if [[ ! -e "$LANDO_MOUNT/public/core-dev" ]]; then
    git clone https://github.com/WordPress/wordpress-develop.git "$LANDO_MOUNT/public/core-dev"
fi

if [[ ! -e "$LANDO_MOUNT/public/core-dev/.svn" ]]; then
    cd "$LANDO_MOUNT"
    svn co --ignore-externals https://develop.svn.wordpress.org/trunk/ tmp-svn
    mv tmp-svn/.svn public/core-dev/.svn
    rm -rf tmp-svn
fi

if [[ ! -e "$LANDO_MOUNT/public/core-dev/wp-config.php" ]]; then
    cp "$LANDO_MOUNT/config/wp-config.php" "$LANDO_MOUNT/public/core-dev/wp-config.php"
fi

if [[ ! -e "$LANDO_MOUNT/public/core-dev/wp-tests-config.php" ]]; then
    cp "$LANDO_MOUNT/config/wp-tests-config.php" "$LANDO_MOUNT/public/core-dev/wp-tests-config.php"
fi

if [[ ! -e "$LANDO_MOUNT/public/core-dev/vendor" ]]; then
    cd $LANDO_MOUNT/public/core-dev
    composer install
fi

if [[ ! -e "$LANDO_MOUNT/public/core-dev/node_modules" ]]; then
    cd "$LANDO_MOUNT/public/core-dev"
    npm install
fi

if [[ ! -e "$LANDO_MOUNT/public/core-dev/build" ]]; then
    cd "$LANDO_MOUNT/public/core-dev"
    npx grunt
fi

cd "$LANDO_MOUNT/public/core-dev"
if ! git config -l --local | grep -q 'alias.svn-up'; then
    git config alias.svn-up '! ../../bin/svn-git-up $1';
fi

if ! wp core is-installed; then
  wp core install --url="https://$LANDO_APP_NAME.$LANDO_DOMAIN/" --title="WordPress Develop" --admin_name="admin" --admin_email="admin@local.test" --admin_password="password"
  wp rewrite structure '/%year%/%monthnum%/%day%/%postname%/'
fi