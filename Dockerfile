FROM php:5.6-apache

RUN echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list && \
    echo "deb-src [trusted=yes] http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list 

RUN apt-get update && apt-get install -y wget && \
    a2enmod headers rewrite include && \
    a2dismod deflate -f && \
    service apache2 restart

# Configure Apache with the provided virtual host configuration
RUN echo '\
<VirtualHost *:80>\n\
    ServerName boost.localhost\n\
    DocumentRoot /var/www/html\n\
    <Directory "/var/www/html">\n\
        Options +MultiViews +Includes +ExecCGI +FollowSymLinks +Includes\n\
        AllowOverride All\n\
        Order allow,deny\n\
        Allow from all\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Set up local PHP configuration for Boost
RUN mkdir -p /var/www/html/common/code && \
    echo "<?php\n\
define('BOOST_WEBSITE_SHARED_DIR', '/var/www/shared');\n\
define('STATIC_DIR', '/var/www/shared/archives/live');\n\
?>" > /var/www/html/common/code/boost_config_local.php

# Set up the appropriate directories for the documentation
RUN mkdir -p /var/www/shared/archives/live && \
    cd /var/www/shared/archives/live && \
    wget https://boostorg.jfrog.io/artifactory/main/release/1.74.0/source/boost_1_74_0.tar.gz && \
    tar -xvf boost_1_74_0.tar.gz && \
    rm boost_1_74_0.tar.gz

# Copy the app source to the container
COPY . /var/www/html/

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]