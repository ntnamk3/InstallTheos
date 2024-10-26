#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!"
   exit 1
fi

set -euo pipefail

# Function to add a line to ~/.profile if it doesn't exist
add_to_profile() {
    grep -qxF "$1" ~/.profile || echo "$1" >> ~/.profile
}

# Add THEOS export if it doesn't exist
add_to_profile 'export THEOS=/opt/theos'

# Add umask check if it doesn't exist
if ! grep -q "if \[\[ \"\$(umask)\" = \"0000\" \]\]; then" ~/.profile; then
    echo 'if [[ "$(umask)" = "0000" ]]; then' >> ~/.profile
    echo '  umask 0022' >> ~/.profile
    echo 'fi' >> ~/.profile
fi

# Source the profile to apply changes
source ~/.profile

# Install required packages
yum install -y epel-release
yum install -y clang git perl unzip fakeroot build-essential wget

# Set THEOS path and clean previous installations
sudo rm -rf $THEOS
LLVM_VERSION=${1:-16}

# Download and install the latest LLVM toolchain for CentOS
curl -LO https://github.com/sbingner/llvm-project/releases/download/v16.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma
TMP=$(mktemp -d)
echo $TMP
tar --lzma -xf linux-ios-arm64e-clang-toolchain.tar.lzma -C $TMP
sudo mkdir -p $THEOS/toolchain/linux/iphone
sudo mv $TMP/ios-arm64e-clang-toolchain/* $THEOS/toolchain/linux/iphone/
rm -rf $TMP linux-ios-arm64e-clang-toolchain.tar.lzma

# Clone Theos repository
sudo git clone --recursive https://github.com/theos/theos.git $THEOS
sudo rm -rf $THEOS/toolchain*

# Download iOS SDKs
cd $HOME
wget https://github.com/xybp888/iOS-SDKs/archive/master.zip
unzip master.zip
sudo mkdir -p $THEOS/sdks
sudo mv $HOME/iOS-SDKs-master/*.sdk $THEOS/sdks
rm -rf $HOME/iOS-SDKs-master $HOME/master.zip

# Download and install Swift toolchain
curl https://kabiroberai.com/toolchain/download.php?toolchain=swift-ubuntu-latest -Lo swift-toolchain.tar.gz
sudo tar xzf swift-toolchain.tar.gz -C $THEOS/toolchain
rm swift-toolchain.tar.gz

echo "All done!"
