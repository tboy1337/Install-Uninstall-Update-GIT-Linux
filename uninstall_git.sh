#!/bin/bash

check_sudo() {
    if [ "$EUID" -ne 0 ]; then 
        echo "This script requires sudo privileges to uninstall Git"
        echo "Please run with sudo"
        exit 4
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
    elif [ -f /etc/redhat-release ]; then
        OS="RedHat"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    else
        echo "Unsupported operating system"
        exit 3
    fi
}

check_git() {
    if ! command -v git &> /dev/null; then
        echo "Git is not installed on this system"
        exit 0
    else
        echo "Git is installed. Current version:"
        git --version
    fi
}

uninstall_git() {
    echo "Uninstalling Git..."
    
    case $OS in
        "Ubuntu"|"Debian")
            apt-get remove --purge git -y
            apt-get autoremove -y
            apt-get autoclean
            ;;
        "RedHat"|"CentOS"*)
            yum remove git -y
            ;;
        "macOS")
            brew uninstall git
            ;;
        *)
            echo "Unsupported operating system for automatic uninstallation"
            exit 2
            ;;
    esac
    
    echo "Git has been uninstalled"
}

check_sudo
detect_os
check_git
uninstall_git

if ! command -v git &> /dev/null; then
    echo "Verification: Git has been successfully removed"
else
    echo "Warning: Git might still be installed. Please check manually."
fi

exit 1
