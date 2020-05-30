# Conitor

[![Version](https://img.shields.io/badge/Version-1.0-blue)]()
[![Language](https://img.shields.io/badge/Bash-4.2%2B-brightgreen)]()
[![Available](https://img.shields.io/badge/Available-Linux%20Debian-orange)]()
[![Download](https://img.shields.io/badge/Size-140Ko-brightgreen)]()
[![License](https://img.shields.io/badge/License-GPL%20v3%2B-red)]()

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
- You can allow connections of your choice (add them to the file authorized.txt)
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
![Launch](https://user-images.githubusercontent.com/55319869/79692680-cd3fb180-8266-11ea-83a7-bb344adf7299.png)
![Example](https://user-images.githubusercontent.com/55319869/79692696-d9c40a00-8266-11ea-9082-92f4d73e30ee.png)
![Internal options](https://user-images.githubusercontent.com/55319869/79692715-f6604200-8266-11ea-86a6-a1410c13a6f8.png)
![Listen services](https://user-images.githubusercontent.com/55319869/79692727-08da7b80-8267-11ea-929c-b3c7bb83c004.png)
![Antivirus scan](https://user-images.githubusercontent.com/55319869/79692739-17c12e00-8267-11ea-98ab-9e07a608fa2b.png)

## License
GNU General Public License v3.0 for Conitor
AUTHOR: @hacknonym
