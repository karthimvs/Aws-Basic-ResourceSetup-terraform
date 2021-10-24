#! /bin/bash
sudo yum update
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<center><h1>Deployed via Terraform</h1></center>" | sudo tee /var/www/html/index.html