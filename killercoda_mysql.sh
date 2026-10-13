# Laboratorio Killercoda (Ubuntu) - MySQL con cadena de conexion local
# Cadena: mysql://root:root@127.0.0.1:3306/dw_taxi

apt-get update && apt-get install -y mysql-server
service mysql start

# En Ubuntu, root usa auth_socket; se cambia a contrasena para conectar por 127.0.0.1
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'root'; FLUSH PRIVILEGES;"

# Conexion local y creacion de la base
mysql -h 127.0.0.1 -P 3306 -u root -proot -e "CREATE DATABASE dw_taxi; SHOW DATABASES;"