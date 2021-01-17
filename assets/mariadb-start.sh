#!/bin/bash

rm -f /var/lib/mysql/CAN_USE

set -e

export MYSQL_ROOT_PASSWORD=$(cat /newPass)

# Start
echo MariaDB - Starting
/usr/local/bin/docker-entrypoint.sh mysqld &
APP_PID=$!

# Change root password if needed
NEW_PASS=$(cat /newPass)
if [ -f /volumes/config/lastPass ]; then

  LAST_PASS=$(cat /volumes/config/lastPass 2>/dev/null || echo)
  if [ "$LAST_PASS" != "$NEW_PASS" ]; then
    echo MariaDB - Update the password
    sleep 5s
    
    if [ "$LAST_PASS" == "" ]; then
      echo MariaDB- Had no password 
      mysql -u root -h 127.0.0.1 << _EOF
DROP USER IF EXISTS root@localhost;
DROP USER IF EXISTS root@'127.0.0.1';
DROP USER IF EXISTS root@'::1';
GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '$NEW_PASS' WITH GRANT OPTION;
FLUSH PRIVILEGES;
_EOF
    else
      echo MariaDB - Had a password
      mysql --defaults-file=/volumes/config/lastPass.cnf -u root -h 127.0.0.1 << _EOF
DROP USER IF EXISTS root@localhost;
DROP USER IF EXISTS root@'127.0.0.1';
DROP USER IF EXISTS root@'::1';
GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '$NEW_PASS';
FLUSH PRIVILEGES;
_EOF
    fi

  fi

fi
echo $NEW_PASS > /volumes/config/lastPass
cp /newPass.cnf /volumes/config/lastPass.cnf

# Wait that it is ready
echo MariaDB - Wait for it to be accessible
while ! echo SHOW DATABASES | mysql --defaults-file=/newPass.cnf -u root -h 127.0.0.1 > /dev/null 2> /dev/null ; do
  sleep 1s
done

# Run the upgrade if the version changed
LAST_VERSION=$(cat /volumes/config/lastversion 2> /dev/null || echo)
NEW_VERSION=$(mysql --version)
if [ "$LAST_VERSION" != "$NEW_VERSION" ]; then
  echo MariaDB - Upgrade the database
  mysql_upgrade --defaults-file=/newPass.cnf -u root -h 127.0.0.1
  
  echo "$NEW_VERSION" > /volumes/config/lastversion
fi

# Fix missing user
echo MariaDB - Fix missing user
mysql --defaults-file=/newPass.cnf -u root -h 127.0.0.1 << _EOF
CREATE USER IF NOT EXISTS \`mariadb.sys\`@\`localhost\`;
GRANT USAGE ON *.* TO \`mariadb.sys\`@\`localhost\`;
GRANT SELECT, DELETE ON \`mysql\`.\`global_priv\` TO \`mariadb.sys\`@\`localhost\`;
FLUSH PRIVILEGES;
_EOF

# Fully ready
echo MariaDB - Ready to use

touch /var/lib/mysql/READY
touch /var/lib/mysql/CAN_USE

# Wait for a SIGTERM
function softQuit {
  echo MariaDB - Got a SIGTERM signal. Sending mysqladmin shutdown command
  mysqladmin --defaults-file=/newPass.cnf -u root -h 127.0.0.1 shutdown

  while [ -d "/proc/$APP_PID" ]; do
    sleep 1s
  done
  echo MariaDB - Fully stopped
}

trap softQuit SIGTERM

wait $APP_PID
