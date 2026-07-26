sudo apt update -y
sudo apt install nginx -y
sudo mkdir -p /var/www/html/netflix
echo 'This is Netflix Server' | sudo tee /var/www/html/netflix/index.html > /dev/null
