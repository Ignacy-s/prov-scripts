#! /bin/bash
# Moved Vagrant files which messed up osticket project.
# Extracting history to make a provisioning script.
yum update -y 

# Installing Apache
yum install -y httpd php php-mysql php-gd php-xml php-mbstring epel-release php-imap
systemctl enable --now httpd

# DB
yum install -y mariadb-server && systemctl enable --now mariadb
mysql -sfu root < "mysql_secure_installation.sql"
mysqladmin -u root -p'root123' create osticket
mysql -u root -p'root123' -D osticket -e "grant all on osticket.* to osticket@localhost identified by 'osticket123'; flush privileges;"

# Files
mkdir osticket
cd osticket
curl -L https://mirror.linuxtrainingacademy.com/osticket/osTicket-v1.9.15.zip > osTicket-v1.9.15.zip
unzip osTicket-v1.9.15.zip
mv upload/* /var/www/html
cp /var/www/html/include/ost-sampleconfig.php /var/www/html/include/ost-config.php
chown apache /var/www/html/include/ost-config.php


# here you use the browser to configurate the app
read -n1 -r -p "Point your browser at installation ip, and configure it. Press space to continue..." key

chown root /var/www/html/include/ost-config.php
rm -rf /var/www/html/setup/

# postfix
yum install cyrus-sasl-plain -y #SASL auth lib
cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
cat "smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_tls_security_level = encrypt
header_size_limit = 4096000
relayhost = [smtp.sendgrid.net]:587" | tee -a /etc/postfix/main.cf
cp /vagrant/sasl_passwd /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
systemctl restart postfix.service

exit 0
