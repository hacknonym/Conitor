# Conitor

[![Version](https://img.shields.io/badge/Version-1.0-blue.svg?style=for-the-badge)]()
[![Language](https://img.shields.io/badge/Bash-4.2%2B-brightgreen.svg?style=for-the-badge)]()
[![Available](https://img.shields.io/badge/Available-Debian-orange.svg?style=for-the-badge)]()
[![Download](https://img.shields.io/badge/Size-140Ko-brightgreen.svg?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-GPL%20v3%2B-red.svg?style=for-the-badge)](https://github.com/hacknonym/Conitor/blob/master/LICENSE)

### Author: github.com/hacknonym

##  A Security Monitor

![Banner](https://user-images.githubusercontent.com/55319869/79692588-468ad480-8266-11ea-9a54-7ae68bea19b0.PNG)

**Conitor** is a network security monitor. #conitor #security

## Features !
- Has **3 levels** of security
	* No restrictions
	* Block connections except Loopback, and your exceptions
	* Block connections except Loopback
- Kill the process in real time if the connection is not authorized
- You can allow connections of your choice (add them to the file **authorized.txt**)
- You can change the level at any time
- Automatic antivirus scan of downloaded files
- Automatic antivirus scan of connected external devices
- Notify you in case of detection via a popup
- Indicates the status and information of the current network
- Indicates the status and information of current open services

## Advice
Launch it at startup

## Installation
Necessary to have root rights
```bash
git clone https://github.com/hacknonym/Conitor.git
cd Conitor
sudo chmod +x conitor.sh
sudo ./conitor.sh
```
### Usage 
```bash
cd Conitor
sudo ./conitor.sh
```

## Tools Overview
![Launch](https://user-images.githubusercontent.com/55319869/87787189-82b8db80-c83b-11ea-91ab-3cd58557ccaf.png)
![Example](https://user-images.githubusercontent.com/55319869/87787194-851b3580-c83b-11ea-9db4-2209c42dc89e.png)
![Internal options](https://user-images.githubusercontent.com/55319869/87787199-877d8f80-c83b-11ea-9217-35015d943b6e.png)
![Listen services](https://user-images.githubusercontent.com/55319869/87787211-8c424380-c83b-11ea-82bb-f3115842dcc8.png)
![Antivirus scan](https://user-images.githubusercontent.com/55319869/79692739-17c12e00-8267-11ea-98ab-9e07a608fa2b.png)

## License
GNU General Public License v3.0 for Conitor
AUTHOR: @hacknonym
