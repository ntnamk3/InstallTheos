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

sudo apt-get update
sudo apt-get install -y software-properties-common gnupg1 gnupg2 gnupg3 gnupg unzip

sudo rm -rf $THEOS

LLVM_VERSION=${1:-16}  # Updated to the latest LLVM version

DISTRO=$(lsb_release -is)
VERSION=$(lsb_release -sr)
DIST_VERSION="${DISTRO}_${VERSION}"

declare -A LLVM_VERSION_PATTERNS
LLVM_VERSION_PATTERNS[9]="-9"
LLVM_VERSION_PATTERNS[10]="-10"
LLVM_VERSION_PATTERNS[11]="-11"
LLVM_VERSION_PATTERNS[12]="-12"
LLVM_VERSION_PATTERNS[13]="-13"
LLVM_VERSION_PATTERNS[14]="-14"
LLVM_VERSION_PATTERNS[15]="-15"
LLVM_VERSION_PATTERNS[16]="-16"

if [ ! ${LLVM_VERSION_PATTERNS[$LLVM_VERSION]+_} ]; then
    echo "This script does not support LLVM version $LLVM_VERSION"
    exit 3
fi

LLVM_VERSION_STRING=${LLVM_VERSION_PATTERNS[$LLVM_VERSION]}

# find the right repository name for the distro and version
case "$DIST_VERSION" in
    Debian_9* )       REPO_NAME="deb http://apt.llvm.org/stretch/  llvm-toolchain-stretch$LLVM_VERSION_STRING main" ;;
    Debian_10* )      REPO_NAME="deb http://apt.llvm.org/buster/   llvm-toolchain-buster$LLVM_VERSION_STRING  main" ;;
    Debian_unstable ) REPO_NAME="deb http://apt.llvm.org/unstable/ llvm-toolchain$LLVM_VERSION_STRING         main" ;;
    Debian_testing )  REPO_NAME="deb http://apt.llvm.org/unstable/ llvm-toolchain$LLVM_VERSION_STRING         main" ;;
    Ubuntu_16.04 )    REPO_NAME="deb http://apt.llvm.org/xenial/   llvm-toolchain-xenial$LLVM_VERSION_STRING  main" ;;
    Ubuntu_18.04 )    REPO_NAME="deb http://apt.llvm.org/bionic/   llvm-toolchain-bionic$LLVM_VERSION_STRING  main" ;;
    Ubuntu_18.10 )    REPO_NAME="deb http://apt.llvm.org/cosmic/   llvm-toolchain-cosmic$LLVM_VERSION_STRING  main" ;;
    Ubuntu_19.04 )    REPO_NAME="deb http://apt.llvm.org/disco/    llvm-toolchain-disco$LLVM_VERSION_STRING   main" ;;
    Ubuntu_19.10 )    REPO_NAME="deb http://apt.llvm.org/eoan/     llvm-toolchain-eoan$LLVM_VERSION_STRING    main" ;;
    Ubuntu_20.04 )    REPO_NAME="deb http://apt.llvm.org/focal/    llvm-toolchain-focal$LLVM_VERSION_STRING   main" ;;
    Ubuntu_22.04 )    REPO_NAME="deb http://apt.llvm.org/jammy/    llvm-toolchain-jammy$LLVM_VERSION_STRING   main" ;;
    * )
        echo "Distribution '$DISTRO' in version '$VERSION' is not supported by this script (${DIST_VERSION})."
        exit 2
esac

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo add-apt-repository "${REPO_NAME}"
sudo apt-get update
sudo apt-get install -y clang-$LLVM_VERSION lldb-$LLVM_VERSION lld-$LLVM_VERSION clangd-$LLVM_VERSION
sudo apt-get install -y fakeroot git perl build-essential

sudo git clone --recursive https://github.com/theos/theos.git $THEOS
sudo rm -rf $THEOS/toolchain*

# Replace with the latest toolchain link
curl -LO https://github.com/sbingner/llvm-project/releases/download/v16.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma
TMP=$(mktemp -d)
echo $TMP
tar --lzma -xf linux-ios-arm64e-clang-toolchain.tar.lzma -C $TMP
sudo mkdir -p $THEOS/toolchain/linux/iphone
sudo mv $TMP/ios-arm64e-clang-toolchain/* $THEOS/toolchain/linux/iphone/
rm -rf $TMP linux-ios-arm64e-clang-toolchain.tar.lzma

cd $HOME
wget https://github.com/xybp888/iOS-SDKs/archive/master.zip
unzip master.zip
sudo mkdir -p $THEOS/sdks
sudo mv $HOME/iOS-SDKs-master/*.sdk $THEOS/sdks
rm -rf $HOME/iOS-SDKs-master $HOME/master.zip

# Replace with the latest Swift toolchain link
curl https://kabiroberai.com/toolchain/download.php?toolchain=swift-ubuntu-latest -Lo swift-toolchain.tar.gz
sudo tar xzf swift-toolchain.tar.gz -C $THEOS/toolchain
rm swift-toolchain.tar.gz

echo "All done!"
