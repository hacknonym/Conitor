function quit(){
	echo -ne "$blueb[?]$grey Quit (Y/n)"
	read -p "> " -n 1 -e quit_prog
	if [[ "$quit_prog" =~ ^[YyOo]$ ]] ; then
		exit 0
	fi
}

function kill_pid(){
	echo -ne "$blueb[?]$grey Kill a process (Y/n)"
	read -p "> " -n 1 -e kill_proc
	if [[ "$kill_proc" =~ ^[YyOo]$ ]] ; then
		echo -ne "$blueb[?]$grey Specify the PID"
		read -p "> " pidnum
		if [ ! -z $pidnum ] ; then
			sudo kill $pidnum 1> /dev/null
			echo -e "$greenb[+]$grey PID $pidnum was killed"
		else
			echo -e "$redb[x]$grey Error input is empty"
		fi
	fi
}

function program_level(){
	echo -e " $white[1]$grey : No restrictions"
	echo -e " $white[2]$grey : Block all except Loopback, and your exceptions"
	echo -e " $white[3]$grey : Block all except Loopback"
	echo
	read -p "(1/2/3)> " -n 1 -e level
	level="${level:-${default_level}}"
	echo
}

function loop_frequency(){
	echo -ne "$blueb[?]$grey Frequency current($yellow$default_frequency$grey s)"
	read -p "> " frequency
	frequency="${frequency:-${default_frequency}}"
}

function antivirus_downloads(){
	echo -ne "$blueb[?]$grey Enable Downloads folder protection (0/1) current($yellow$default_enable_downloads_analysis$grey)"
	read -p "> " -n 1 -e enable_downloads_analysis
	enable_downloads_analysis="${enable_downloads_analysis:-${default_enable_downloads_analysis}}"
}

function antivirus_external_devices(){
	echo -ne "$blueb[?]$grey Enable External devices protection (0/1) current($yellow$default_enable_sdb_analysis$grey)"
	read -p "> " -n 1 -e enable_sdb_analysis
	enable_sdb_analysis="${enable_sdb_analysis:-${default_enable_sdb_analysis}}"
}

function display_log_file(){
	echo -ne "$blueb[?]$grey Display log file (Y/n)"
	read -p "> " -n 1 -e display_log
	if [[ "$display_log" =~ ^[YyOo]$ ]] ; then
		xterm -fa monaco -fs 10 -T "LOG" -geometry "110x30" -bg black -fg grey -e "tail -f $LOG_FILE" & 1> /dev/null
	fi
}

function display_loopback_conn(){
	echo -ne "$blueb[?]$grey Display loopback connection (0/1) current($yellow$default_display_conn_lo$grey)"
	read -p "> " -n 1 -e display_conn_lo
	display_conn_lo="${display_conn_lo:-${default_display_conn_lo}}"
}

function add_authorized_connection(){
	echo -ne "$blueb[?]$grey Authorize a connection (Y/n)"
	read -p "> " -n 1 -e auth_conn
	if [[ "$auth_conn" =~ ^[YyOo]$ ]] ; then
		echo -ne "$blueb[?]$grey Specify the name of the program to be authorized"
		read -p "> " prog_name
		if [ ! -z $prog_name ] ; then
			echo -e "$prog_name" >> "$AUTH_FILE"
			echo -e "$greenb[+]$grey $prog_name add in authorized programs '$AUTH_FILE'"
		else
			echo -e "$redb[x]$grey Error input is empty"
		fi
	fi
}

function del_authorized_connection(){
	echo -ne "$blueb[?]$grey Remove an authorized connection (Y/n)"
	read -p "> " -n 1 -e rm_auth_conn
	if [[ "$rm_auth_conn" =~ ^[YyOo]$ ]] ; then
		for i in $(cat $AUTH_FILE | tr ' ' '_') ; do
			echo -e " -  $white$i$grey" | tr '_' ' '
		done
		echo -ne "$blueb[?]$grey Specify the name of the program to be unauthorized"
		read -p "> " prog_name
		if [ ! -z $prog_name ] ; then
			content=$(cat "$AUTH_FILE" | grep -v "$prog_name")
			echo -e "$content" > "$AUTH_FILE"
			echo -e "$greenb[+]$grey $prog_name has been removed from authorized connections"
		else
			echo -e "$redb[x]$grey Error input is empty"
		fi
	fi
}

function options(){
	echo

	quit

	default_frequency="$frequency"
	loop_frequency

	default_level="$level"
	echo -ne "$blueb[?]$grey Modify the level current($yellow$default_level$grey)"
	read -p " (Y/n)> " -n 1 -e modify_level
	if [[ "$modify_level" =~ ^[YyOo]$ ]] ; then
		echo
		echo -e "Specify the desired level"
		program_level
	fi

	kill_pid

	default_enable_downloads_analysis="$enable_downloads_analysis"
	antivirus_downloads

	default_enable_sdb_analysis="$enable_sdb_analysis"
	antivirus_external_devices

	add_authorized_connection
	del_authorized_connection

	default_display_conn_lo="$display_conn_lo"
	display_loopback_conn
	
	display_log_file
}
