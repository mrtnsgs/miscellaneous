#!/bin/bash
###################################################################
# Script para ajustar pacotes iniciais e interface de rede
# 1.0v
# 13/11/2019
# Autor: Guilherme Martins
###################################################################


USE_MESSAGE="
Uso: $(basename "$0") [OPÇÕES]

OPÇÕES:
	-h, --help 		Show this help menu
	-a, --all 		Enable all below options
	-o, --hostname 		Set hostname
	-p, --packages 		Install the follow packages: net-tools sudo vim curl wget g++ gcc htop git
	-s, --sudo 		Enable the sudo commando to users that are using bash
	-n, --newinterface 	Change network interface from DHCP to STATIC
"

function is_root_user() {
	if [[ $EUID != 0 ]]; then
    	return 1
  	fi
  	return 0
}

function installPkgs(){
	echo "Updating packages..."
	apt-get -y update ; apt-get -y upgrade ; apt-get -y install net-tools sudo vim curl wget g++ gcc htop git
}

function setHostname(){
	local FILEHOSTN='/etc/hostname'

	echo "Setting HOSTNAME..."
	echo "Insert new hostname: " ; read NEWHOSTNAME

	echo $NEWHOSTNAME > $FILEHOSTN
	sed -i "s/$(hostname)/$NEWHOSTNAME/g" /etc/hosts
	hostname $NEWHOSTNAME
	echo "Hostname set to $NEWHOSTNAME !"
}

function setSudoers(){
	local FILESUDO='/etc/sudoers'
	
	which sudo
	
	if [[ $? -eq 0 ]]; then
		echo "Setting sudo command to $FILESUDO file"
		sed -i "21s/^/$(grep bash /etc/passwd | grep -v root | cut -d':' -f1) ALL=(ALL) ALL/"  $FILESUDO
	else
		echo "sudo package not found, please install the package using -p or --packages"
	fi
}

function adjustNetInterface(){
	local INTERFACESNET='/etc/network/interfaces'
	
	echo "Insert the network interface: " ; read IntRD
	echo "Insert IP address: " ; read ADDR
	echo "Insert the netmask: " ; read NETMSK
	echo "Insert the gateway: " ; read GWAY

	echo "Changing DHCP to STATIC" ; sed -i 's/dhcp/static/g' $INTERFACESNET ; sed -i "12s/^/auto $IntRD\n/" $INTERFACESNET

	echo -e "address $ADDR
	netmask $NETMSK
	gateway $GWAY" >> $INTERFACESNET

	echo "Reboot the server to apply the changes"
	#echo "The server go to be rebooted to apply the new configurations"
	#echo "Reiniciando servidor para que sejam aplicadas as novas configurações"
	#sleep 10 ; reboot
}

if ! is_root_user; then
	echo "You must be root user to execute this script" 2>&1
	echo  2>&1
	exit 1
fi

if [[ -z $1 ]]; then
    echo "$USE_MESSAGE"
fi

while [[ -n "$1" ]]; do
	case "$1" in
		-h | --help) 	echo "$USE_MESSAGE" && exit 0 ;;
		-o | --hostname) setHostname ;;
		-p | --packages) installPkgs ;;
		-s | --sudo)  	 setSudoers ;;
		-n | --newinterface) adjustNetInterface	;;
		-a | --all)	installPkgs && setHostname && setSudoers && adjustNetInterface ;;
		*) echo "Invalid option, please use -h or --help to help" && exit 1 ;;
	esac
	shift
done