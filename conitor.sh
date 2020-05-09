#!/bin/bash
#coding:utf-8
#title:conitor.sh
#author:hacknonym
#launch:./conitor.sh   |or|   bash conitor.sh   |or|   . conitor.sh

source options.sh
source startup.sh
source loop.sh

#terminal text color code
cyan='\e[0;36m'
purple='\e[0;7;35m'
purpleb='\e[0;7;35;1m'
orange='\e[38;5;166m'
orangeb='\e[38;5;166;1m'
orangeh='\e[47;38;5;166;7m'
white='\e[0;37;1m'
whiteu='\e[0;37;1;4m'
whiteh='\e[0;37;1;7m'
grey='\e[0;37m'
green='\e[0;32m'
greenb='\e[0;32;1m'
greenh='\e[0;42;1m'
red='\e[0;31m'
redb='\e[0;31;1m'
redh='\e[0;41;1m'
redhf='\e[0;41;5;1m'
yellow='\e[0;33m'
yellowb='\e[0;33;1m'
yellowh='\e[0;43;1m'
blue='\e[0;34m'
blueb='\e[0;34;1m'
blueh='\e[0;44;1m'

MAIN_PATH=$(pwd)
USERNAME=$(whoami)
AUTH_FILE="$MAIN_PATH/authorized.txt"
LOG_FILE="$MAIN_PATH/conitor.log"
#LOG_FILE="/var/log/conitor/conitor.log"
APP_PATH="/usr/share/applications/Conitor.desktop"
ICON_PATH="/usr/share/icons/Conitor.ico"
NETSTAT=$(which netstat)

touch $AUTH_FILE
touch $LOG_FILE

state=1        #popup 'New unknown onnections'
cable_state=0  #Network

#External devices
old_nb_sdb=$(
	c=0
	for i in $(ls /dev | grep -Eo "sd[b-z][1-9]|sd[b-z][1-9][1-9]|sd[b-z][1-9][1-9][1-9]|sd[a-z][a-z][1-9]|sd[a-z][a-z][1-9][1-9]|sd[a-z][a-z][1-9][1-9][1-9]|sd[a-z][a-z][a-z][1-9]|sd[a-z][a-z][a-z][1-9][1-9]|sd[a-z][a-z][a-z][1-9][1-9][1-9]") ; do
		c=$(($c + 1))
	done
	echo -e "$c"
)

trap options_quit INT

launch

resize -s 36 86 1> /dev/null

while [ true ] ; do

	# ----------------------Variables and operations used for display------------------------- #

	#System
	current_date=$(date "+%d-%m-%Y %H:%M:%S")
	hostname=$(uname -n)

	#Network Wi-Fi
	private_ip=$(hostname -I)
	ap_freq=$(iwgetid --freq | cut -d ':' -f 2)
	essid=$(iwgetid --raw)
	essid_file=$(ls -1F /etc/NetworkManager/system-connections/ | grep -m 1 "$essid")
	if [ ! -z "$essid_file" ] ; then
		wifipass=$(cat "/etc/NetworkManager/system-connections/$essid_file" | grep -e "psk=" | cut -d '"' -f 2 | cut -c 5-)
		sizepass=$(echo -e "$wifipass" | wc -m)
	fi

	#Network Interfaces
	wlan_interface=$(iwgetid --freq | cut -d ' ' -f 1)
	interface=$(ip link show | grep -v link | grep -e "UP" | grep -e "LOWER_UP" | cut -d ' ' -f 2 | sed 's/://g' | grep -v lo)
	nb_interfaces=$(
		c=0
		for i in $(echo -e "$interface") ; do
			c=$(($c + 1))
		done
		echo -e "$c"
	)
	list_interfaces=$(
		c=0
		for i in $(echo -e "$interface") ; do
			c=$(($c + 1))
			echo -e "    └─Interface $white$c$grey: $yellow$i$grey"
		done
	)

	if [ $nb_interfaces -eq 1 ] ; then
		if [ -z "$wlan_interface" ] ; then
			if [ ! -z "$interface" ] ; then
				cable_state=$(cat /sys/class/net/$interface/carrier)
			fi
		else
			cable_state=0
		fi
	else
		cable_state=0
	fi

	#Connections established
  	nb_conn_established=$(sudo $NETSTAT -punt | grep -v "::" | grep -v ":67" | grep -c "ESTABLISHED")
  	conn_established=$(
	  	for i in $(sudo $NETSTAT -punt | grep -v "::" | grep -v ":67" | grep -e "ESTABLISHED" | cut -c 21- | tr ' ' '_') ; do 
	  		correct=$(echo -e "$i" | tr '_' ' ')
	  		lhost=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 1)
	  		lport=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 2)
	  		rhost=$(echo -e "$correct" | awk '{print $2}' | cut -d ':' -f 1)
	  		rport=$(echo -e "$correct" | awk '{print $2}' | cut -d ':' -f 2)
	  		pid=$(echo -e "$correct" | awk '{print $4}' | cut -d '/' -f 1)
	  		progname=$(echo -e "$correct" | awk '{print $4}' | cut -d '/' -f 2-)

	  		conn_block "$lhost" $lport "$rhost" $rport $pid "$progname"
	  		
	  		if [ "$rhost" != "127.0.0.1" ] ; then
	  			echo -e "│  $yellow$lhost$grey:$green$lport$grey\t$yellow$rhost$grey:$green$rport$grey    \t$pid\t$progname   \t│"
	  		#Display loopback connection if '$display_conn_lo' = 1
	  		elif [ "$rhost" = "127.0.0.1" -a $display_conn_lo -eq 1 ] ; then
	  			echo -e "│  $yellow$lhost$grey:$green$lport$grey\t$yellow$rhost$grey:$green$rport$grey    \t$pid\t$progname   \t│"
	  		fi
	    done
    )

    #Popup 'New unknown Connections'
	if [ $nb_conn_established -ne 0 -a $state -eq 1 -a $level -eq 1 ] ; then
		state=0
		notify-send --urgency normal --expire-time 2500 -i $ICON_PATH "New unknown connections"
	elif [ $nb_conn_established -eq 0 -a $state -eq 0 ] ; then
		state=1
	fi

    #Connections listen
    nb_conn_listen=$(
	    c=0
	    for i in $(sudo $NETSTAT -puntl | grep -e "LISTEN" | awk '{print $7}' | cut -d '/' -f 2 | sort | uniq) ; do
	    	c=$(($c + 1))
		done
		echo -e "$c"
    )

    #Listen on loopback
	conn_listen_loopback=1  #initial state -> Good
    for i in $(sudo $NETSTAT -puntl | cut -c 21- | grep -e "LISTEN" | sort | tr ' ' '_') ; do
	    correct=$(echo -e "$i" | tr '_' ' ')
	    lhost=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 1)

	    #If among all the services, there is one listening on an address range other than 127.0.0.1, then there is a potential risk
    	if [ "$lhost" = "127.0.0.1" ] ; then  #127.0.0.1
	    	echo -n
	    elif [ -z "$lhost" ] ; then
	    	lhost=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 3)
	    	if [ "$lhost" = "1" ] ; then      #::1
	    		echo -n
	    	else
	    		conn_listen_loopback=0        #=0 -> do  not listen in loopback (potencial risk)
	    	fi
	    else
	    	conn_listen_loopback=0
		fi
	done

    conn_listen=$(
	    for i in $(sudo $NETSTAT -puntl | cut -c 21- | grep -e "LISTEN" | sort | tr ' ' '_') ; do
		    correct=$(echo -e "$i" | tr '_' ' ')
		    lhost=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 1)
		    lport=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 2)

		    if [ -z $lport ] ; then 
		    	lport=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 4)
		    fi

		    rhost=$(echo -e "$correct" | awk '{print $2}' | cut -d ':' -f 1)
		    rport=$(echo -e "$correct" | awk '{print $2}' | cut -d ':' -f 2)
		    pid=$(echo -e "$correct" | awk '{print $4}' | cut -d '/' -f 1)
		    progname=$(echo -e "$correct" | awk '{print $4}' | cut -d '/' -f 2)
		    
		    if [ "$lhost" = "127.0.0.1" ] ; then  #127.0.0.1
		    	echo -e "│    $white$progname$grey\tlisten on port $greenb$lport$grey\t$pid\t│"
		    elif [ -z "$lhost" ] ; then
		    	lhost=$(echo -e "$correct" | cut -d ' ' -f 1 | cut -d ':' -f 3)
		    	if [ "$lhost" = "1" ] ; then      #::1
		    		echo -e "│    $white$progname$grey\tlisten on port $greenb$lport$grey\t$pid\t│"
		    	else
		    		echo -e "│    $white$progname$grey\tlisten on port $white$orange$lport$grey\t$pid\t│"
		    	fi
		    else
		    	echo -e "│    $white$progname$grey\tlisten on port $white$orange$lport$grey\t$pid\t│"
			fi
	    done
    )

    #Downloads
    if [ $enable_downloads_analysis -eq 1 ] ; then
    	textl1="$greenb ✔$grey Downloads folder protection enabled$white\t\t\t"
		file=$(ls -lt $DOWNLOAD_PATH | sed -n '2 p' | cut -d ':' -f 2 | cut -c 4-)
		nb_file=$(
			c=0
			for i in $(ls -l $DOWNLOAD_PATH | grep -e ":" | awk '{print $1}'); do
				c=$(($c + 1))
			done
			echo -e "$c"
		)

		if [ $nb_file -lt $old_nb_file ] ; then
			old_nb_file="$nb_file"

		elif [ $nb_file -gt $old_nb_file ] ; then
			old_nb_file="$nb_file"
			notify-send --urgency normal --expire-time 2500 -i $ICON_PATH "File $file detected in Downloads"
			#Export antivirus() function in the current shell
			export -f antivirus
			xterm -fa monaco -fs 12 -T "Analysis '$file'" -geometry "80x24" -bg black -fg white -e "antivirus $DOWNLOAD_PATH/\"$file\"" & 1> /dev/null
		fi
	else
		textl1="$redb x$grey Downloads folder protection disabled$white\t\t\t"
	fi

	#External devices    sdb1 -> sdzzz999   : 18277 devices with 999 partitions
	nb_sdb=$(
		c=0
		for i in $(ls /dev | grep -Eo "sd[b-z][1-9]|sd[b-z][1-9][1-9]|sd[b-z][1-9][1-9][1-9]|sd[a-z][a-z][1-9]|sd[a-z][a-z][1-9][1-9]|sd[a-z][a-z][1-9][1-9][1-9]|sd[a-z][a-z][a-z][1-9]|sd[a-z][a-z][a-z][1-9][1-9]|sd[a-z][a-z][a-z][1-9][1-9][1-9]") ; do
			c=$(($c + 1))
		done
		echo -e "$c"
	)
	list_devices=$(
		c=0
		for i in $(ls -lt /media/$USERNAME/ | grep -e ":" | cut -d ':' -f 2 | cut -c 4- | tr ' ' 'µ') ; do
			c=$(($c+1))
			correct=$(echo -e "$i" | tr 'µ' ' ')
			echo -e "    └─Device $white$c$grey: $yellow$correct$grey"
		done
	)

	if [ $enable_sdb_analysis -eq 1 ] ; then
		textl5="$greenb ✔$grey External devices protection enabled$white\t\t\t"
		sdb_device=$(ls -t /dev | grep -Eo "sd[b-z][1-9]|sd[b-z][1-9][1-9]|sd[b-z][1-9][1-9][1-9]|sd[a-z][a-z][1-9]|sd[a-z][a-z][1-9][1-9]|sd[a-z][a-z][1-9][1-9][1-9]|sd[a-z][a-z][a-z][1-9]|sd[a-z][a-z][a-z][1-9][1-9]|sd[a-z][a-z][a-z][1-9][1-9][1-9]" | sed -n '1 p')
		#nb_sdb=$(...)

		if [ $nb_sdb -lt $old_nb_sdb ] ; then
			old_nb_sdb="$nb_sdb"

		elif [ $nb_sdb -gt $old_nb_sdb ] ; then
			old_nb_sdb="$nb_sdb"
			sleep 1		#time to mount the partition(s)
			sdb_name=$(df -hT | grep -e "$sdb_device" | cut -d '%' -f 2 | cut -c 2-)
			notify-send --urgency normal --expire-time 2500 -i $ICON_PATH "Device $sdb_name detected"
			#Export antivirus() function in the current shell
			export -f antivirus
			xterm -fa monaco -fs 12 -T "Analysis '$sdb_name'" -geometry "80x24" -bg black -fg white -e "antivirus \"$sdb_name\"" & 1> /dev/null
		fi
	else
		textl5="$redb x$grey External devices protection disabled$white\t\t\t"

		#To not analyze the devices already connected when the protection is re-activated
		#in this way, '$nb_sdb' and '$old_nb_sdb' are always equal, there is no difference during reactivation
		if [ $nb_sdb -lt $old_nb_sdb ] ; then
			old_nb_sdb="$nb_sdb"

		elif [ $nb_sdb -gt $old_nb_sdb ] ; then
			old_nb_sdb="$nb_sdb"
		fi
	fi
	
	clear
	# ----------------------Main panel------------------------- #

	echo
	echo -e """[$blueh $hostname $grey] IP LAN: $yellowb$private_ip$grey
$white╔═══════════════════════════════════════════════════════════════╗
$white║  Main panel\t\t\t\t\t\tLevel: $whiteu$level$white║
$white║                                                               ║
$white║  $textl1║
$white║  $textl5║
$white║                                                               ║
$white║  $textl2║
$white║  $textl3║
$white║  $textl4║
$white║                                                               ║
$white╚═══════════════════════════════════════════════════════════════╝$grey"""

	# -------------------Display all information---------------------------- #

	echo -e "$white Information report:$grey\t\t\t\tOptions:$whiteu Ctrl + C $grey"

	#External devices
	if [ $nb_sdb -ne 0 ] ; then
		echo && echo -e "$whiteh $nb_sdb $white connected device(s)$grey"
		echo -e "$list_devices"
	fi

	#Network
	if [ -z "$private_ip" ] ; then
		textl2="🔒$greenb Connected to no network$white\t\t\t\t\t"
	else
		if [ $cable_state -eq 1 ] ; then
			textl2="🔒$greenb Connected to network via Ethernet$white\t\t\t\t"
		elif [ -z "$wifipass" ] ; then
			echo && echo -e "$whiteh i $white Network connection information$grey"
			echo -e "    └─ESSID: $yellow$essid$grey\tFREQ: $yellow$ap_freq$grey\tKEY: $redh ABSENT $grey"
			textl2="⚠️ $orangeb Connected to the network via Wi-Fi$white\t\t\t"
		elif [ $sizepass -gt 20 ] ; then
			echo && echo -e "$whiteh i $white Network connection information$grey"
			echo -e "    └─ESSID: $yellow$essid$grey\tFREQ: $yellow$ap_freq$grey\tKEY: $greenh SECURE $grey"
			textl2="🔒$greenb Connected to the network via Wi-Fi$white\t\t\t"
		else
			echo && echo -e "$whiteh i $white Network connection information$grey"
			echo -e "    └─ESSID: $yellow$essid$grey\tFREQ: $yellow$ap_freq$grey\tKEY: $orangeh NOT SECURE $grey"
			textl2="⚠️ $orangeb Connected to the network via Wi-Fi$white\t\t\t"
		fi
	fi
	if [ $nb_interfaces -ne 0 ] ; then
		echo && echo -e "$whiteh $nb_interfaces $white interface(s) enabled$grey"
		echo -e "$list_interfaces"
	fi

	#Connections established
	if [ $nb_conn_established -ne 0 ] ; then

		#Display loopback connections
		if [ $display_conn_lo -eq 1 ] ; then
			state_display_conn_lo="$greenb⬤$grey"
		else
			state_display_conn_lo="$redb⬤$grey"
		fi

		case $level in
			1 )
				echo && echo -e "$orangeh $nb_conn_established $grey$orangeb unknown connection(s) in progress$grey\t\t\tDisplay Loopback $state_display_conn_lo"
				textl3="⚠️  $orangeh $nb_conn_established $grey$orangeb unknown connection(s) in progress$white\t\t\t";;
			2 )
				echo && echo -e "$greenh $nb_conn_established $greenb connection(s) in progress$grey\t\t\tDisplay Loopback $state_display_conn_lo"
				textl3="🔒 $greenh $nb_conn_established $greenb connection(s) in progress$white\t\t\t\t";;
			3 ) 
				echo && echo -e "$greenh $nb_conn_established $greenb connection(s) in progress$grey\t\t\tDisplay Loopback $state_display_conn_lo"
				textl3="🔒 $greenh $nb_conn_established $greenb connection(s) in progress$white\t\t\t\t"

				#Display automatically loopback connections when level equal 3
				display_conn_lo=1;;
		esac

		echo -e "┌───────────────────────────────────────────────────────────────────────┐"
		echo -e "│  Local Address\tRemote Address\t\tPID\tProgram Name\t│"
		echo -e "└───────────────────────────────────────────────────────────────────────┘"
		echo -e "$conn_established"
		echo -e "└───────────────────────────────────────────────────────────────────────┘"
	else
		textl3="🔒$greenb No connections in progress$white\t\t\t\t"
	fi

	#Connections listen
	if [ $nb_conn_listen -ne 0 ] ; then
		case $conn_listen_loopback in
			0 ) 
				echo && echo -e "$yellowh $nb_conn_listen $yellowb active service(s)$grey"
				textl4="⚠️  $yellowh $nb_conn_listen $yellowb active service(s)$white\t\t\t\t\t";;

			1 ) 
				echo && echo -e "$greenh $nb_conn_listen $greenb active service(s)$grey"
				textl4="🔒 $greenh $nb_conn_listen $greenb active service(s)$white\t\t\t\t\t";;
		esac

		echo -e "┌───────────────────────────────────────────────┐"
		echo -e "│  Services state 'LISTEN'\t\tPID\t│"
		echo -e "└───────────────────────────────────────────────┘"
		echo -e "$conn_listen"
		echo -e "└───────────────────────────────────────────────┘"
	else
		textl4="🔒$greenb No active service$white\t\t\t\t\t\t"
	fi

	sleep $frequency
done
