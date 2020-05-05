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

	#Un/Authorized a new program name if level equal 2
	if [ $level -eq 2 ] ; then
		read -p "[?] Authorize a connection (Y/n)> " -n 1 -e auth_conn
		if [[ "$auth_conn" =~ ^[YyOo]$ ]] ; then
			add_authorized_connection
		fi
		read -p "[?] Remove an authorized connection (Y/n)> " -n 1 -e rm_auth_conn
		if [[ "$rm_auth_conn" =~ ^[YyOo]$ ]] ; then
			del_authorized_connection
		fi
	fi

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

function add_authorized_connection(){
	read -p "[?] Specify the name of the program to be authorized > " prog_name
	if [ ! -z $prog_name ] ; then
		echo "$prog_name" >> "$AUTH_FILE"
		echo -e "[+] $prog_name add in authorized programs '$AUTH_FILE'"
	else
		echo -e "[x] Error input is empty"
	fi
}

function del_authorized_connection(){
	read -p "[?] Specify the name of the program to be unauthorized > " prog_name
	if [ ! -z $prog_name ] ; then
		content=$(cat "$AUTH_FILE" | grep -v "$prog_name")
		echo "$content" > "$AUTH_FILE"
		echo -e "[+] $prog_name has been removed from authorized connections"
	else
		echo -e "[x] Error input is empty"
	fi
}
