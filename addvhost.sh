#!/usr/bin/env bash
#

sudo apt install certbot python3-certbot-nginx

USERNAME=dockeruser
read -p "Enter domain name : " domain

# Functions
ok() { echo -e '\e[32m'$domain'\e[m'; } # Green
die() {
    echo -e '\e[1;31m'$domain'\e[m'
    exit 1
}

# Variables
#NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/conf.d'
WEB_DIR='/home'
WEB_USER=USERNAME

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
#[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Create nginx config file
cat >$NGINX_ENABLED_VHOSTS/$domain-vhost.conf <<EOF
### www to non-www
#server {
#    listen	 80;
#    server_name  www.$domain;
#    return	 301 http://$domain\$request_uri;
#}
server {
    listen   80;
    server_name $domain www.$domain;
    root  /home/USERNAME;
    charset  utf-8;
    index index.php index.html index.htm;
    #access_log $WEB_DIR/logs/$domain-access.log;
    access_log off;
    error_log $WEB_DIR/logs/$domain-error.log;
    #error_log off;
    ## REWRITES BELOW ##
    
    location / {
                try_files $uri $uri/ =404;
    }
}

 server {
    listen 80;
    server_name $domain/pgadmin;
    proxy_pass http://127.0.0.1:5050;
}

 server {
    listen 8081;
    server_name $domain/redis-commander;
    proxy_pass http://127.0.0.1:5050;
}


 server {
    listen 8081;
    server_name $domain/bullboard;
    proxy_pass http://127.0.0.1:3000;
}

EOF

# Creating {public,log} directories
#mkdir -p $WEB_DIR/USERNAME/{public_html,logs}

# Creating index.html file
cat >$WEB_DIR/USERNAME/index.html <<EOF
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
            <p><a target="_blank" href="http://$domain:8081/redis-commander">Redis commander</a></p>
        </li>
        <li>
            <p><a target="_blank" href="http://$domain:3000/bullboard">Bullboard</a></p>
        </li>
    </ul>
</body>
</html>
EOF

sudo certbot --nginx -d $domain -d www.$domain

# Changing permissions
chown -R $WEB_USER:$WEB_USER $WEB_DIR/USERNAME

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE_VHOSTS/$1 $NGINX_ENABLED_VHOSTS/$1

# Restart
echo "Do you wish to restart nginx?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        service nginx restart
        break
        ;;
    No) exit ;;
    esac
done

ok "Site Created for $domain"
