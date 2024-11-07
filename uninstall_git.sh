#!/bin/bash

check_sudo() {
    if [ "$EUID" -ne 0 ]; then 
        echo "This script requires sudo privileges to uninstall Git."
        echo "Please run with sudo."
        sleep 5
        exit 4
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
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi

    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        PACKAGE_MANAGER="apt"
    elif [ "$OS" == "fedora" ] || [ "$OS" == "centos" ]; then
        PACKAGE_MANAGER="yum"
    elif [ "$OS" == "darwin" ]; then
        PACKAGE_MANAGER="brew"
    elif [ "$OS" == "android" ]; then
        PACKAGE_MANAGER="pkg"
    else
        echo "Unsupported operating system or package manager."
        exit 3
    fi

    echo "Detected OS: $OS"
    echo "Using package manager: $PACKAGE_MANAGER"
}

check_git() {
    if ! command -v git &> /dev/null; then
        echo "Git is not installed on this system."
        sleep 5
        exit 0
    else
        echo "Git is installed. Current version:"
        git --version
    fi
}

uninstall_git() {
    echo "Uninstalling Git..."
    
    case $PACKAGE_MANAGER in
        "apt")
            apt-get remove --purge git -y
            apt-get autoremove -y
            apt-get autoclean
            ;;
        "yum")
            yum remove git -y
            yum clean
            ;;
        "brew")
            brew uninstall git
            ;;
        "pkg")
            pkg uninstall git -y
            pkg  clean -y
            ;;
        *)
            echo "Unsupported package manager for automatic uninstallation."
            sleep 5
            exit 2
            ;;
    esac
    
    echo "Git has been uninstalled."
}

check_sudo
detect_os_and_package_manager
check_git
uninstall_git

if ! command -v git &> /dev/null; then
    echo "Verification: Git has been successfully removed."
else
    echo "Warning: Git might still be installed, please check manually."
fi

sleep 5
exit 1
