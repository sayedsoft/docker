echo "Int before Setup"
sudo apt -y upgrade
sudo apt update
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common certbot python3-certbot-nginx apache2-utils
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt-get -y install curl
sudo apt-get -y install gnupg
sudo apt-get -y install ca-certificates
sudo apt-get -y install lsb-release
echo "Setuping docker"
sudo apt -y install docker-ce
echo "Setuping docker-compose"
sudo apt -y install docker-compose

# Compose
echo "Do you want run docker-compose up ?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        echo "Running docker up"
        docker compose down
        docker-compose up -d
        break
        ;;
    No) exit ;;
    esac
done

# Restart
echo "Do you want run setup up domain  ?"
select yndomain in "Yes" "No"; do
    case $yndomain in
    Yes)
        echo "Setup.. domain"
        chmod +x ./addvhost.sh
        sudo ./addvhost.sh
        break
        ;;
    No) exit ;;
    esac
done
