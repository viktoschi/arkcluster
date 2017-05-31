#!/bin/sh

# Change the ARK_UID if needed
if [ ! "$(id -u steam)" -eq "$ARK_UID" ]; then 
	echo "Changing steam uid to $ARK_UID."
	usermod -o -u "$ARK_UID" steam ; 
fi
# Change gid if needed
if [ ! "$(id -g steam)" -eq "$ARK_GID" ]; then 
	echo "Changing steam gid to $ARK_GID."
	groupmod -o -g "$ARK_GID" steam ; 
fi

# Put steam owner of directories (if the uid changed, then it's needed)
chown -R steam:steam /ark /home/steam

# avoid error message when su -p (we need to read the /root/.bash_rc )
chmod -R 777 /root/

# Launch run.sh with user steam (-p allow to keep env variables)
su steam -c /home/steam/run.sh
