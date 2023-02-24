#!/usr/bin/env bash
#
sudo apt-get update

read -p "Enter domain name : " domain
read -p "Enter username : " primaryusername

sudo useradd $primaryusername -g sudo
# Functions
ok() { echo -e '\e[32m'$domain'\e[m'; } # Green
die() {
    echo -e '\e[1;31m'$domain'\e[m'
    exit 1
}

sudo htpasswd -c /etc/nginx/.htpasswd $primaryusername

# Variables
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
#NGINX_ENABLED_VHOSTS='/etc/nginx/conf.d'
WEB_DIR='/var/www'
WEB_USER=$primaryusername

sudo rm -rf /var/log/nginx
sudo mkdir /var/log/nginx
sudo touch /var/log/nginx/error.log
sudo chown -R www-data:www-data /var/log/nginx

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
#[ $# != "1" ] && die "Usage: $(basename $0) domainName"

rm $NGINX_AVAILABLE_VHOSTS/$domain
rm $NGINX_ENABLED_VHOSTS/$domain

# Create nginx config file
cat >$NGINX_AVAILABLE_VHOSTS/$domain <<EOF
### www to non-www
#server {
#    listen	 80;
#    server_name  www.$domain;
#    return	 301 http://$domain\$request_uri;
#}
server {
    listen   80;
    server_name $domain www.$domain;
    root  $WEB_DIR/$domain;
    charset  utf-8;
    index index.php index.html index.htm;
   
    access_log $WEB_DIR/logs/$domain-access.log;
    error_log $WEB_DIR/logs/$domain-error.log;

    location / {
        try_files $uri $uri/ =404;
        auth_basic "Restricted Content";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }

     location /pgadmin/ {
        proxy_pass http://127.0.0.1:5050;
    }

      location /redis-commander/ {
        proxy_pass http://127.0.0.1:8081;
    }

    location /bullboard/ {
        proxy_pass http://127.0.0.1:3000;
    }


}
EOF

# Creating {public,log} directories
mkdir -p $WEB_DIR/$domain/{public_html,logs}
mkdir -p $WEB_DIR/logs

sudo chown -R $USER:$USER $WEB_DIR/$domain

# Creating index.html file
cat >$WEB_DIR/$domain/index.html <<EOF
<!DOCTYPE html>
<head>
    <title>Quick links</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css"
        integrity="sha384-rbsA2VBKQhggwzxH7pPCaAqO46MgnOM80zW1RWuH61DGLwZJEdK2Kadq2F9CUG65" crossorigin="anonymous">
</head>
<body class="p-5">
    <ul>
        <li>
            <p><a target="_blank" href="http://$domain/pgadmin">PG Admin</a></p>
        </li>
        <li>
            <p><a target="_blank" href="http://$domain/redis-commander">Redis commander</a></p>
        </li>
        <li>
            <p><a target="_blank" href="http://$domain/bullboard">Bullboard</a></p>
        </li>
    </ul>
</body>
</html>
EOF

sudo chown -R $USER:$USER $WEB_DIR/$domain

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE_VHOSTS/$domain $NGINX_ENABLED_VHOSTS/

service nginx restart

find / -type f -name ".certbot.lock" -exec rm {} \;
sudo certbot --nginx -d $domain -d www.$domain

ok "Site Created for $domain"
