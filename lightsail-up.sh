#!/bin/bash

sudo apt update

echo "Installing Apache2.."
sudo apt install apache2 software-properties-common -y

echo "Checking if PHP repository already exists in apt.."
ppa_name="ondrej/php"

# Check if the PPA is already added
if grep -q "^deb .*$ppa_name" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo "PPA $ppa_name is already added. Aborting..."
else
    # Add the PPA
    echo "Adding PPA $ppa_name..."
    sudo add-apt-repository "ppa:$ppa_name" -y
fi

sudo apt update

echo "Installing PHP 8.2 and its modules.."
sudo apt install php8.2 php8.2-{curl,common,mysql,cli,gd,xml,mbstring,zip} php-json -y

echo "Fetching Composer setup via curl.."
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php

echo "Installing Composer.."
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

echo "Finished installing Apache2, PHP 8.2 and Composer.. Done!"
echo "Enabling PHP 8.2 and rewrite modules.."
sudo a2enmod php8.2
sudo a2enmod rewrite

echo "Restarting Apache2.."
sudo systemctl restart apache2

echo "Checking versions of the installed packages.."
apache2 -v
php -v
composer --version

# Creating a project directory under /var/www
# Get the directory name from user input

read -p "Enter the name of the project directory: " dir_name

# Check if the directory already exists
if [ -d "/var/www/$dir_name" ]; then
    echo "Directory already exists. Aborting."
    exit 1
fi

# Create the directory in /var/www/ as root user
sudo mkdir -p "/var/www/$dir_name"

# Change ownership of the directory to your user
# sudo chown -R $USER:$USER "/var/www/$dir_name"

# Change into the new directory
cd "/var/www/$dir_name"

# Get the repository URL from user input
read -p "Enter the URL of the project Git repository: " repo_url

# Clone the repository
git clone "$repo_url" .

echo "Repository cloned into /var/www/$dir_name"

composer install

cp .env.example .env

php artisan key:generate

php artisan storage:link

chmod -R 777 storage/


# Store the IP address of the Lightsail instance in a variable
laravel_dir="/var/www/$dir_name"  # Change this to your Laravel app's directory

read -p "Enter the IP address of your instance:" ip_addr
echo "$ip_addr <- This ip address will be used as a ServerName parameter in the VirtualHost file"

# Create a new virtual host configuration file for Laravel
cat <<EOF | sudo tee "/etc/apache2/sites-available/$dir_name.conf"
<VirtualHost *:80>
    ServerAdmin webmaster@$dir_name.com
    ServerName $ip_addr
    DocumentRoot $laravel_dir/public

    <Directory $laravel_dir/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$domain_name-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain_name-access.log combined
</VirtualHost>
EOF

# Disable the default virtual host
sudo a2dissite 000-default.conf

# Enable the new virtual host
sudo a2ensite "$dir_name.conf"

# Reload Apache to apply the changes
sudo systemctl restart apache2

echo "Apache server restarted.."
echo "Apache2 configuration for your project is complete."
echo "Don't forget to configure .env file manually according to your needs.."
echo "Your Laravel app should now be accessible at http://$ip_addr."
echo " 󰙯 Bye, cya later.."
