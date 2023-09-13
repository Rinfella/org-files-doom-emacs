#!/bin/bash

# Enter root mode
sudo su

# Installing OpenLiteSpeed, Certbot and LSPHP
apt update
echo "Adding LiteSpeed repository to apt.."
wget -O - https://repo.litespeed.sh | sudo bash

echo "Installing LiteSpeed, LSPHP and certbot.."
apt update
apt install openlitespeed certbot lsphp82 lsphp82-{common,curl,mysql}

# Creating www directory
cd "/usr/local/lsws"
mkdir "www"
cd "www"
echo "www directory created at $PWD"

read -p "Enter the name of your project directory: " dir_name

mkdir   "$dir_name"
cd      "$dir_name"

read -p "Enter the URL of the project repository: " repo_url
echo "Cloning the repository.. $repo_url"
git clone "$repo_url" .
echo "Repository cloned into $PWD"

# Installing Composer
echo "Installing Composer.."
/usr/local/lsws/lsphp81/bin/php8.2 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
/usr/local/lsws/lsphp81/bin/php8.2 composer-setup.php
/usr/local/lsws/lsphp81/bin/php8.2 composer.phar install

# Copying the env example file
cp .env.example .env

# Generating key and linking storage
/usr/local/lsws/lsphp81/bin/php8.1 artisan key:generate
/usr/local/lsws/lsphp81/bin/php8.1 artisan storage:link

# Set storage permission to ALL
chmod -R 777 storage/
systemctl enable lsws
systemctl restart lsws

# Set Admin password for LiteSpeed GUI Dashboard
/usr/local/lsws/admin/misc/admpass.sh

echo "OpenLiteSpeed server configurations has finished."
echo "Don't forget to configure the .env file manually and set LiteSpeed dashboard admin password."
echo "You can now start configuring the LiteSpeed dashboard on via the browser.."
