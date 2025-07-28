#!/bin/sh

if [ -f /etc/os-release ]; then
    OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    
    case "$OS_ID" in
        debian|ubuntu|linuxmint|pop|kali)
            exit 1
            ;;
        rhel|centos|fedora|rocky|almalinux|ol)
            exit 2
            ;;
    esac
fi

if [ -f /etc/debian_version ]; then
    exit 1
elif [ -f /etc/redhat-release ] || \
     [ -f /etc/centos-release ] || \
     [ -f /etc/fedora-release ] || \
     [ -f /etc/rocky-release ] || \
     [ -f /etc/almalinux-release ]; then
    exit 2
fi

exit 0
