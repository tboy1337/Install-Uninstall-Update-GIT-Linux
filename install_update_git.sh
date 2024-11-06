#!/bin/bash

get_package_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    else
        echo "unknown"
    fi
}

install_update_git() {
    local package_manager=$1
    
    if command -v git >/dev/null 2>&1; then
        echo "Git is already installed, checking for updates..."
        case $package_manager in
            "brew")
                brew update
                brew upgrade git
                ;;
            "apt")
                apt-get update
                apt-get install --only-upgrade git
                apt-get clean
                rm -rf /var/lib/apt/lists/*
                ;;
            "yum")
                yum update -y git
                yum clean all
                rm -rf /var/cache/yum
                ;;
        esac
    else
        echo "Git is not installed, installing it now..."
        case $package_manager in
            "brew")
                brew update
                brew install git
                ;;
            "apt")
                apt-get update
                apt-get install -y git
                apt-get clean
                rm -rf /var/lib/apt/lists/*
                ;;
            "yum")
                yum update
                yum install -y git
                yum clean all
                rm -rf /var/cache/yum
                ;;
        esac
    fi
}

PACKAGE_MANAGER=$(get_package_manager)

if [ "$PACKAGE_MANAGER" = "unknown" ]; then
    echo "Error: No supported package manager found (brew, apt-get, or yum)"
    exit 1
fi

install_update_git $PACKAGE_MANAGER

echo "Git installation/update completed using $PACKAGE_MANAGER"

exit 0
