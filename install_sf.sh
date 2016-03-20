#!/bin/bash

###############################################################################
## Automated "clean" Symfony(v2.8) installer
## Authors: 
##      Armas Spann
##          inspired by Martin Bieder
## CreationDate: 2016-03-16
###############################################################################

## including helpers..
installer_path=$(dirname `readlink -f $0`)
source ${installer_path}/helper/helper.sh

## Additional test configuration (config_test.yml) - base64 encoded
CONFTST_YML_B64="ZG9jdHJpbmU6DQogIGRiYWw6DQogICAgICAgIGRlZmF1bHRfY29ubmVjdGlvb\
jogZGVmYXVsdA0KICAgICAgICBjb25uZWN0aW9uczoNCiAgICAgICAgICAgIGRlZmF1bHQ6DQogICA\
gICAgICAgICAgICAgZHJpdmVyOiAgIHBkb19zcWxpdGUNCiAgICAgICAgICAgICAgICBwYXRoOiAgI\
CAgJyVrZXJuZWwuY2FjaGVfZGlyJS9kYXRhLnNxbGl0ZSc="

## Welcome message
prntMessage "=== Symfony Framework installer (2.8) ==="
echo -e ""

## checking if $1 (project_name) is set
if [[ -z $1 ]]; then
    prntMessage "usage: $0 <project_name> <options>\noptions:\n -f\tforce overwrite"
    exit 0;
else
    project_name=$1
    if [[ $2 == "-f" ]] && [[ -d ${project_name} ]]; then
        prntWithSpaces "Deleting existing project: '${project_name}' (due -f option)..."
        rm -rf ${project_name}
        if [[ -d ${project_name} ]]; then
            prntERR; exit 1;
        fi
        prntOK
        echo -e ""
    elif [[ -d ${project_name} ]]; then
        prntCRIT "Sorry, project ($1) exists already."
    fi
fi

## checking for binaries (php, composer, npm, bower, symfony)
prntMessage "Checking for needed binaries/aliases..."
chkBinMulti "awk, base64, bash, bower, composer, npm, php, sed, symfony, whereis"
if [[ $SH_ERROR -eq 1 ]]; then
    prntCRIT "Sorry some dependencies are missing. please fix them!"
else
    ## determine composer path ()
    if [[ `builtin type composer 2>/dev/null` ]]; then
        composer="composer"
    else
        composer=$(echo -e $(bash -i -c "alias" \
        | awk -v FS="(composer=| alias=)" '{print $2}') | tr -d '[[:space:]]')
        composer=${composer:1:-1}
    fi
fi
echo -e ""

## preparing symfony base-installlation...
prntWithSpaces "Installing Symfony 2.8..."
symfony new ${project_name} 2.8 >/dev/null 2>&1
if [[ -d ${project_name} ]]; then
    prntOK

    ## installing bundle files
    for bundle in ${installer_path}/mod_bundle/*.bundle; do
        source ${bundle};
    done

    ## finalizing install (comperser update)
    prntWithSpaces "Finalizing Symfony 2.8 (composer update)..."
    $(cd ${project_name} && eval ${composer} update >/dev/null 2>&1)
    prntOK

    echo -e ""
    prntWithSpaces "Fixing test-environment..."
    ## patching config_test.yml
    echo $CONFTST_YML_B64 | base64 -d >> ${project_name}/app/config/config_test.yml
    prntOK
else
    prntCRIT "Sorry, can't install Symfony 2.8."
fi
echo -e ""

prntMessage "Symfony 2.8 setup complete."

exit 0
