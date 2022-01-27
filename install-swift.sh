#!/bin/bash

# https://download.swift.org/swift-5.5.2-release/xcode/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-osx.pkg
# https://download.swift.org/swift-5.5.2-release/ubuntu1804/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu18.04.tar.gz
# https://download.swift.org/swift-5.5.2-release/ubuntu2004/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu20.04.tar.gz

# https://download.swift.org/development/xcode/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-osx.pkg
# https://download.swift.org/development/ubuntu1804/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu18.04.tar.gz
# https://download.swift.org/development/ubuntu1804/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu18.04.tar.gz.sig
# https://download.swift.org/development/ubuntu2004/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu20.04.tar.gz
# https://download.swift.org/development/ubuntu2004/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu20.04.tar.gz.sig

# $SWIFT_VERSION: 5.5 || swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a

KERNEL=$(uname)
if [[ $KERNEL == "Darwin" ]]; then
    IS_MACOS=true
elif [[ $KERNEL == "Linux" ]]; then
    IS_LINUX=true
    UBUNTU_VERSION=$(lsb_release -rs)
else
    echo "Unsupported kernel '$KERNEL' ☠️"
    exit 1;
fi

release_name () {
    if [[ $SWIFT_VERSION == swift-DEVELOPMENT-SNAPSHOT* ]]; then
        RELEASE_NAME=$SWIFT_VERSION
    else
        RELEASE_NAME=swift-$SWIFT_VERSION-RELEASE
    fi

    echo $RELEASE_NAME
}

download_file () {
    FILETYPE=$1

    if [ $IS_MACOS ]; then
        ALT_PLATFORM=osx
    elif [ $IS_LINUX ]; then
        ALT_PLATFORM=ubuntu$UBUNTU_VERSION
    fi

    RETURN_VALUE=$(release_name)-$ALT_PLATFORM

    if [ $FILETYPE ]; then
        RETURN_VALUE=$RETURN_VALUE.$FILETYPE
    fi

    echo $RETURN_VALUE
}

download_url () {
    DOWNLOAD_BASE_URL=https://download.swift.org
    FILETYPE=$1

    if [[ $SWIFT_VERSION == swift-DEVELOPMENT-SNAPSHOT* ]]; then
        FOLDER=development
    else
        FOLDER=swift-$SWIFT_VERSION-release
    fi

    if [ $IS_MACOS ]; then
        PLATFORM=xcode
    elif [ $IS_LINUX ]; then
        PLATFORM=ubuntu${UBUNTU_VERSION//[.]/}
    fi

    echo $DOWNLOAD_BASE_URL/$FOLDER/$PLATFORM/$(release_name)/$(download_file $FILETYPE)
}

if [ $IS_LINUX ]; then
    echo "Installing system dependencies for '$UBUNTU_VERSION' 📦"
    sudo apt-get update
    if [ $UBUNTU_VERSION == "18.04" ]; then
        sudo apt-get install \
        binutils git libc6-dev libcurl4 libedit2 libgcc-5-dev libpython2.7 libsqlite3-0 libstdc++-5-dev libxml2 \
        pkg-config tzdata zlib1g-dev
    elif [ $UBUNTU_VERSION == "20.04" ]; then
        sudo apt-get install \
        binutils git gnupg2 libc6-dev libcurl4 libedit2 libgcc-9-dev libpython2.7 libsqlite3-0 libstdc++-9-dev libxml2 \
        libz3-dev pkg-config tzdata uuid-dev zlib1g-dev
    else
        echo "No Swift Toolchain available for Ubuntu version '$UBUNTU_VERSION'."
        echo "Visit https://swift.org/download for more information."
        exit 1
    fi
fi

if [ $IS_MACOS ]; then
    TOOLCHAIN_URL=$(download_url pkg)
elif [ $IS_LINUX ]; then
    TOOLCHAIN_URL=$(download_url tar.gz)
    TOOLCHAIN_SIG_URL=$(download_url tar.gz.sig)
fi

echo "Downloading Swift toolchain ☁️"
wget $TOOLCHAIN_URL

if [ $IS_LINUX ]; then
    echo "Verifying Swift toolchain 🔑"
    wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -
    wget $TOOLCHAIN_SIG_URL
    gpg --verify $(download_file tar.gz.sig)

    echo "Installing Swift toolchain 💻"
    tar xzf $(download_file tar.gz)
    ls
    mkdir /opt/swift-toolchains
    mv $(download_file) /opt/swift-toolchains/$(release_name).xctoolchain

    PATH=/opt/swift-toolchains/$(release_name).xctoolchain/usr/bin:${PATH}
elif [ $IS_MACOS ]; then
    echo "Installing Swift toolchain 💻"
    sudo installer -pkg $(download_file pkg) -target /

    PATH=/Library/Developer/Toolchains/$(release_name).xctoolchain/usr/bin:"${PATH}"
fi
echo "PATH=$PATH" >> $GITHUB_ENV

echo "Successfully installed Swift toolchain 🎉"
