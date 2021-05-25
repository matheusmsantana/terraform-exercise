sudo apt update
sudo apt install -y mysql-server-5.7
sudo cp -f /home/azureuser/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
sudo mysql < /home/azureuser/mysql/script.sql
sudo systemctl restart mysql.service
sleep 30