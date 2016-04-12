#!/bin/bash

###############################################################################
## Setup Helper - INCLUDE
## Author: 
##      Armas Spann
## CreationDate: 2016-03-16
###############################################################################

SH_ERROR=0
SH_QUIT_ON_ERROR=0

## set default tab-width.. (8 spaces)
tabs -n 8

## getting "superuser" command..
case $(awk -F= '/^NAME/{print tolower($2)}' /etc/os-release | sed "s/\"//g") in
    "ubuntu")
        suCmd="sudo sh -c"
        ;;
    *)
    	suCmd="su -c"
    	;;
esac

### [info] - begin
function prntWithSpaces {
    spaces=$(($(tput cols)-$(expr length "$1")-4))
    if [[ $# == 2 ]]; then
        echo -ne $1
        for ((i=0; i<=${spaces}; i++)); do
            echo -ne "$2"
        done
        echo -e "$2$2$2$2"
    else
        tabs $(($(tput cols)-4))
        echo -ne $1
    fi
}
function prntInfo {
    echo -e "\t[\033[01;32m**\033[00m]"
}
function prntOK {
    echo -e "\t[\033[01;32m++\033[00m]"
}
function prntWARN {
    echo -e "\t[\033[01;33m--\033[00m]"
}
function prntERR {
    SH_ERROR=1
    echo -e "\t[\033[01;31m!!\033[00m]"
    if [[ $SH_QUIT_ON_ERROR -eq 1 ]]; then
        prntMessage "Error, exiting!"
        cleanup
        exit;
    fi
}
function prntCRIT {
    if [[ ! -z $1 ]]; then
        prntWithSpaces "$1"
    else
        prntWithSpaces "Sorry, unable to complete, please contact your BOFH!"
    fi
    prntERR
    exit 1;
}
function prntMessage {
    if [[ $# == 2 ]]; then
        prntWithSpaces "$1"
        case "$2" in
            "ok")
                prntOK
                ;;
            "wrn")
                prntWARN
                ;;
            "err")
                prntERR
                ;;
            *)
                prntInfo
                ;;
        esac
    elif [[ $# == 1 ]]; then
        echo -e $1
    else
        echo -e ""
    fi
}
### [info] - end

### [bin-check] - beginn
function chkBin {
    bin=`echo $1 | tr -d ' '`
    if [[ $bin == *","* ]]; then
        chkBinMulti $bin
        return;
    fi
    prntWithSpaces "Checking for '$bin'.."
    if [[ `builtin type $bin 2>/dev/null` ]] || [[ `echo $(bash -i -c 'alias') | grep $bin` ]]; then
        prntOK
    else
        prntERR
        showBinMessage $bin
        unset bin
    fi
}
function chkBinMulti {
    IFS=',' read -a items <<< "$1"
    for index in "${!items[@]}" ; do
        chkBin ${items[index]}
    done
    unset items index IFS
}
function showBinMessage {
    case "$1" in
        "composer")
            prntMessage "installing composer..."
            mkdir -p ~/.config/composer
            $(cd ~/.config/composer && wget https://getcomposer.org/composer.phar >/dev/null 2>&1 && chmod +x composer.phar)
            alias composer='~/.config/composer/composer.phar'
            prntMessage "please add: alias composer='~/.config/composer/composer.phar'" "info"
            prntMessage "composer installation succeeded, please rerun." "ok"
            ;;
        "symfony")
            prntMessage "installing symfony..."
            if [[ $EUID -ne 0 && ${suCmd} != "sudo sh -c" ]]; then echo -n "root-"; fi
            $(${suCmd} "curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony && chmod a+x /usr/local/bin/symfony")
            prntMessage "symfony installation succeeded, please rerun." "ok"
            ;;
        *)
            prntMessage "please install '$1', or add an alias to it."
            ;;
    esac
}
### [bin-check] - end

### [Cleanup] - begin
function cleanup {
    unset SH_QUIT_ON_ERROR SH_ERROR
    tabs -8
}
### [Cleanup] - end