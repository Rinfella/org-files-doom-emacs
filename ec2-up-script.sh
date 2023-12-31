#!/bin/bash

# Installing OpenLiteSpeed, Certbot and LSPHP
apt update
echo "Adding LiteSpeed repository to apt.."
wget -O - https://repo.litespeed.sh | sudo bash

echo "Installing LiteSpeed, LSPHP and certbot.."
apt update
apt install openlitespeed certbot lsphp81 lsphp81-{common,curl,mysql}

# Creating www directory adn removing default directory 'Example'
mkdir -p /usr/local/lsws/www

rm -r /usr/local/lsws/Example

project_path="/usr/local/lsws/www"

read -p "Enter the URL of the project repository: " repo_url
echo "Cloning the repository.. $repo_url"
git clone "$repo_url" $project_path
echo "Repository cloned into $project_path"

# Installing Composer
cd "$project_path"
echo "Installing Composer.."
version=$(grep "php\":" composer.json | sed  -e 's/[[:space:]]//g' | sed  -n 's/"php":"^\([0-9]\)\..*/\1/p')

/usr/local/lsws/lsphp81/bin/php8.1 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
/usr/local/lsws/lsphp81/bin/php8.1 composer-setup.php

if [ "$version" == "8" ]; then
    /usr/local/lsws/lsphp81/bin/php8.1 composer.phar install
else
    /usr/local/lsws/lsphp74/bin/php7.4 composer.phar install
fi

# Copying the env example file
cp .env.example .env

# Generating key and linking storage
/usr/local/lsws/lsphp81/bin/php8.1 artisan key:generate
/usr/local/lsws/lsphp81/bin/php8.1 artisan storage:link

ln -s /usr/local/lsws/lsphp81/bin/php8.1  /usr/local/bin/php81
ln -s /usr/local//lsws/lsphp74/bin/php7.4  /usr/local/bin/php74

# Set storage permission to ALL
chown -R root:www-data storage/ bootstrap/cache
chmod -R 777 storage/ bootstrap/cache
systemctl enable lsws
systemctl restart lsws

# Set Admin password for LiteSpeed GUI Dashboard
/usr/local/lsws/admin/misc/admpass.sh

echo "OpenLiteSpeed server configurations has finished."
echo "Don't forget to configure the .env file manually and set LiteSpeed dashboard admin password."
echo "You can now start configuring the LiteSpeed dashboard on via the browser..https://your_ip:7080"
