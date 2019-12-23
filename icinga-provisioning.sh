#! /bin/bash

if [ ! \( "$(whoami)" = "root" \) ]
then {
echo "This should be run as root."
exit 1
}
fi

# Using set -e for debugging. It might crash scripts using subshells.
set -e
yum update -y || true

# Install the EPEL repo:
yum install -y epel-release

# Install SCL repository (for newer PHP version)
yum install -y centos-release-scl

# Installing Apache
yum install -y httpd 

# Start and Enable the Web Server
systemctl enable --now httpd

# Install MariaDB
yum install -y mariadb-server && systemctl enable --now mariadb

# Securing the mysql server
#|| true is a mortal sin.
mysql -v -uroot < /vagrant/mysql_secur\
e_installation.sql || true

# Create Databases for Applications and Users for Databases
mysql -v -u root -proot123 <<EOF
create database if not exists icinga;
create database if not exists icingaweb;
EOF

DBNAME=icinga
DBUSER=icinga
DBUSER_PASSWD=icinga123
mysql -v -u root -proot123 -D $DBNAME -e "grant all on ${DBNAME}.* to ${DBUSER}@localhost identified by '${DBUSER_PASSWD}' ; "

DBNAME=icingaweb
DBUSER=icingaweb
DBUSER_PASSWD=icingaweb123
mysql -v -u root -proot123 -D $DBNAME -e "grant all on ${DBNAME}.* to ${DBUSER}@localhost identified by '${DBUSER_PASSWD}' ; flush privileges;"

# Configure Icinga Repository
yum install -y https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm || true

# Install Icinga
yum install -y icinga2 icingaweb2 icingacli icinga2-ido-mysql


# Try to make Icinga install the latest versions of itself
yum update -y

# Start and enable the FPM service
systemctl enable --now rh-php71-php-fpm.service

yum install rh-php71-php-mysqlnd

# Configure PHP
mystring="date.timezone = \"Europe/Oslo\""
php_path1="/etc/php.ini"
php_path2="/etc/opt/rh/rh-php71/php.ini"
for php_path in php_path1 php_path2;
do
if [ "$(grep -c "$mystring"  "$php_path")" -lt 1 ]
then {
cp -v "$php_path" ${php_path}.bak-$(($(date +%s)/60))
echo "date.timezone = \"Europe/Oslo\"" | tee -a "$php_path"
}
else echo "Timezone already set."
fi
# Restart php fpm
systemctl restart rh-php71-php-fpm.service

#Configure the Database
if [ "$(mysqlshow -u root -proot123 icinga | wc -l)" -eq 5 ]
then
mysql -v -u root -proot123 icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
elif [ "$(mysqlshow -u root -proot123 icinga | wc -l)" -eq 66 ]
then {
echo "Database already initialized"
sleep 1;}
else {
echo "Database length neither 5 or 66, something's wrong?"
exit 1
}
fi

# Configure postfix
mystring="smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
if [ "$(grep -c "$mystring" /etc/postfix/main.cf)" -lt 1 ]
then {
yum install cyrus-sasl-plain -y #SASL auth lib
cp -v /etc/postfix/main.cf /etc/postfix/main.cf.bak-$(($(date +%s)/60))
tee -a /etc/postfix/main.cf <<EOF
"smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_tls_security_level = encrypt
header_size_limit = 4096000
relayhost = [smtp.sendgrid.net]:587"
EOF
cp /vagrant/sasl_passwd /etc/postfix/sasl_passwd
chmod -v 600 /etc/postfix/sasl_passwd
postmap -v /etc/postfix/sasl_passwd
systemctl restart postfix.service
rm -vf /etc/postfix/sasl_passwd
}
else echo "Postfix already configured."
fi

# Tell icinga how to connect to the database
mystring="password = \"icinga123\""
my_url="/etc/icinga2/features-available/ido-mysql.conf"
if [ "$(grep -c "$mystring" "$my_url" )" -lt 1 ]
then {
    sed -E -i.bak-$(($(date +%s)/60)) -e '/\/\/(us|pa|ho|da)/s/\/\///' \
-e '/password/s/inga/inga123/' $my_url
   
}
else echo "DB password in icinga already set."
fi
# Enable ido-mysql.conf
icinga2 feature enable ido-mysql


# Allow commands to be received by the Web Front End
icinga2 feature enable command
# see what features are running:
icinga2 feature list

# Install Monitoring Plugins
yum install -y nagios-plugins-all

# Prepare the server for clients (run the WIZARD for the right icinga ver.)
### (don't run if already run before)
icinga_ver="$(icinga2 --version | head -1 | awk '{print $10}')"
icinga_ver="${icinga_ver/#v/}"
icinga_ver="${icinga_ver%.*}"
echo "Found out that icinga version is: ${icinga_ver}."
if [ "$icinga_ver" = "2.5" ]
   then {
#case when we have icinga 2.5 (from jason's tutorial)
   if [ ! \( -e '/etc/icinga2/conf.d/api-users.conf' \) ]
then {
icinga2 node wizard <<EOF
n



EOF
##That is we answer n, and 3 times enter to accept defaults
} else echo "Icinga Config-Wizard already run."
fi
}
elif [ $icinga_ver = "2.11" ] ; then 
{
#case when we have icinga 2.11 (had to find it out myself)
   if [ ! \( -e '/etc/icinga2/conf.d/api-users.conf' \) ]
then {
icinga2 node wizard <<EOF
n






EOF
##That is we answer n, and 6 times enter to accept defaults
} else echo "Icinga Config-Wizard already run."
fi
}
else echo "Unknown Icinga version: ${icinga_ver}."
     exit 1
fi

# Start Icinga
systemctl enable --now icinga2.service

# Configure the Web Front-End
icingacli setup token create
systemctl restart httpd

# Use the browser to configure the app, then press space
read -n1 -r -p "Open http://10.23.45.30/icingaweb2/setup. Press space to continue..." key
echo "$key"
