#!/usr/bin/env bash
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
