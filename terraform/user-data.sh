#!/bin/bash
set -e

apt-get update -y
apt-get install -y nginx

HOSTNAME=$(hostname)

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>SecureScale</title>
</head>
<body>
    <h1>SecureScale is running!</h1>
    <h2>Cloud Engineering Portfolio Project</h2>
    <p>Served by: $HOSTNAME</p>
</body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx