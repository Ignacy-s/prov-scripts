#! /bin/bash
# Moved Vagrant files which messed up osticket project.
# Extracting history to make a provisioning script.
set -e
sudo yum update -y 

# Installing Apache
sudo yum install -y httpd php php-mysql 
sudo yum install -y php-gd php-xml php-mbstring

sudo systemctl enable --now httpd

# DB
DBNAME=kanboard
DBUSER=kanboard
DBUSER_PASSWD=kanboard123
sudo yum install -y mariadb-server && sudo systemctl enable --now mariadb
echo -e '\n\nroot123\nroot123\n\n\n\n' | sudo mysql_secure_installation 
sudo mysqladmin -u root -proot123 create $DBNAME
sudo mysql -u root -proot123 -D $DBNAME -e "grant all on ${DBNAME}.* to ${DBUSER}@localhost identified by '${DBUSER_PASSWD}' ; flush privileges;"

# Files
curl -LO http://mirror.linuxtrainingacademy.com/kanboard/kanboard-v1.0.34.zip
unzip kanboard-v1.0.34.zip
sudo mv kanboard/* /var/www/html
ls -l /var/www/html
#Tell the app how to connect to database
sudo tee -a /var/www/html/config.php <<EOF
<?php
define('DB_DRIVER', 'mysql');
define('DB_USERNAME', 'kanboard');
define('DB_PASSWORD', 'kanboard123');
define('DB_HOSTNAME', 'localhost');
define('DB_NAME', 'kanboard');
EOF

# postfix
sudo yum install cyrus-sasl-plain -y #SASL auth lib
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
sudo tee -a /etc/postfix/main.cf <<EOF
"smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_tls_security_level = encrypt
header_size_limit = 4096000
relayhost = [smtp.sendgrid.net]:587"
EOF
sudo cp /vagrant/sasl_passwd /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl restart postfix.service
sudo rm -f /etc/postfix/sasl_passwd
