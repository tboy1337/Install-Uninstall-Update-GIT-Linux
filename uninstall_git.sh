#!/bin/bash

check_sudo() {
    if [ "$EUID" -ne 0 ]; then 
        echo "This script requires sudo privileges to uninstall Git."
        echo "Please run with sudo."
        exit 1
    fi
}

detect_os_and_package_manager() {
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
        if command -v dnf &> /dev/null; then
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
        echo "Unsupported operating system or package manager."
        exit 1
    fi

    echo "Detected OS: $OS"
    echo "Using package manager: $PACKAGE_MANAGER"
}

check_git() {
    if ! command -v git &> /dev/null; then
        echo "Git is not installed on this system."
        exit 0
    else
        echo "Git is installed, current version:"
        git --version
    fi
}

uninstall_git() {
    echo "Uninstalling Git..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get update
            apt-get remove --purge git git-core git-man git-doc -y
            apt-get autoremove -y
            apt-get autoclean
            ;;
        "dnf")
            dnf remove git git-core git-doc -y
            dnf clean all
            ;;
        "yum")
            yum remove git git-core git-doc -y
            yum clean all
            ;;
        "pacman")
            pacman -Sy
            pacman -Rns git --noconfirm
            pacman -Sc --noconfirm
            ;;
        "emerge")
            emerge --sync
            emerge -C dev-vcs/git
            emerge --depclean
            ;;
        "brew")
            brew update
            brew uninstall git
            ;;
        "pkg")
            pkg update
            pkg uninstall git -y
            pkg clean -y
            ;;
        *)
            echo "Unsupported package manager for automatic uninstallation."
            exit 1
            ;;
    esac
    
    echo "Git has been uninstalled."
}

main() {
    check_sudo
    detect_os_and_package_manager
    check_git
    uninstall_git

    if ! command -v git &> /dev/null; then
        echo "Verification: Git has been successfully removed."
        exit 0
    else
        echo "Warning: Git might still be installed, please check manually."
        exit 1
    fi
}

main
