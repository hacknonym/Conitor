#!/bin/bash
#coding:utf-8
#title:conitor.sh
#author:hacknonym
#launch:./conitor.sh   |or|   bash conitor.sh   |or|   . conitor.sh

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
LOG_FILE="$MAIN_PATH/conitor.log"
#LOG_FILE="/var/log/conitor/conitor.log"
APP_PATH="/usr/share/applications/Conitor.desktop"
ICON_PATH="/usr/share/icons/Conitor.ico"
NETSTAT=$(which netstat)

touch $LOG_FILE



state=1        #popup 'New Connections'
cable_state=0  #Network

#Downloads
old_nb_file=$(
	c=0
	for i in $(ls -l $DOWNLOAD_PATH | grep -e ":" | awk '{print $1}'); do
		c=$(($c + 1))
	done
	echo -e "$c"
)

#External devices
old_nb_sdb=$(
	c=0
	for i in $(ls /dev | grep -Eo "sd[b-z][1-9]|sd[b-z][1-9][1-9]|sd[b-z][1-9][1-9][1-9]|sd[a-z][a-z][1-9]|sd[a-z][a-z][1-9][1-9]|sd[a-z][a-z][1-9][1-9][1-9]|sd[a-z][a-z][a-z][1-9]|sd[a-z][a-z][a-z][1-9][1-9]|sd[a-z][a-z][a-z][1-9][1-9][1-9]") ; do
		c=$(($c + 1))
	done
	echo -e "$c"
)

function options_quit(){
	echo
	#Quit the program
	read -p "[?] Quit (Y/n)> " -n 1 -e quit_prog
	if [[ "$quit_prog" =~ ^[YyOo]$ ]] ; then
		exit 1
	fi

	#Loop frequency
	default_frequency="$frequency"
	echo -ne "[?] Frequency current($yellow$default_frequency$grey s)"
	read -p "> " frequency
	frequency="${frequency:-${default_frequency}}"

	#Kill a PID
	read -p "[?] Kill a process (Y/n)> " -n 1 -e kill_proc
	if [[ "$kill_proc" =~ ^[YyOo]$ ]] ; then
		read -p "[?] Specify the PID > " pidnum
		sudo kill $pidnum 1> /dev/null
	fi

	#Program level
	default_level="$level"
	echo -ne "[?] Modify the level current($yellow$default_level$grey)"
	read -p " (Y/n)> " -n 1 -e modify_level
	if [[ "$modify_level" =~ ^[YyOo]$ ]] ; then
		echo
		echo -e "Specify the desired level"
		echo -e " [1] : No restrictions"
		echo -e " [2] : Block connections except Loopback, Firefox-ESR and Tor"
		echo -e " [3] : Block connections except Loopback"
		echo
		read -p "(1/2/3)> " -n 1 -e level
		level="${level:-${default_level}}"
		echo
	fi

	#Downloads Antivirus
	default_enable_downloads_analysis="$enable_downloads_analysis"
	echo -ne "[?] Enable Downloads folder protection (0/1) current($yellow$default_enable_downloads_analysis$grey)"
	read -p "> " -n 1 -e enable_downloads_analysis
	enable_downloads_analysis="${enable_downloads_analysis:-${default_enable_downloads_analysis}}"

	#External devices Antivirus
	default_enable_sdb_analysis="$enable_sdb_analysis"
	echo -ne "[?] Enable External devices protection (0/1) current($yellow$default_enable_sdb_analysis$grey)"
	read -p "> " -n 1 -e enable_sdb_analysis
	enable_sdb_analysis="${enable_sdb_analysis:-${default_enable_sdb_analysis}}"

	#Display loopback connections
	default_display_conn_lo="$display_conn_lo"
	echo -ne "[?] Display loopback connection (0/1) current($yellow$default_display_conn_lo$grey)"
	read -p "> " -n 1 -e display_conn_lo
	display_conn_lo="${display_conn_lo:-${default_display_conn_lo}}"

	#Display LOG file
	read -p "[?] Display log file (Y/n)> " -n 1 -e display_log
	if [[ "$display_log" =~ ^[YyOo]$ ]] ; then
		xterm -fa monaco -fs 10 -T "LOG" -geometry "110x30" -bg black -fg grey -e "tail -f $LOG_FILE" & 1> /dev/null
	fi
}

trap options_quit INT

# ---------------------Functions used at startup-------------------------- #

function user_privs(){
	if [ $EUID -eq 0 ] ; then
		echo -n
	else
		echo -e "[x] You do not have root privileges"
  		exit 1
	fi
}

function shortcut(){
	which conitor 1> /dev/null 2>&1 || { 
		read -p "[?] Do you want to create a shortcut for conitor in your system (Y/n)> " -n 1 -e option
		if [[ "$option" =~ ^[YyOo]$ ]] ; then
			#echo -e "alias conitor=\"cd $MAIN_PATH && ./conitor.sh\"" >> ~/.bashrc
			rm -f /usr/local/sbin/conitor
			touch /usr/local/sbin/conitor
			echo "#!/bin/bash" > /usr/local/sbin/conitor
			echo "cd $MAIN_PATH && ./conitor.sh \$1 \$2 \$3" >> /usr/local/sbin/conitor
			cp "$MAIN_PATH/config/Conitor.desktop" $APP_PATH
			cp "$MAIN_PATH/icons/Conitor.ico" $ICON_PATH
			sudo chmod +x /usr/local/sbin/conitor
			echo -e "[+] Used the shortcut$yellow conitor$grey"
		fi
	}
}

function verify_prog(){
	which $1 1> /dev/null 2>&1 || { 
    	echo -e "$grey[x] $1$yellow not installed$grey"
    	echo -ne "[+] Installation of $yellow$1$grey in progress..."
    	sudo apt-get install -y $2 1> /dev/null
    	echo -e "$green OK$grey";
    }
}

function launch(){
	user_privs
	shortcut
	verify_prog "netstat" "net-tools"
	verify_prog "clamscan" "clamav"
	verify_prog "xterm" "xterm"
	verify_prog "zenity" "zenity"

	default_lang="EN"
	read -p "[?] Language (EN/FR/ES/DE/IT)> " -n 2 -e lang
	lang="${lang:-${default_lang}}"
	foldername=$(cat $MAIN_PATH/lang.txt | grep -ie "$lang" | cut -d ' ' -f 2)
	DOWNLOAD_PATH="$HOME/$foldername"

	default_frequency="0.1"
	echo -ne "[?] Frequency default($yellow$default_frequency$grey s)"
	read -p "> " frequency
	frequency="${frequency:-${default_frequency}}"

	#level defaul -> "No restrictions"
	default_level=1
	echo
	echo -e "Specify the desired level  default($yellow$default_level$grey)"
	echo -e " [1] : No restrictions"
	echo -e " [2] : Block connections except Loopback, Firefox-ESR and Tor"
	echo -e " [3] : Block connections except Loopback"
	echo
	read -p "(1/2/3)> " -n 1 -e level
	level="${level:-${default_level}}"
	echo

	#Downloads Antivirus
	default_enable_downloads_analysis=1
	echo -ne "[?] Enable Downloads folder protection (0/1) default($yellow$default_enable_downloads_analysis$grey)"
	read -p "> " -n 1 -e enable_downloads_analysis
	enable_downloads_analysis="${enable_downloads_analysis:-${default_enable_downloads_analysis}}"

	#External devices Antivirus
	default_enable_sdb_analysis=1
	echo -ne "[?] Enable External devices protection (0/1) default($yellow$default_enable_sdb_analysis$grey)"
	read -p "> " -n 1 -e enable_sdb_analysis
	enable_sdb_analysis="${enable_sdb_analysis:-${default_enable_sdb_analysis}}"

	#Display loopback connections
	default_display_conn_lo=0
	echo -ne "[?] Display loopback connection (0/1) default($yellow$default_display_conn_lo$grey)"
	read -p "> " -n 1 -e display_conn_lo
	display_conn_lo="${display_conn_lo:-${default_display_conn_lo}}"

	#Display LOG file
	read -p "[?] Display log file (Y/n)> " -n 1 -e display_log
	if [[ "$display_log" =~ ^[YyOo]$ ]] ; then
		xterm -fa monaco -fs 10 -T "LOG" -geometry "110x30" -bg black -fg grey -e "tail -f $LOG_FILE" & 1> /dev/null
	fi

	#Update & Upgrade
	read -p "[?] Make update (Y/n)> " -n 1 -e make_update
	if [[ "$make_update" =~ ^[YyOo]$ ]] ; then
		echo -e "[+] Update in progres..."
		sudo apt-get update 1> /dev/null
		echo -e "[*] Upgrade clamav.."
		sudo /usr/bin/freshclam 1> /dev/null
	fi
}

launch

# --------------------Functions use in the loop--------------------------- #

function conn_block(){

	if [ $level -eq 3 ]; then
		#Do not block loopback connections
		if [ "$3" != "127.0.0.1" ] ; then
			sudo kill $5 1> /dev/null
			echo "$current_date :: PID $5 from $6 service was killed, connection state $1:$2 $3:$4" >> $LOG_FILE
			notify-send --urgency normal --expire-time 2500 -i $ICON_PATH "$3:$4 from $6 service was kill"
			#zenity --info --ellipsize --text="$3:$4 from $6 service was kill" & 1> /dev/null
		fi
	elif [ $level -eq 2 ]; then
		#Do not block loopback connections
		if [ "$3" != "127.0.0.1" ] ; then

			#Kill all PID except Firefox-esr, Tor, :9050, :9150, :9151 <- Tor Browser
			if [ "$6" != "firefox-esr" -a "$6" != "tor" -a "$4" != "9050" -a "$4" != "9150" -a "$4" != "9151" ] ; then
				sudo kill $5 1> /dev/null
				echo "$current_date :: PID $5 from $6 service was killed, connection state $1:$2 $3:$4" >> $LOG_FILE
				notify-send --urgency normal --expire-time 2500 -i $ICON_PATH "$3:$4 from $6 service was killed"
			fi
		fi
	fi
}

function antivirus(){
	white='\e[0;37;1m'
	grey='\e[0;37m'
	redb='\e[0;31;1m'
	yellow='\e[0;33m'

	MAIN_PATH=$(pwd)
	LOG_FILE="$MAIN_PATH/conitor.log"
	DOWNLOAD_PATH="$HOME/$foldername"

	echo -e "Scanning $yellow$1$grey in progress..."

	for i in $(clamscan -r -i "$1" | tr ' ' 'µ') ; do
	  correct=$(echo -e "$i" | tr 'µ' ' ')

	  if echo -e "$correct" | grep -e "FOUND" 1> /dev/null ; then
	    echo -e "[!] Virus FOUND  $redb$correct$grey"
	    current_date=$(date "+%d-%m-%Y %H:%M:%S")
	    malware=$(echo -e "$correct" | grep -e "FOUND" | cut -d ':' -f 1)
	    echo "$current_date :: Malware '$malware' detected" >> $LOG_FILE
	    read -p "[?] Virus was found, remove it (Y/n)> " -n 1 -e delete

	    if [[ "$delete" =~ ^[YyOo]$ ]] ; then
	      echo -ne "[+] Remove '$malware' in progress..."
	      sudo rm -rf "$malware"
	      echo "$current_date :: Malware '$malware' deleted" >> $LOG_FILE
	      echo -e " OK" && echo
	    else
	      echo
	    fi

	  else
	   echo -e "$correct"
	  fi
	done

	#read enter
}

resize -s 36 86 1> /dev/null

while [ true ] ; do

	# ----------------------Variables and operations used for display------------------------- #

	#System
	current_date=$(date "+%d-%m-%Y %H:%M:%S")
	hostname=$(uname -n)

	#Network
	private_ip=$(hostname -I)
	essid=$(iwgetid --raw)
	ap_freq=$(iwgetid --freq | cut -d ':' -f 2)
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
			echo -e "[+] Interface $white$c$grey: $yellow$i$grey"
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
	  			echo -e "[+]  $yellow$lhost$grey:$green$lport$grey\t\t$yellow$rhost$grey:$green$rport$grey    \t$pid\t$progname\t│"
	  		
	  		#Display loopback connection if '$display_conn_lo' = 1
	  		elif [ "$rhost" = "127.0.0.1" -a $display_conn_lo -eq 1 ] ; then
	  			echo -e "[+]  $yellow$lhost$grey:$green$lport$grey\t\t$yellow$rhost$grey:$green$rport$grey    \t$pid\t$progname\t│"
	  		fi
	    done
    )

    #Popup 'New Connections'
	if [ $nb_conn_established -ne 0 -a $state -eq 1 ] ; then
		state=0
		notify-send --urgency normal --expire-time 2500 -i $ICON_PATH "New Connections"
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
    conn_listen_loopback=$(
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
		echo -e "$conn_listen_loopback"
    )
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
		    echo -e "[+]  $white$progname$grey\tlisten on port $orange$lport$grey\t$pid\t│"
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
		for i in $(ls -lt /media/$USERNAME/ | cut -d '.' -f 2 | cut -c 11- | grep -v ":" | tr ' ' 'µ') ; do
			c=$(($c+1))
			correct=$(echo -e "$i" | tr 'µ' ' ')
			echo -e "[+] Device $white$c$grey: $yellow$correct$grey"
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
			sleep 0.5
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
		else
			echo && echo -e "$whiteh i $white Network connection information$grey"
			echo -e "[+] ESSID: $yellow$essid$grey\tFREQ: $yellow$ap_freq$grey"
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
				echo && echo -e "$orangeh $nb_conn_established $grey$orangeb unknown connection(s) in progress$grey\t\t\t\tDisplay Loopback $state_display_conn_lo"
				textl3="⚠️  $orangeh $nb_conn_established $grey$orangeb unknown connection(s) in progress$white\t\t\t";;
			2 | 3 )
				echo && echo -e "$greenh $nb_conn_established $greenb connection(s) in progress$grey\t\t\t\tDisplay Loopback $state_display_conn_lo"
				textl3="🔒 $greenh $nb_conn_established $greenb connection(s) in progress$white\t\t\t\t";;
		esac

		echo -e "────────────────────────────────────────────────────────────────────────────────┐"
		echo -e "     Local Address\t\tRemote Address\t\tPID\tProgram Name\t│"
		echo -e "────────────────────────────────────────────────────────────────────────────────┘"
		echo -e "$conn_established"
		echo -e "────────────────────────────────────────────────────────────────────────────────┘"
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

		echo -e "────────────────────────────────────────────────┐"
		echo -e "     Services state 'LISTEN'\t\tPID\t│"
		echo -e "────────────────────────────────────────────────┘"
		echo -e "$conn_listen"
		echo -e "────────────────────────────────────────────────┘"
	else
		textl4="🔒$greenb No active service$white\t\t\t\t\t\t"
	fi

	sleep $frequency
done
