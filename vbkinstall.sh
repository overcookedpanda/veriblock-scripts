#!/usr/bin/env bash
#
# Check system to make sure it can support running NodeCore
#
echo "Checking to see if your system meets the minimum requirements for NodeCore to run..."
TOTALMEM=$(cat /proc/meminfo | head -n 1 | tr -d -c 0-9)
TOTALMEM=$(($TOTALMEM/1000000))
echo System Memory: $TOTALMEM GB
TOTALCORES=$(nproc)
echo System Cores: $TOTALCORES
TOTALDISK=$(df -H "$HOME" | awk 'NR==2 { print $2 }' | tr -d -c 0-9)
echo Disk Size: $TOTALDISK GB
FREESPACE=$(df -H "$HOME" | awk 'NR==2 { print $2 }' | tr -d -c 0-9)
echo Free Disk Space: $FREESPACE GB
if [ $TOTALMEM -lt 4 ]
then
    echo "Sorry, but this system needs at least 4GB of RAM for NodeCore to run.  Exiting Install..."
    exit
elif [ $TOTALCORES -lt 2 ]
then
    echo "Sorry, but this system needs at least 2 cores for NodeCore to run.  Exiting Install..."
    exit
elif [ $TOTALDISK -lt 50 ]
then
    echo "Sorry, but this system needs at least 50GB total disk space for NodeCore to run.  Exiting Install..."
    exit
elif [ $FREESPACE -lt 15 ]
then
    echo "Sorry, but this system needs at least 15GB free disk space for NodeCore to run.  Exiting Install..."
    exit
else
    echo "Your system is suitable, continuing installation of NodeCore..."
fi
#
# Install Java:
#
echo "Installing Java if needed..."
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' software-properties-common | grep "install ok installed" | cut -d' ' -f2)
echo Checking for software-properties-common: $PKG_OK
if [ "" == "$PKG_OK" ]; then
    echo "No software-properties-common. Setting up software-properties-common."
    sudo apt-get update
    sudo apt-get install software-properties-common -qq
fi
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' oracle-java8-installer | grep "install ok installed" | cut -d' ' -f2)
echo Checking for oracle-java8-installer: $PKG_OK
if [ "" == "$PKG_OK" ]; then
    echo "No oracle-java8-installer. Setting up oracle-java8-installer."
    if ! grep -q "ppa:webupd8team/java" /etc/apt/sources.list; then
        echo "Adding repo for Java installation..."
        sudo add-apt-repository ppa:webupd8team/java -y
    fi
    sudo apt-get update
    sudo apt-get install oracle-java8-installer -qq
fi
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' oracle-java8-set-default|grep "install ok installed" | cut -d' ' -f2)
echo Checking for oracle-java8-set-default: $PKG_OK
if [ "" == "$PKG_OK" ]; then
    echo "No oracle-java8-set-default. Setting up oracle-java8-set-default."
    sudo apt-get install oracle-java8-set-default -qq
fi
#
# Install Other Dependencies:
#
echo "Installing other dependencies if needed..."
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' jq | grep "install ok installed" | cut -d' ' -f2)
echo Checking for jq: $PKG_OK
if [ "" == "$PKG_OK" ]; then
    echo "No jq. Setting up jq."
    sudo apt-get install jq -qq
fi
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' unzip | grep "install ok installed" | cut -d' ' -f2)
echo Checking for unzip: $PKG_OK
if [ "" == "$PKG_OK" ]; then
    echo "No unzip. Setting up unzip."
    sudo apt-get install unzip -qq
fi
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' screen | grep "install ok installed" | cut -d' ' -f2)
echo Checking for screen: $PKG_OK
if [ "" == "$PKG_OK" ]; then
    echo "No screen. Setting up screen."
    sudo apt-get install screen -qq
fi
#
# Get url for latest nodecore version
#
LATEST_NODECORE=`curl -s https://testnet.explore.veriblock.org/api/stats/download | jq -r .nodecore_all_tar`
LATEST_BOOTSTRAP=`curl -s https://testnet.explore.veriblock.org/api/stats/download | jq -r .bootstrapfile_zip`
NODECORE="$(cut -d'/' -f9 <<<$LATEST_NODECORE)"
BOOTSTRAP="$(cut -d'/' -f4 <<<$LATEST_BOOTSTRAP)"
NODECORE_ALL_DIR="$(echo "$NODECORE" | cut -d'.' -f1-3)"
NODECORE_DIR="$(echo "$NODECORE" | cut -d'-' -f2,4 | cut -d'.' -f1-3)"
#
echo "Creating directory for latest release..."
mkdir $NODECORE_ALL_DIR
cd $NODECORE_ALL_DIR
#
# Download latest version of nodecore & bootstrap
#
echo "Downloading $LATEST_NODECORE..."
wget -q --show-progress $LATEST_NODECORE
echo "Extracting $NODECORE..."
tar xvf $NODECORE
cd $NODECORE_DIR
mkdir testnet
cd testnet
echo "Downloading $LATEST_BOOTSTRAP..."
wget -q --show-progress $LATEST_BOOTSTRAP
echo "Extracting $BOOTSTRAP for fast sync..."
unzip $BOOTSTRAP
echo "Removing $BOOTSTRAP..."
rm $BOOTSTRAP
cd ../bin
chmod +x nodecore
echo "Starting NodeCore..."
screen -S nodecore ./nodecore
