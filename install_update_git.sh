#!/bin/bash

set -e

check_root() {
    if [ "$(id -u)" != "0" ] && [ "$PACKAGE_MANAGER" != "brew" ]; then
        echo "Error: This script must be run as root for $PACKAGE_MANAGER operations"
        exit 1
    fi
}

detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif type lsb_release &> /dev/null; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [ "$(uname -o)" == "Android" ]; then
        OS="android"
    elif [ "$(uname)" == "Darwin" ]; then
        OS="darwin"
        if ! command -v brew >/dev/null 2>&1; then
            echo "Error: Homebrew is not installed. Please install it first."
            exit 1
        fi
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

    case "$OS" in
        "ubuntu"|"debian")
            PACKAGE_MANAGER="apt"
            ;;
        "fedora")
            PACKAGE_MANAGER="dnf"
            ;;
        "centos")
            if command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
            else
                PACKAGE_MANAGER="yum"
            fi
            ;;
        "arch")
            PACKAGE_MANAGER="pacman"
            ;;
        "gentoo")
            PACKAGE_MANAGER="emerge"
            ;;
        "darwin")
            PACKAGE_MANAGER="brew"
            ;;
        "android")
            PACKAGE_MANAGER="pkg"
            ;;
        *)
            PACKAGE_MANAGER="unknown"
            ;;
    esac
}

install_update_git() {
    local package_manager=$1
    local exit_code=0
    
    if command -v git >/dev/null 2>&1; then
        echo "Git is already installed, checking for updates..."
        case $package_manager in
            "brew")
                brew update || exit_code=$?
                [ $exit_code -eq 0 ] && brew upgrade git || exit_code=$?
                ;;
            "apt")
                apt-get update || exit_code=$?
                [ $exit_code -eq 0 ] && apt-get upgrade -y git || exit_code=$?
                [ $exit_code -eq 0 ] && apt-get clean || exit_code=$?
                [ $exit_code -eq 0 ] && rm -rf /var/lib/apt/lists/* || exit_code=$?
                ;;
            "yum")
                yum update -y || exit_code=$?
                [ $exit_code -eq 0 ] && yum upgrade -y git || exit_code=$?
                [ $exit_code -eq 0 ] && yum clean all || exit_code=$?
                [ $exit_code -eq 0 ] && rm -rf /var/cache/yum || exit_code=$?
                ;;
            "dnf")
                dnf check-update || [ $? -eq 100 ] || exit_code=$?
                [ $exit_code -eq 0 ] && dnf upgrade -y git || exit_code=$?
                [ $exit_code -eq 0 ] && dnf clean all || exit_code=$?
                ;;
            "pacman")
                pacman -Syu --noconfirm git || exit_code=$?
                [ $exit_code -eq 0 ] && pacman -Scc --noconfirm || exit_code=$?
                ;;
            "emerge")
                emerge --sync || exit_code=$?
                [ $exit_code -eq 0 ] && emerge -u dev-vcs/git || exit_code=$?
                [ $exit_code -eq 0 ] && eclean distfiles || exit_code=$?
                ;;
            "pkg")
                pkg update || exit_code=$?
                [ $exit_code -eq 0 ] && pkg upgrade -y git || exit_code=$?
                [ $exit_code -eq 0 ] && pkg clean -y || exit_code=$?
                ;;
            *)
                echo "Error: Package manager '$package_manager' not supported."
                exit 1
                ;;
        esac
    else
        echo "Git is not installed, installing it now..."
        case $package_manager in
            "brew")
                brew update || exit_code=$?
                [ $exit_code -eq 0 ] && brew install git || exit_code=$?
                ;;
            "apt")
                apt-get update || exit_code=$?
                [ $exit_code -eq 0 ] && apt-get install -y git || exit_code=$?
                [ $exit_code -eq 0 ] && apt-get clean || exit_code=$?
                [ $exit_code -eq 0 ] && rm -rf /var/lib/apt/lists/* || exit_code=$?
                ;;
            "yum")
                yum update -y || exit_code=$?
                [ $exit_code -eq 0 ] && yum install -y git || exit_code=$?
                [ $exit_code -eq 0 ] && yum clean all || exit_code=$?
                [ $exit_code -eq 0 ] && rm -rf /var/cache/yum || exit_code=$?
                ;;
            "dnf")
                dnf check-update || [ $? -eq 100 ] || exit_code=$?
                [ $exit_code -eq 0 ] && dnf install -y git || exit_code=$?
                [ $exit_code -eq 0 ] && dnf clean all || exit_code=$?
                ;;
            "pacman")
                pacman -Syu --noconfirm git || exit_code=$?
                [ $exit_code -eq 0 ] && pacman -Scc --noconfirm || exit_code=$?
                ;;
            "emerge")
                emerge --sync || exit_code=$?
                [ $exit_code -eq 0 ] && emerge dev-vcs/git || exit_code=$?
                [ $exit_code -eq 0 ] && eclean distfiles || exit_code=$?
                ;;
            "pkg")
                pkg update || exit_code=$?
                [ $exit_code -eq 0 ] && pkg install -y git || exit_code=$?
                [ $exit_code -eq 0 ] && pkg clean -y || exit_code=$?
                ;;
            *)
                echo "Error: Package manager '$package_manager' not supported."
                exit 1
                ;;
        esac
    fi

    if [ $exit_code -ne 0 ]; then
        echo "Error: Failed to install/update git using $package_manager"
        exit $exit_code
    fi
}

main() {
    detect_system

    if [ "$PACKAGE_MANAGER" = "unknown" ]; then
        echo "Error: No supported package manager found (brew, apt, yum, dnf, pacman, emerge or pkg)."
        exit 1
    fi

    check_root

    install_update_git "$PACKAGE_MANAGER"

    echo "Git installation/update completed successfully using $PACKAGE_MANAGER."
}

main

exit 0
