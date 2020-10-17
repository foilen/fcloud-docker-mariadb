#!/bin/bash

rm -f /var/lib/mysql/CAN_USE

set -e

# Initializing
if [ ! -f /var/lib/mysql/READY ]; then
  echo MariaDB - Initializing the DB
  /usr/bin/mysql_install_db --auth-root-authentication-method=normal
  
fi

# Start
echo MariaDB - Starting
/usr/sbin/mysqld &
APP_PID=$!
echo MariaDB - Started

# Change root password if needed
LAST_PASS=$(cat /volumes/config/lastPass || echo)
NEW_PASS=$(cat /newPass)
if [ "$LAST_PASS" != "$NEW_PASS" ]; then
  sleep 5
  echo MariaDB - Update the password
  
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
  echo $NEW_PASS > /volumes/config/lastPass
  cp /newPass.cnf /volumes/config/lastPass.cnf
fi

# Run the upgrade if the version changed
LAST_VERSION=$(cat /volumes/config/lastversion || echo)
NEW_VERSION=$(mysql --version)
if [ "$LAST_VERSION" != "$NEW_VERSION" ]; then
  sleep 5
  echo MariaDB - Upgrade the database
  mysql_upgrade --defaults-file=/volumes/config/lastPass.cnf -u root -h 127.0.0.1
  
  echo "$NEW_VERSION" > /volumes/config/lastversion
fi

echo MariaDB - Ready to use

touch /var/lib/mysql/READY
touch /var/lib/mysql/CAN_USE

function softQuit {
  echo MariaDB - Got a SIGTERM signal. Sending mysqladmin shutdown command
  mysqladmin --defaults-file=/volumes/config/lastPass.cnf -u root -h 127.0.0.1 shutdown
}

trap softQuit SIGTERM

wait $APP_PID
