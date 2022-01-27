#!/bin/bash

if [[ $SWIFT_VERSION == swift-DEVELOPMENT-SNAPSHOT* ]]; then
    TOOLCHAIN_BASE_URL="https://download.swift.org/development/ubuntu${UBUNTU_VERSION//[.]/}/$SWIFT_VERSION"
    TOOLCHAIN_PATH="$SWIFT_VERSION-ubuntu$UBUNTU_VERSION"
else
    TOOLCHAIN_BASE_URL="https://download.swift.org/swift-$SWIFT_VERSION-release/ubuntu${UBUNTU_VERSION//[.]/}/swift-$SWIFT_VERSION-RELEASE"
    TOOLCHAIN_PATH="swift-$SWIFT_VERSION-RELEASE-ubuntu$UBUNTU_VERSION"
fi

TOOLCHAIN_TAR="$TOOLCHAIN_PATH.tar.gz"
TOOLCHAIN_SIG="$TOOLCHAIN_TAR.sig"
TOOLCHAIN_TAR_URL="$TOOLCHAIN_BASE_URL/$TOOLCHAIN_TAR"
TOOLCHAIN_SIG_URL="$TOOLCHAIN_BASE_URL/$TOOLCHAIN_SIG"

echo "Installing system dependencies 📦"
if [ $UBUNTU_VERSION == "18.04" ]; then
    echo "choosing list for 18.04"
    sudo apt-get install \
    binutils git libc6-dev libcurl4 libedit2 libgcc-5-dev libpython2.7 libsqlite3-0 libstdc++-5-dev libxml2 \
    pkg-config tzdata zlib1g-dev
elif [ $UBUNTU_VERSION == "20.04" ]; then
    echo "choosing list for 20.04"
    sudo apt-get install \
    binutils git gnupg2 libc6-dev libcurl4 libedit2 libgcc-9-dev libpython2.7 libsqlite3-0 libstdc++-9-dev libxml2 \
    libz3-dev pkg-config tzdata uuid-dev zlib1g-dev
else
    echo "No Swift Toolchain available for Ubuntu version '$UBUNTU_VERSION'."
    echo "Visit https://swift.org/download for more information."
    exit 1;
fi

if [ -d "/usr/share/swift-toolchain" ]; then
    echo "Toolchain already exists, skipping download ✅"
else
    echo "Reading toolchain version from .swift-version 📄"
    echo "Detected Swift toolchain version '$(cat .swift-version)' 📄"

    echo "Downloading Swift toolchain ☁️"
    wget $TOOLCHAIN_TAR_URL

    echo "Verifying Swift toolchain 🔑"
    wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -
    wget $TOOLCHAIN_SIG_URL
    gpg --verify $TOOLCHAIN_SIG

    echo "Installing Swift toolchain 💻"
    tar xzf $TOOLCHAIN_TAR

    mv $TOOLCHAIN_PATH /usr/share/swift-toolchain
    echo "Successfully installed Swift toolchain 🎉"
fi

export PATH=/usr/share/swift-toolchain/usr/bin:${PATH}
echo "PATH=$PATH" >> $GITHUB_ENV
