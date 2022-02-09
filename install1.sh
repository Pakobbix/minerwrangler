#!/bin/bash

# created by Nikolai

# Ubuntu server 20.04.2 LTS

# DEFINING ALL THE VARIABLES

#define colors for colored text
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

#define the installation variable, and set it to one
var=1

# define variables for the manufacturer and model of the GPU(s), and hide the command line output
{
  vendor=$(lshw -class display | grep 'vendor' | uniq)
  model=$(lshw -class display | grep 'product')
} &> /dev/null

# DEFINING THE INSTALLATION FUNCTIONS
# define the confirm install function
confirm_install() {
  local REPLY
  while true; do
    read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY])
        echo
        ((var*=2))
        return 0 ;;
      [nN])
        echo
        ((var-=1))
        return 1 ;;
      *)
        echo " ${red}invalid input${reset}"
    esac
  done
}

# define Nvidia installation
nvidia_install() {
  # add the nvidia drivers ppa
  add-apt-repository ppa:graphics-drivers/ppa -y
  apt upgrade -y
  # install all the necessary libraries, will ask config during install
  apt install nvidia-driver-460 nvidia-cuda-toolkit -y
}

IFS=$'\n'
question="Choose your preferred miner Software: "
entrys=("T-Rex Miner" "Phoenix Miner" "Nanominer")

PS3="$question "
select entry in "${entrys[@]}" "Abort"; do

miner_install() {
	if ((REPLY == 1 + ${#entrys[@]})); then
		exit
		break

	elif ((REPLY > 0 && REPLY <= ${#entrys[@]})); then
		if [ "$entry" == "T-Rex Miner" ]; then
			latest=$(curl -s https://github.com/trexminer/T-Rex/releases/latest | sed 's/.*href="\|">.*//g')
			filename=$(curl -s "$latest" | grep -i "linux" | grep -i "text" | sed 's/.*">\|<\/.*//g')
			wget "$(echo "$latest" | sed 's/tag/download/g')/$filename"
      mkdir T-Rex && tar -zxvf $filename -C T-Rex
		elif [ "$entry" == "Phoenix Miner" ]; then
			dllink=$(curl -s https://phoenixminer.org/download/latest/ | grep "Linux" | grep "cutt" | sed 's/.*href="\|"\ rel.*//g' | head -n 1)
			wget -r -p -k "$dllink"
      cd cutt.ly/
      mv * phoenixminer.zip
      unzip phoenixminer.zip
		elif [ "$entry" == "Nanominer" ]; then
			latest=$(curl -s https://github.com/nanopool/nanominer/releases/latest | sed 's/.*href="\|">.*//g')
			filename=$(curl -s "$latest" | grep 'linux-[0-9].[0-9].[0-99]-cuda' | grep -i "text" | sed 's/.*">\|<\/.*//g')
			wget "$(echo "$latest" | sed 's/tag/download/g')/$filename"
      tar -xvf "$filename"
      mv nanominer*/ nanominer
		fi
	fi
	break
done
}

# ETHlargementPill installation for GTX 1080, 1080TI and Titan XP
pill_install() {
  # Download
  wget https://github.com/admin-ipfs/OhGodAnETHlargementPill/raw/master/OhGodAnETHlargementPill-r2
  # Make the file executable, and rename it
  chmod +x OhGodAnETHlargementPill-r2
  mv OhGodAnETHlargementPill-r2 ETHPill
}

# THE CONDITIONAL INSTALLATON CODE
clear
if [[ $vendor =~ "NVIDIA" ]]; then
  echo -e "${green}NVIDIA GPUs detected${reset}" "\U2714"
elif [[ $vendor =~ "AMD" ]]; then
  echo "${red}AMD GPUs are not yet supported${reset}"
  echo "exiting in 5 seconds"
  sleep 5
  exit 0
else
  echo "${red}No GPUs detected${reset}"
  echo "exiting in 5 seconds"
  sleep 5
  exit 0
fi
echo "$model"

# setup questions
confirm_install "Is this the correct hardware?" || exit 0
clear
printf "\U1F48A" && confirm_install "The pill? (GTX 1080, 1080Ti & Titan XP)"
clear

# update and upgrade packages to the latest version
apt update && apt upgrade -y
# just such a useful tool, should be installed regardless of option
apt install screen -y
# allow ssh through firewall, and enable firewall for security purposes
ufw allow ssh
yes | ufw enable

# installation
if [[ $vendor =~ "NVIDIA" ]]; then
  nvidia_install
  miner_install
  if [[ $var = 4 ]]; then
    pill_install
  fi
else
  exit 0
fi

# REBOOT SYSTEM AND GET READY TO MINE
# make the next install script executable, while removing permissions for the current one
chmod 0 install1.sh
chmod +x install2.sh
clear
# display a message, then reboot
echo "${red}Rebooting ...${reset}"
sleep 2
reboot
