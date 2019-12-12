#!/bin/bash


# script needs to be run with super privilege
if [ $(id -u) -ne 0 ]; then
  printf "Script must be run with superuser privilege. Try 'sudo ./install.sh'\n"
  exit 1
fi

apt list --upgradable

# 1. install requirements
apt -f -y install dialog mosquitto mosquitto-clients redis-server redis-tools postgresql

# 2. setup PostgreSQL databases and users
sudo -u postgres psql -c "create role chirpstack_as with login password 'dbpassword';"
sudo -u postgres psql -c "create role chirpstack_ns with login password 'dbpassword';"
sudo -u postgres psql -c "create database chirpstack_as with owner chirpstack_as;"
sudo -u postgres psql -c "create database chirpstack_ns with owner chirpstack_ns;"
sudo -u postgres psql chirpstack_as -c "create extension pg_trgm;"
sudo -u postgres psql chirpstack_as -c "create extension hstore;"
sudo -u postgres psql -U postgres -f init_sql.sql

#3. install lora packages
#3.1 install https requirements
#apt -f -y install apt-transport-https dirmngr
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1CE2AFD36DBCCA00
#echo "deb https://artifacts.loraserver.io/packages/3.x/deb stable main" | sudo tee /etc/apt/sources.list.d/loraserver.list
#apt update
#apt install loraserver
#apt install lora-gateway-bridge
#apt install lora-app-server

#3.2 download lora packages
#wget https://artifacts.loraserver.io/packages/3.x/deb/pool/main/l/lora-app-server/lora-app-server_3.1.0_linux_amd64.deb 
wget https://artifacts.chirpstack.io/packages/3.x/deb/pool/main/c/chirpstack-application-server/chirpstack-application-server_3.6.1_linux_amd64.deb
#wget https://artifacts.loraserver.io/packages/3.x/deb/pool/main/l/lora-gateway-bridge/lora-gateway-bridge_3.0.1_linux_arm64.deb
wget https://artifacts.chirpstack.io/packages/3.x/deb/pool/main/c/chirpstack-gateway-bridge/chirpstack-gateway-bridge_3.5.0_linux_amd64.deb
#wget https://artifacts.loraserver.io/packages/3.x/deb/pool/main/l/loraserver/loraserver_3.0.2_linux_amd64.deb
wget https://artifacts.chirpstack.io/packages/3.x/deb/pool/main/c/chirpstack-network-server/chirpstack-network-server_3.5.0_linux_amd64.deb

#3.3 install lora packages
dpkg -i chirpstack-application-server_3.6.1_linux_amd64.deb
dpkg -i chirpstack-gateway-bridge_3.5.0_linux_amd64.deb
dpkg -i chirpstack-network-server_3.5.0_linux_amd64.deb

#4. configure lora
# configure LoRa Server
cp -f /etc/chirpstack-network-server/chirpstack-network-server.toml  /etc/chirpstack-network-server/chirpstack-network-server.toml_bak
cp -rf ./chirpstack-network-server_conf/*  /etc/chirpstack-network-server/
#cp -f /etc/loraserver/loraserver.eu_863_870.toml /etc/loraserver.toml
chown -R chirpstack-network-server:chirpstack-network-server /etc/chirpstack-network-server

# configure LoRa App Server
cp -f /etc/chirpstack-application-server/chirpstack-application-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml_bak
cp -f ./chirpstack-application-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml
chown -R chirpstack-application-server:chirpstack-application-server /etc/chirpstack-application-server

#5. start lora
# start loraserver
systemctl restart chirpstack-network-server

# start lora-app-server
systemctl restart chirpstack-application-server

echo "Install LoRaServer success!"
