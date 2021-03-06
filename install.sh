#This is a script to automatically install Minecraftly on a single server for testing
#Requirements: Google Cloud Platform server only (for now). Debian 8 or higher. Server needs at least 1GB Ram
#! /bin/bash
#Update operating system & install some packages
sudo -i
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt-get install screen -y
apt-get install git -y

#Install MySQL server with username "root", no password, and database name "minecraftly"
export DEBIAN_FRONTEND=noninteractive
echo "mysql-server-5.5 mysql-server/root_password password 123456" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password 123456" | debconf-set-selections
apt-get -y install mysql-server-5.5
mysql -u root -p123456 -e "create database minecraftly;"
mysqladmin -u root -p123456 password ''

#Install Redis server
apt-get install redis-server -y

#Install Latest Java Version
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get update -y
apt-get install oracle-java8-set-default -y

#Make some directories & download some preconfigured files
mkdir /m
mkdir /m/b1
mkdir /m/b2
wget -P /m/b1 https://storage.googleapis.com/minecraftly/test/BungeeCord.jar
wget -P /m/b2 https://storage.googleapis.com/minecraftly/test/BungeeCord.jar
mkdir /m/b1/plugins
mkdir /m/b2/plugins
wget -P /m/b1/plugins https://storage.googleapis.com/minecraftly/test/RedisBungee.jar
wget -P /m/b2/plugins https://storage.googleapis.com/minecraftly/test/RedisBungee.jar
wget -P /m/b1/plugins https://storage.googleapis.com/minecraftly/test/MinecraftlyBungee.jar
wget -P /m/b2/plugins https://storage.googleapis.com/minecraftly/test/MinecraftlyBungee.jar
mkdir /m/b1/plugins/MinecraftlyBungee/
mkdir /m/b2/plugins/MinecraftlyBungee/
wget -P /m/b1/plugins/MinecraftlyBungee https://storage.googleapis.com/minecraftly/test/config.yml
wget -P /m/b2/plugins/MinecraftlyBungee https://storage.googleapis.com/minecraftly/test/config.yml
wget -P /m/b1/plugins/MinecraftlyBungee https://storage.googleapis.com/minecraftly/test/motd.yml
wget -P /m/b2/plugins/MinecraftlyBungee https://storage.googleapis.com/minecraftly/test/motd.yml
mkdir /m/buildtools
mkdir /m/s1
mkdir /m/s2
wget -P /m/s1 https://storage.googleapis.com/minecraftly/test/spigot.jar
wget -P /m/s2 https://storage.googleapis.com/minecraftly/test/spigot.jar
mkdir /m/s1/plugins
mkdir /m/s2/plugins
wget -P /m/s1/plugins https://storage.googleapis.com/minecraftly/test/Minecraftly.jar
wget -P /m/s2/plugins https://storage.googleapis.com/minecraftly/test/Minecraftly.jar
wget -P /m/s1/plugins https://storage.googleapis.com/minecraftly/test/ProtocolLib.jar
wget -P /m/s2/plugins https://storage.googleapis.com/minecraftly/test/ProtocolLib.jar
wget -P /m/s1/plugins https://storage.googleapis.com/minecraftly/test/Vault.jar
wget -P /m/s2/plugins https://storage.googleapis.com/minecraftly/test/Vault.jar
mkdir /m/worlds

#Start servers for the first time to generate files
cd /m/b1 && screen -dmS b1 java -jar BungeeCord.jar
sleep 60
screen -r b1 -X stuff 'end\n'
cd /m/b2 && screen -dmS b2 java -jar BungeeCord.jar
sleep 60
screen -r b2 -X stuff 'end\n'
cd /m/s1 && screen -dmS s1 java -Dcom.mojang.eula.agree=true -jar spigot.jar --world-dir /m/worlds --port 25567
sleep 60
screen -r s1 -X stuff 'stop\n'
cd /m/s2 && screen -dmS s2 java -Dcom.mojang.eula.agree=true -jar spigot.jar --world-dir /m/worlds --port 25568
sleep 60
screen -r s2 -X stuff 'stop\n'

#Configure some files
sed -i "s/ host: 0.0.0.0:.*/ host: 0.0.0.0:25565/" /m/b1/config.yml
sed -i "s/ host: 0.0.0.0:.*/ host: 0.0.0.0:25566/" /m/b2/config.yml
sed -i "s/ip_forward: .*/ip_forward: true/" /m/b1/config.yml
sed -i "s/ip_forward: .*/ip_forward: true/" /m/b2/config.yml
sed -i "s/motd: .*/motd: 'BungeeCord 1'/" /m/b1/config.yml
sed -i "s/motd: .*/motd: 'BungeeCord 2'/" /m/b2/config.yml
sed -i "s/md_5:/minecraftly:/" /m/b1/config.yml
sed -i "s/md_5:/minecraftly:/" /m/b2/config.yml
sed -i "s/heartbeatPort: .*/heartbeatPort: 25567/" /m/s1/plugins/Minecraftly/config.yml
sed -i "s/heartbeatPort: .*/heartbeatPort: 25568/" /m/s2/plugins/Minecraftly/config.yml
sed -i "s/address: localhost:.*/address: localhost:25567/" /m/b1/config.yml
sed -i "s/address: localhost:.*/address: localhost:25568/" /m/b2/config.yml
HOSTNAME=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
sed -i "s/server-id:.*/server-id: $HOSTNAME/" /m/b1/plugins/RedisBungee/config.yml
sed -i "s/server-id:.*/server-id: $HOSTNAME/" /m/b2/plugins/RedisBungee/config.yml
sed -i "s/level-name=.*/level-name=world1/" /m/s1/server.properties
sed -i "s/level-name=.*/level-name=world2/" /m/s2/server.properties
sed -i "s/online-mode=.*/online-mode=false/" /m/s1/server.properties
sed -i "s/online-mode=.*/online-mode=false/" /m/s2/server.properties
sed -i "s/bungeecord: .*/bungeecord: true/" /m/s1/spigot.yml
sed -i "s/bungeecord: .*/bungeecord: true/" /m/s2/spigot.yml
sed -i "s/connection-throttle: .*/connection-throttle: -1/" /m/s1/bukkit.yml
sed -i "s/connection-throttle: .*/connection-throttle: -1/" /m/s2/bukkit.yml

#Start servers to play
cd /m/b1 && screen -dmS b1 java -jar BungeeCord.jar
cd /m/b2 && screen -dmS b2 java -jar BungeeCord.jar
cd /m/s1 && screen -dmS s1 java -Dcom.mojang.eula.agree=true -jar spigot.jar --world-dir /m/worlds --port 25567
cd /m/s2 && screen -dmS s2 java -Dcom.mojang.eula.agree=true -jar spigot.jar --world-dir /m/worlds --port 25568
