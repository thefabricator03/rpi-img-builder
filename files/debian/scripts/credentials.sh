#!/bin/bash
if [ -f /boot/credentials.txt ]; then
	source /boot/credentials.txt;
fi

# Functions
change_hostname(){
sed -i "s/bcm2711/${HOSTNAME}/g" /etc/hostname
sed -i "s/bcm2711v7/${HOSTNAME}/g" /etc/hostname
sed -i "s/bcm2710/${HOSTNAME}/g" /etc/hostname
sed -i "s/bcm2709/${HOSTNAME}/g" /etc/hostname
sed -i "s/bcm2708/${HOSTNAME}/g" /etc/hostname
sed -i "s/bcm2711/${HOSTNAME}/g" /etc/hosts
sed -i "s/bcm2711v7/${HOSTNAME}/g" /etc/hosts
sed -i "s/bcm2710/${HOSTNAME}/g" /etc/hosts
sed -i "s/bcm2709/${HOSTNAME}/g" /etc/hosts
sed -i "s/bcm2708/${HOSTNAME}/g" /etc/hosts
}

change_branding(){
sed -i "s/Raspberry Pi/${BRANDING}/g" /etc/update-motd.d/15-brand
}

dhcp(){
sed -i "s/wlan_address 10.0.0.10/#address 10.0.0.10/g" /etc/opt/interfaces
sed -i "s/wlan_netmask 255.255.255.0/#netmask 255.255.255.0/g" /etc/opt/interfaces
sed -i "s/wlan_gateway 10.0.0.1/#gateway 10.0.0.1/g" /etc/opt/interfaces
sed -i "s/wlan_dns-nameservers 8.8.8.8 8.8.4.4/#dns-nameservers 8.8.8.8 8.8.4.4/g" /etc/opt/interfaces
sed -i "s/REGDOMAIN=/REGDOMAIN=${COUNTRYCODE}/g" /etc/default/crda
sed -i "s/country=/country=${COUNTRYCODE}/g" /etc/opt/wpa_supplicant.conf
sed -i 's/name=/ssid="'"${SSID}"'"/g' /etc/opt/wpa_supplicant.conf
sed -i 's/password=/psk="'"${PASSKEY}"'"/g' /etc/opt/wpa_supplicant.conf
mv -f /etc/opt/interfaces /etc/network/interfaces
mv -f /etc/opt/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
iw reg set ${COUNTRYCODE}
sleep 2s
if [[ `grep "1" /sys/class/net/eth0/carrier` ]]; then
	ifconfig eth0 up
	ifup eth0;
fi
ifconfig wlan0 up
ifup wlan0
}

static(){
sed -i "s/iface wlan0 inet dhcp/iface wlan0 inet static/g" /etc/opt/interfaces
sed -i "s/wlan_address 10.0.0.10/address ${IPADDR}/g" /etc/opt/interfaces
sed -i "s/wlan_netmask 255.255.255.0/netmask ${NETMASK}/g" /etc/opt/interfaces
sed -i "s/wlan_gateway 10.0.0.1/gateway ${GATEWAY}/g" /etc/opt/interfaces
sed -i "s/wlan_dns-nameservers 8.8.8.8 8.8.4.4/dns-nameservers ${NAMESERVERS}/g" /etc/opt/interfaces
sed -i "s/REGDOMAIN=/REGDOMAIN=${COUNTRYCODE}/g" /etc/default/crda
sed -i "s/country=/country=${COUNTRYCODE}/g" /etc/opt/wpa_supplicant.conf
sed -i 's/name=/ssid="'"${SSID}"'"/g' /etc/opt/wpa_supplicant.conf
sed -i 's/password=/psk="'"${PASSKEY}"'"/g' /etc/opt/wpa_supplicant.conf
mv -f /etc/opt/interfaces /etc/network/interfaces
mv -f /etc/opt/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
iw reg set ${COUNTRYCODE}
sleep 2s
if [[ `grep "1" /sys/class/net/eth0/carrier` ]]; then
	ifconfig eth0 up
	ifup eth0;
fi
ifconfig wlan0 up
ifup wlan0
}

connect_wifi(){
if [[ "$MANUAL" == "y" ]]; then
	static;
else
	dhcp;
fi
}

hostname_branding(){
if [[ "$CHANGE" == "y" ]]; then
	change_hostname;
	change_branding;
	hostnamectl set-hostname ${HOSTNAME};
	systemctl restart avahi-daemon;
fi
}

remove_wifi(){
rm -f /usr/local/bin/credentials
rm -f /boot/rename_to_credentials.txt
rm -f /etc/opt/{interfaces,wpa_supplicant.conf}
mv -f /etc/opt/interfaces.manual /etc/network/interfaces
mv -f /etc/opt/wpa_supplicant.manual /etc/wpa_supplicant/wpa_supplicant.conf
sleep 2s
if [[ `grep "1" /sys/class/net/eth0/carrier` ]]; then
	ifconfig eth0 up;
	ifup eth0;
fi
if [[ `grep 'mywifissid' /etc/wpa_supplicant/wpa_supplicant.conf` ]]; then
	:;
else
	ifconfig wlan0 up;
	ifup wlan0;
fi
}

# Renew ssh keys and machine-id
sleep 1s
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
systemctl restart ssh
rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure

# Check Credentials
if [ -f /boot/credentials.txt ]; then
	hostname_branding;
	connect_wifi;
else
	remove_wifi;
fi

# Clean
rm -f /usr/local/bin/credentials
rm -f /boot/credentials.txt
rm -f /etc/opt/{interfaces.manual,wpa_supplicant.manual}
systemctl disable credentials > /dev/null 2>&1

exit 0
