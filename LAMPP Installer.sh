# Created By PT.Kilau Energi Infotama
# Author : Abdul Muttaqin
#!/bin/bash

echo "Please enter root user MySQL password! :"
read mysql_password

echo "Please enter the domain you want to set up (example.com)! :"
read domain

echo "Please enter your email!"
read email

echo "Do you wish to set up a reverse proxy (yes/no)?"
read reverse_proxy

# Update system 
sudo apt-get update

# Install Apache
sudo apt-get install apache2 -y

# Install MySQL Server in a Non-Interactive mode. 
echo "mysql-server mysql-server/root_password password $mysql_password" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysql_password" | sudo debconf-set-selections
sudo apt-get install mysql-server -y

# Install PHP
sudo apt-get install php libapache2-mod-php php-mysql -y

# Install phpMyAdmin and set up database
sudo apt-get install phpmyadmin -y

# Enable phpMyAdmin Apache configuration
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin
sudo systemctl restart apache2

# Setup Virtual Host
sudo bash -c 'cat << EOF > /etc/apache2/sites-available/$domain.conf
<VirtualHost *:80>
    ServerAdmin admin@$domain
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot /var/www/$domain
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF'

# Enable the site
sudo a2ensite $domain.conf
sudo systemctl reload apache2

# Install Let's Encrypt client
sudo apt-get install certbot python3-certbot-apache -y
# Obtain and Install SSL certificate
sudo certbot --apache -n -d $domain --email $email --agree-tos --redirect


# Add Reverse Proxy if requested
if [ "$reverse_proxy" == "yes" ]; then
    sudo a2enmod proxy
    sudo a2enmod proxy_http
    sudo systemctl restart apache2

    echo "Please enter the IP of the server you want to set as the backend for the reverse proxy!"
    read backend_ip

    sudo bash -c 'cat << EOF >> /etc/apache2/sites-available/$domain.conf
    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>
    ProxyPass / http://$backend_ip/
    ProxyPassReverse / http://$backend_ip/
    EOF'

    sudo systemctl reload apache2
fi

echo "Setup is complete!"
