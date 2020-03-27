#!/usr/bin/env bash
#
# Automated install script for VeriBlock NodeCore on Ubuntu and CentOS Linux distributions
# This script can be called with -u <url> to download an alternate package, and network can be specified with -n (-n testnet), or defaults to mainnet. You can use the -b flag if you wish to skip downloading the bootstrap and start sync at block 0.
# It should be noted that this script uses the new datadir location of ~/VeriBlock by default, with the calling of NodeCore with `./nodecore -d USER`
#
echo "Some parts of this script require sudo to run such as installing dependencies, please authenticate now..."
if [[ ! $(sudo echo 0) ]]; then exit; fi
BOOTSTRAP_ENABLED=1
NETWORK=mainnet
while getopts ":u:b:n:" opt; do
  case $opt in
    u)
      LATEST_NODECORE="$OPTARG"
      ;;
    b)
      BOOTSTRAP_ENABLED=0
      ;;
    n)
      NETWORK="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1;
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1;
      ;;
  esac
done

function checknetwork {
    if [[ ${NETWORK} == "testnet" || ${NETWORK} == "mainnet" ]]; then
        true
    else
        false
    fi
}
function isinstalledcentos {
    if yum list installed "$@" >/dev/null 2>&1; then
        true
    else
        false
    fi
}
function isinstalledubuntu {
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$@" | grep "install ok installed" | cut -d' ' -f2)
	if [[ "" == "$PKG_OK" ]]; then
	    false
	else
	    true
	fi
}
function distrocheck {
    python -mplatform | grep -qi centos && DISTRO=centos || DISTRO=Ubuntu
    if [[ "$DISTRO" != "centos" ]] && [[ "$DISTRO" != "Ubuntu" ]]; then
        echo "Sorry, this script only supports automated NodeCore install on CentOS or Ubuntu"
        exit
    else
        echo "Current Distribution identified as: $DISTRO"
    fi
}
function installpackage {
 if [[ "$DISTRO" == "centos" ]]; then
    if isinstalledcentos $@; then
        echo "$@: installed";
    else
        echo "$@: not installed, installing package via yum.";
        sudo yum -y install $@
    fi
    elif [[ "$DISTRO" == "Ubuntu" ]]; then
        if isinstalledubuntu $@; then
			echo "$@: installed";
		else
			echo "$@: not installed, installing package via apt.";
            sudo apt-get install $@ -qq
        fi
    else
        echo "Sorry, but this script only supports CentOS or Ubuntu distributions.  Exiting now..."
        exit
fi
}
function repocheck {
 if [[ "$DISTRO" == "centos" ]]; then
    if [ -f "/etc/yum.repos.d/zulu.repo" ]; then
	echo "Zulu yum repo for OpenJDK exists... proceeding...";
    else
	echo "Zulu yum repo is required... installing now...";
	sudo rpm --import http://repos.azulsystems.com/RPM-GPG-KEY-azulsystems;
	sudo curl -s -o /etc/yum.repos.d/zulu.repo http://repos.azulsystems.com/rhel/zulu.repo;
    fi
fi
}
#
# Check that the user has specified mainnet or testnet, or is using default network selection.
#
if checknetwork $@; then
        echo "NodeCore network: ${NETWORK}";
    else
        echo "Sorry, but ${NETWORK} is an invalid network selection.  Exiting now..."
        exit
fi
#
# Check that user has sudo privileges
#
timeout 2 sudo id > /dev/null && sudo="true" || sudo="false"
if $sudo == "true"
then
    echo "Current user has sudo privileges, proceeding..."
elif $sudo == "false"
then
    echo "You need to run this script as a user that has sudo privileges"
    exit
fi
#
# Check that system is either CentOS or Ubuntu so that we can install dependencies and automate NodeCore installation
#
distrocheck
#
# Check system to make sure it can support running NodeCore
#
echo "Checking to see if your system meets the minimum requirements for NodeCore to run..."
TOTALMEM=$(cat /proc/meminfo | head -n 1 | tr -d -c 0-9)
TOTALMEM=$(($TOTALMEM/1000000))
echo System Memory: $TOTALMEM GB
TOTALCORES=$(nproc)
echo System Cores: $TOTALCORES
TOTALDISK=$(df -k . | awk 'NR==2 { print $2/1048576 }')
TOTALDISK=${TOTALDISK/.*}
echo Disk Size: $TOTALDISK GB
FREESPACE=$(df -k . | awk 'NR==2 { print $4/1048576 }')
FREESPACE=${FREESPACE/.*}
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
# Install OpenJDK & other dependencies
#
repocheck
if [[ "$DISTRO" == "centos" ]];
then
    depends=(zulu-11 jq unzip screen python)
    elif [[ "$DISTRO" == "Ubuntu" ]];
    then
        depends=(default-jre jq unzip screen python)
else
    # It should never make it this far, but just in case
    echo "Sorry, this script only supports automated NodeCore install on CentOS or Ubuntu"
    exit
fi

for p in "${depends[@]}"
do
    installpackage ${p};
done
#
# Get url for latest NodeCore version
#
if [ -z "$LATEST_NODECORE" ]
then
    LATEST_NODECORE=`curl -s https://explore.veriblock.org/api/stats/download | jq -r .nodecore_all_tar`
else
    echo "Using url $LATEST_NODECORE for download..."
fi
NODECORE="$(basename $LATEST_NODECORE)"
NC_VERSION=`curl -s https://explore.veriblock.org/api/stats/download | jq -r .nodecore_all_tar | awk -F'v[^0-9]*' '$0=$2' | sed s'/\///g'`
NODECORE_ALL_DIR="$(basename $NODECORE .tar.gz)"
BOOTSTRAP_DOWNLOADER=bootstrap-downloader-${NC_VERSION}/bin/bootstrap-downloader
NODECORE_DIR="$(echo "$NODECORE" | cut -d'-' -f2,4 | cut -d'.' -f1-3)"
#
echo "Creating directory for latest release..."
mkdir -p $NODECORE_ALL_DIR
cd $NODECORE_ALL_DIR
#
# Download latest version of NodeCore & bootstrap
#
# Older version of wget does not allow --show-progress, test if available
#
wgetProgress=""
failurestring="unrecognized option"
wgetout=$(wget --show-progress 2>&1 | head -n 1)
[ "${wgetout#*$failurestring}" != "$wgetout" ] || { wgetProgress="--show-progress"; }
#
echo "Downloading $LATEST_NODECORE..."
wget -q $wgetProgress $LATEST_NODECORE
echo "Extracting $NODECORE..."
tar zxmvf $NODECORE
rm $NODECORE

if [[ "$BOOTSTRAP_ENABLED" == "1" ]];
then
    mkdir -p ~/VeriBlock/${NETWORK}

    if [[ "$NETWORK" == "testnet" ]];
    then
        echo "network=testnet" >> ~/VeriBlock/nodecore.properties
    elif [[ "$NETWORK" == "mainnet" ]];
    then
        echo "network=mainnet" >> ~/VeriBlock/nodecore.properties
    fi
    echo "Downloading latest block files for ${NETWORK}..."
    $BOOTSTRAP_DOWNLOADER -d ~/VeriBlock/ -n ${NETWORK}
    if [ $? -eq 0 ]
    then
        echo "Successfully downloaded block files... continuing."
        cd $NODECORE_DIR/bin
        echo "Starting NodeCore..."
        screen -dmS nodecore bash -c './nodecore -d USER'
        echo "NodeCore started in 'nodecore' screen, type 'screen -r nodecore' to attach..."
    else
        echo "Failed to download block files.. exiting.. please try to run the script again." >&2
        exit 1
    fi
else
cd $NODECORE_DIR/bin
echo "Starting NodeCore..."
screen -dmS nodecore bash -c './nodecore -d USER'
echo "NodeCore started in 'nodecore' screen, type 'screen -r nodecore' to attach..."
fi
