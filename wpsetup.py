#!/usr/bin/env python3

import subprocess
import sys
import random
import string
import os

def install_package(package_name):
    try:
        print(f"Installing {package_name}")
        subprocess.check_call(['pkg', 'install', '-y', package_name])
    except subprocess.CalledProcessError as e:
        print(f"Failed to install {package_name}: {str(e)}")
        sys.exit(1)

def setup_apache(wp_domain, pma_domain):
    try:
        print("Setting up Apache")
        subprocess.check_call(['sysrc', 'apache24_enable=YES'])
        subprocess.check_call(['service', 'apache24', 'start'])

        # Setup Virtual Hosts
        with open("/usr/local/etc/apache24/Includes/vhosts.conf", "w") as vhost_file:
            vhost_file.write(f"""
            <VirtualHost *:80>
                ServerName {wp_domain}
                DocumentRoot "/usr/local/www/apache24/data/wordpress"
            </VirtualHost>
            
            <VirtualHost *:80>
                ServerName {pma_domain}
                DocumentRoot "/usr/local/www/apache24/data/phpmyadmin"
            </VirtualHost>
            """)
        subprocess.check_call(['service', 'apache24', 'restart'])
    except subprocess.CalledProcessError as e:
        print(f"Failed to set up Apache: {str(e)}")
        sys.exit(1)

def setup_mysql(db_name, user_name, password):
    try:
        print("Setting up MySQL")
        subprocess.check_call(['sysrc', 'mysql_enable=YES'])
        subprocess.check_call(['service', 'mysql-server', 'start'])

        # Setup MySQL Database
        subprocess.check_call(['mysql', '-e', f"CREATE DATABASE {db_name};"])
        subprocess.check_call(['mysql', '-e', f"CREATE USER '{user_name}'@'localhost' IDENTIFIED BY '{password}';"])
        subprocess.check_call(['mysql', '-e', f"GRANT ALL PRIVILEGES ON {db_name}.* TO '{user_name}'@'localhost';"])
        subprocess.check_call(['mysql', '-e', "FLUSH PRIVILEGES;"])

    except subprocess.CalledProcessError as e:
        print(f"Failed to set up MySQL: {str(e)}")
        sys.exit(1)

def setup_php():
    try:
        print("Setting up PHP")
        subprocess.check_call(['sysrc', 'php_fpm_enable=YES'])
        subprocess.check_call(['service', 'php-fpm', 'start'])
    except subprocess.CalledProcessError as e:
        print(f"Failed to set up PHP: {str(e)}")
        sys.exit(1)

def setup_wordpress(db_name, user_name, password):
    try:
        print("Setting up WordPress")
        subprocess.check_call(['fetch', 'https://wordpress.org/latest.tar.gz'])
        subprocess.check_call(['tar', '-xzvf', 'latest.tar.gz', '-C', '/usr/local/www/apache24/data'])

        # Update WordPress Configuration
        subprocess.check_call(['cp', '/usr/local/www/apache24/data/wordpress/wp-config-sample.php', '/usr/local/www/apache24/data/wordpress/wp-config.php'])
        subprocess.check_call(['sed', '-i', f"s/database_name_here/{db_name}/", '/usr/local/www/apache24/data/wordpress/wp-config.php'])
        subprocess.check_call(['sed', '-i', f"s/username_here/{user_name}/", '/usr/local/www/apache24/data/wordpress/wp-config.php'])
        subprocess.check_call(['sed', '-i', f"s/password_here/{password}/", '/usr/local/www/apache24/data/wordpress/wp-config.php'])

        print("WordPress is set up. Please configure the rest through its installation GUI.")

    except subprocess.CalledProcessError as e:
        print(f"Failed to set up WordPress: {str(e)}")
        sys.exit(1)

def generate_password(length=12):
    chars = string.ascii_letters + string.digits + '!@#$%^&*()'
    random.seed = (os.urandom(1024))
    password = ''.join(random.choice(chars) for i in range(length))
    return password

def setup_phpmyadmin():
    try:
        print("Setting up phpMyAdmin")
        subprocess.check_call(['fetch', 'https://files.phpmyadmin.net/phpMyAdmin/latest.tar.gz'])
        subprocess.check_call(['tar', '-xzvf', 'latest.tar.gz', '-C', '/usr/local/www/apache24/data'])
        subprocess.check_call(['mv', '/usr/local/www/apache24/data/phpMyAdmin-*', '/usr/local/www/apache24/data/phpmyadmin'])
    except subprocess.CalledProcessError as e:
        print(f"Failed to set up phpMyAdmin: {str(e)}")
        sys.exit(1)

def main():
    db_name = 'wordpress'
    user_name = 'wordpress_user'
    password = generate_password()

    wp_domain = input("Enter the domain for WordPress: ")
    pma_domain = input("Enter the domain for phpMyAdmin: ")

    install_package('apache24')
    install_package('mysql80-server')
    install_package('php74')
    install_package('php74-mysqli')
    install_package('mod_php74')

    setup_apache(wp_domain, pma_domain)
    setup_mysql(db_name, user_name, password)
    setup_php()
    setup_wordpress(db_name, user_name, password)
    setup_phpmyadmin()

    print(f"Database: {db_name}, Username: {user_name}, Password: {password}")

if __name__ == "__main__":
    main()