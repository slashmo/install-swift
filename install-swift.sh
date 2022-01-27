#!/bin/bash

# Expects environment variable `SWIFT_VERSION`
# Example values: 5.5 or swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a

# System library dependencies: wget

install_swift () {
    determine_os

    if [[ -d $(toolchain_path) ]]; then
        echo "Toolchain already exists, skipping download ✅"
    else
        download_toolchain
        if_linux_verify_signature
    fi

    if_linux_install_system_dependencies
    install_toolchain

    echo "Successfully installed Swift toolchain 🎉"
}

#-=============================================================================-
# Steps
#-=============================================================================-

determine_os () {
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
}

download_toolchain () {
    echo "Downloading Swift toolchain ☁️"
    if [ $IS_MACOS ]; then
        TOOLCHAIN_URL=$(download_url pkg)
    elif [ $IS_LINUX ]; then
        TOOLCHAIN_URL=$(download_url tar.gz)
    fi

    wget $TOOLCHAIN_URL
}

if_linux_install_system_dependencies () {
    if ! [[ $IS_LINUX ]]; then
        return 0;
    fi

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
}

if_linux_verify_signature () {
    if ! [[ $IS_LINUX ]]; then
        return 0;
    fi

    echo "Verifying Swift toolchain 🔑"
    wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -
    wget $(download_url tar.gz.sig)
    gpg --verify $(download_file tar.gz.sig)
}

install_toolchain () {
    echo "Installing Swift toolchain 💻"

    if [ $IS_LINUX ]; then
        tar xzf $(download_file tar.gz)
        mkdir $(toolchains_path)
        mv $(download_file) $(toolchain_path)
    elif [ $IS_MACOS ]; then
        TOOLCHAIN=$(release_name).xctoolchain
        TOOLCHAINS_PATH=/Library/Developer/Toolchains
        sudo installer -pkg $(download_file pkg) -target /
    fi
    PATH=$(toolchain_path)/usr/bin:${PATH}
    echo "PATH=$PATH" >> $GITHUB_ENV
}

#-=============================================================================-
# Helpers
#-=============================================================================-

# Example release URLs
# https://download.swift.org/swift-5.5.2-release/xcode/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-osx.pkg
# https://download.swift.org/swift-5.5.2-release/ubuntu1804/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu18.04.tar.gz
# https://download.swift.org/swift-5.5.2-release/ubuntu2004/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu20.04.tar.gz

# Example development snapshot URLs
# https://download.swift.org/development/xcode/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-osx.pkg
# https://download.swift.org/development/ubuntu1804/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu18.04.tar.gz
# https://download.swift.org/development/ubuntu1804/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu18.04.tar.gz.sig
# https://download.swift.org/development/ubuntu2004/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu20.04.tar.gz
# https://download.swift.org/development/ubuntu2004/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a/swift-DEVELOPMENT-SNAPSHOT-2022-01-09-a-ubuntu20.04.tar.gz.sig

toolchain_path () {
    if [ $IS_LINUX ]; then
        echo $(toolchains_path)/$(release_name)
    elif [ $IS_MACOS ]; then
        echo $(toolchains_path)/$(release_name).xctoolchain
    fi
}

toolchains_path () {
    if [ $IS_LINUX ]; then
        echo /opt/swift-toolchains
    elif [ $IS_MACOS ]; then
        echo /Library/Developer/Toolchains
    fi
}

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

install_swift
