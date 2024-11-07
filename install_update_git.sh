#!/bin/bash

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
elif type lsb_release &> /dev/null; then
    OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
elif [ "$(uname -o)" == "Android" ]; then
    OS="android"
elif [ "$(uname)" == "Darwin" ]; then
    OS="darwin"
elif [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/fedora-release ]; then
    OS="fedora"
elif [ -f /etc/centos-release ]; then
    OS="centos"
elif [ -f /etc/arch-release ]; then
    OS="arch"
elif [ -f /etc/gentoo-release ]; then
    OS="gentoo"
else
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
fi

if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    PACKAGE_MANAGER="apt"
elif [ "$OS" == "fedora" ]; then
    PACKAGE_MANAGER="dnf"
elif [ "$OS" == "centos" ]; then
    # Check if dnf is available, otherwise use yum
    if command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
    else
        PACKAGE_MANAGER="yum"
    fi
elif [ "$OS" == "arch" ]; then
    PACKAGE_MANAGER="pacman"
elif [ "$OS" == "gentoo" ]; then
    PACKAGE_MANAGER="emerge"
elif [ "$OS" == "darwin" ]; then
    PACKAGE_MANAGER="brew"
elif [ "$OS" == "android" ]; then
    PACKAGE_MANAGER="pkg"
else
    PACKAGE_MANAGER="unknown"
fi

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
                yum update
                yum update -y git
                yum clean all
                rm -rf /var/cache/yum
                ;;
            "dnf")
                dnf check-update
                dnf upgrade -y git
                dnf clean all
                ;;
            "pacman")
                pacman -Sy
                pacman -S --noconfirm git
                pacman -Scc --noconfirm
                ;;
            "emerge")
                emerge --sync
                emerge -u dev-vcs/git
                eclean distfiles
                ;;
            "pkg")
                pkg update
                pkg upgrade -y git
                pkg clean -y
                ;;
            *)
                echo "Error: Package manager '$package_manager' not supported."
                sleep 5
                exit 1
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
            "dnf")
                dnf check-update
                dnf install -y git
                dnf clean all
                ;;
            "pacman")
                pacman -Sy
                pacman -S --noconfirm git
                pacman -Scc --noconfirm
                ;;
            "emerge")
                emerge --sync
                emerge dev-vcs/git
                eclean distfiles
                ;;
            "pkg")
                pkg update
                pkg install -y git
                pkg clean -y
                ;;
            *)
                echo "Error: Package manager '$package_manager' not supported."
                sleep 5
                exit 1
                ;;
        esac
    fi
}

if [ "$PACKAGE_MANAGER" = "unknown" ]; then
    echo "Error: No supported package manager found (brew, apt, yum, dnf, pacman, emerge or pkg)."
    sleep 5
    exit 1
fi

install_update_git $PACKAGE_MANAGER

echo "Git installation/update completed using $PACKAGE_MANAGER."

sleep 5
exit 0
