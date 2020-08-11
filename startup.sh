function user_privs(){
	if [ $EUID -eq 0 ] ; then
		echo -n
	else
		echo -e "[x] You do not have root privileges"
  		exit 0
	fi
}

function shortcut(){
	which conitor 1> /dev/null 2>&1 || { 
		echo -ne "$blueb[?]$grey Do you want to create a shortcut for conitor in your system (Y/n)"
		read -p "> " -n 1 -e option
		if [[ "$option" =~ ^[YyOo]$ ]] ; then
			#echo -e "alias conitor=\"cd $MAIN_PATH && ./conitor.sh\"" >> ~/.bashrc
			rm -f /usr/local/sbin/conitor
			touch /usr/local/sbin/conitor
			echo -e "#!/bin/bash" > /usr/local/sbin/conitor
			echo -e "cd $MAIN_PATH && sudo ./conitor.sh \$1 \$2 \$3" >> /usr/local/sbin/conitor
			cp "$MAIN_PATH/config/Conitor.desktop" $APP_PATH
			cp "$MAIN_PATH/icons/Conitor.ico" $ICON_PATH
			sudo chmod +x /usr/local/sbin/conitor
			echo -e "$yellowb[i]$grey Used the shortcut$yellow conitor$grey"
		fi
	}
}

function verify_prog(){
	which $1 1> /dev/null 2>&1 || { 
    	echo -e "$grey[x] $1$yellow not installed$grey"
    	echo -ne "$greenb[+]$grey Installation of $yellow$1$grey in progress..."
    	sudo apt-get install -y $2 1> /dev/null
    	echo -e "$green OK$grey";
    }
}

function update(){
	echo -ne "$blueb[?]$grey Make update (Y/n)"
	read -p "> " -n 1 -e make_update
	if [[ "$make_update" =~ ^[YyOo]$ ]] ; then
		echo -e "$greenb[+]$grey Update in progres..."
		sudo apt-get update 1> /dev/null
		echo -e "$greenb[+]$grey Upgrade clamav.."
		sudo /usr/bin/freshclam 1> /dev/null
	fi
}

function launch(){
	user_privs
	shortcut
	verify_prog "netstat" "net-tools"
	verify_prog "clamscan" "clamav"
	verify_prog "xterm" "xterm"
	verify_prog "zenity" "zenity"

	default_lang="EN"
	echo -ne "$blueb[?]$grey Language (EN/FR/ES/DE/IT)"
	read -p "> " -n 2 -e lang
	lang="${lang:-${default_lang}}"
	foldername=$(cat $MAIN_PATH/lang.txt | grep -ie "$lang" | cut -d ' ' -f 2)
	DOWNLOAD_PATH="$HOME/$foldername"

	#Initialization of the number of files in downloads
	old_nb_file=$(
		c=0
		for i in $(ls -1 $DOWNLOAD_PATH | tr ' ' '_'); do
			c=$(($c + 1))
		done
		echo -e "$c"
	)

	default_frequency="0.1"
	loop_frequency

	#level defaul -> "No restrictions"
	default_level=1
	echo
	echo -e "Specify the desired level  default($yellow$default_level$grey)"
	program_level

	#Downloads Antivirus
	default_enable_downloads_analysis=1
	antivirus_downloads
	
	#External devices Antivirus
	default_enable_sdb_analysis=1
	antivirus_external_devices
	
	#Display loopback connections
	default_display_conn_lo=0
	display_loopback_conn

	#Display LOG file
	display_log_file

	#Update & Upgrade
	update
}
