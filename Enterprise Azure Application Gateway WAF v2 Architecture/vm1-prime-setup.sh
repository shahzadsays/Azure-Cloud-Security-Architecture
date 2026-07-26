sudo apt update -y
sudo apt install nginx -y
sudo mkdir -p /var/www/html/prime
echo 'This is Amazon Prime Server' | sudo tee /var/www/html/prime/index.html > /dev/null
