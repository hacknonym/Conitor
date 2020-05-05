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

	#Initialization of the number of files in downloads
	old_nb_file=$(
		c=0
		for i in $(ls -l $DOWNLOAD_PATH | grep -e ":" | awk '{print $1}'); do
			c=$(($c + 1))
		done
		echo -e "$c"
	)

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
