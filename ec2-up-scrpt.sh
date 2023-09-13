# Installing Composer
echo "Installing Composer.."
/usr/local/lsws/lsphp81/bin/php8.2 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
/usr/local/lsws/lsphp81/bin/php8.2 composer-setup.php
/usr/local/lsws/lsphp81/bin/php8.2 composer.phar install
