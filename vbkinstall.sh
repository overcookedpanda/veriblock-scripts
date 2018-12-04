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
TOTALDISK=$(df -H / | tail -1 | cut -d' ' -f9 | tr -d -c 0-9)
echo Disk Size: $TOTALDISK GB
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
echo "Sorry, but this system needs at least 50GB total diskspace for NodeCore to run.  Exiting Install..."
echo
else
echo "Your system is suitable, continuing installation of NodeCore..."
fi
#
# Install Java:
#
echo "Installing Java if needed..."
sudo apt-get update
sudo apt-get install software-properties-common -qq
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update
sudo apt-get install oracle-java8-installer -qq
sudo apt-get install oracle-java8-set-default -qq
#
# Install Other Dependencies:
#
echo "Installing other dependencies if needed..."
sudo apt-get install jq -qq
sudo apt-get install unzip -qq
#
# Get url for latest nodecore version
#
LATEST_NODECORE=`curl -s https://testnet.explore.veriblock.org/api/stats/download | jq -r .nodecore_all_tar`
LATEST_BOOTSTRAP=`curl -s https://testnet.explore.veriblock.org/api/stats/download | jq -r .bootstrapfile`
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
cd ../bin
chmod +x nodecore
echo "Starting NodeCore..."
./nodecore
