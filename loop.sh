function conn_block(){

	if [ $level -eq 3 ] ; then
		#Do not block loopback connections
		if [ "$3" != "127.0.0.1" ] ; then
			sudo kill $5 1> /dev/null
			echo -e "$current_date :: PID $5 from $6 service was killed, connection state $1:$2 $3:$4" >> $LOG_FILE
			notify-send --urgency normal --expire-time 2500 -i $ICON_PATH "$3:$4 from $6 service was kill"
			#zenity --info --ellipsize --text="$3:$4 from $6 service was kill" & 1> /dev/null
		fi
	elif [ $level -eq 2 ]; then
		#Do not block loopback connections
		if [ "$3" != "127.0.0.1" ] ; then

			authorized_conn=0
			for i in $(cat $AUTH_FILE) ; do
				#If the program name exist inside authorized connections file
				if [ "$6" = "$i" ] ; then
					authorized_conn=1
				fi
			done
			
			#Kill all PID except your exceptions
			if [ "$authorized_conn" != "1" ] ; then
				sudo kill $5 1> /dev/null
				echo -e "$current_date :: PID $5 from $6 service was killed, connection state $1:$2 $3:$4" >> $LOG_FILE
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
	    current_date=$(date "+%d/%m/%Y-%H:%M:%S")
	    malware=$(echo -e "$correct" | grep -e "FOUND" | cut -d ':' -f 1)
	    echo -e "$current_date :: Malware '$malware' detected" >> $LOG_FILE
	    read -p "[?] Virus was found, remove it (Y/n)> " -n 1 -e delete

	    if [[ "$delete" =~ ^[YyOo]$ ]] ; then
	      echo -ne "[+] Remove '$malware' in progress..."
	      sudo rm -rf "$malware"
	      echo -e "$current_date :: Malware '$malware' deleted" >> $LOG_FILE
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
