#!/bin/bash
# Install Apache web server
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
# Create website files
echo "<h1>Welcome to the Home Page!</h1>" > /var/www/html/index.html
echo "<h1>Order Page</h1><p>Place your order here.</p>" > /var/www/html/order.html
echo "<h1>Payment Page</h1><p>Make your payment.</p>" > /var/www/html/payment.html
