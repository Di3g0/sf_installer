#!/bin/bash

###############################################################################
## Automated "clean" Symfony(v2.8) installer
## Authors: 
##      Armas Spann
##          inspired by Martin Bieder
## CreationDate: 2016-03-16
###############################################################################

## including helpers..
source $(dirname `readlink -f $0`)/setup_helper.sh
## BowerBundle configuration  (config.yml)- base64 encoded
BOWER_YML_B64="c3BfYm93ZXI6DQogICAgYmluOiB+YmJ+ICMgT3B0aW9uYWwNCiAgICBhc3NldGl\
jOg0KICAgICAgICBlbmFibGVkOiBmYWxzZQ0KICAgIGJ1bmRsZXM6DQogICAgICAgIEFwcEJ1bmRsZ\
ToNCiAgICAgICAgICAgIGNvbmZpZ19kaXI6IFJlc291cmNlcy9jb25maWcNCiAgICAgICAgICAgIGN\
hY2hlOiAla2VybmVsLnJvb3RfZGlyJS9jYWNoZS9ib3dlcg0KICAgICAgICAgICAgYXNzZXRfZGlyO\
iAuLi9wdWJsaWMvYm93ZXJfY29tcG9uZW50cw=="
## BowerBundle configuration (bower.json) - base64 encoded
BOWER_JSON_B64="ew0KICAgICJuYW1lIjogIn5hbn4iLA0KICAgICJkZXBlbmRlbmNpZXMiOiB7DQ\
ogICAgICAgICJib290c3RyYXAiOiAifjMuMy41IiwNCiAgICAgICAgImJvb3RzdHJhcC1kYXRlcGlj\
a2VyIjogIn4xLjUuMCIsDQogICAgICAgICJmb250LWF3ZXNvbWUiOiAifjQuNC4wIiwNCiAgICAgIC\
AgImJvb3RzdHJhcC1zYXNzIjogIn4zLjMuNSINCiAgICB9DQp9"

## Welcome message
prntMessage "=== Symfony Framework installer (2.8) ==="

## checking if $1 (project_name) is set
if [[ -z $1 ]]; then
    prntCRIT "usage: $0 <project_name>"
elif [[ -d $1 ]]; then
    prntCRIT "Sorry, project ($1) exists already."
else 
    project_name=$1
fi

## checking for binaries (php, composer, npm, bower, symfony)
prntMessage "Checking for needed binaries/aliases..."
chkBinMulti "bash, awk, sed, whereis, php, composer, npm, bower, symfony"
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

## preparing symfony base-installlation...
prntWithSpaces "Installing Symfony 2.8..."
symfony new ${project_name} 2.8 >/dev/null 2>&1
if [[ -d ${project_name} ]]; then
    prntOK
    ## main default install routine..
    prntWithSpaces "Installing SpBowerBundle..."
    ## very bad implementation... need to get around "eval"...
    $(cd ${project_name} \
        && eval ${composer} require sp/bower-bundle >/dev/null 2>&1)
    if [[ -d ${project_name}/vendor/sp/bower-bundle ]]; then
        prntOK
        ## patching configurations...
        prntWithSpaces "Configuring SpBowerBundle..."
        
        ## patching config.yml
        bower=`whereis bower | awk '{print $2}'`
        echo $BOWER_YML_B64 | base64 -d > ${project_name}.tmp
        sed -i "s@~bb~@${bower}@g" ${project_name}.tmp
        sed -i $'s/\r$//' ${project_name}.tmp
        cat ${project_name}.tmp >> ${project_name}/app/config/config.yml
        rm ${project_name}.tmp

        ## patching bower.json
        mkdir -p ${project_name}/src/AppBundle/Resources/config
        echo $BOWER_JSON_B64 | base64 -d > ${project_name}.tmp
        sed -i "s@~an~@${project_name}@g" ${project_name}.tmp
        sed -i $'s/\r$//' ${project_name}.tmp
        cat ${project_name}.tmp > ${project_name}/src/AppBundle/Resources/config/bower.json
        rm ${project_name}.tmp

        ## patching composer.json
        sed -i \
        's/clearCache",/clearCache",\n\t\t"Sp\\\\BowerBundle\\\\Composer\\\\ScriptHandler::bowerInstall\",/g' \
        ${project_name}/composer.json

        ## patching AppKernel.php
        sed -i \
        's/DoctrineBundle(),/DoctrineBundle(),\n\t\tnew\ Sp\\BowerBundle\\SpBowerBundle(),/g' \
        ${project_name}/app/AppKernel.php

        ## just print OK, check follows
        prntOK

        ## finalizing BowerBundle
        prntWithSpaces "Finalizing SpBowerBundle(composer update)..."
        $(cd ${project_name} && eval ${composer} update >/dev/null 2>&1)
        if [[ ${project_name}//src/AppBundle/Resources/public/bower_components ]]; then
            prntOK
        else
            prntERR
            prntMessage "Sorry, can't install SpBowerBundle." "err"
        fi
    else
        prntERR
        prntMessage "Sorry, can't install SpBowerBundle." "err"
    fi


    ## installing DoctrineMigrationsBundle
    prntWithSpaces "Installing DoctrineMigrationsBundle..."
    ## patching php version, <6.4 not supported by bundle
    sed -i \
        's/"php":\ "5.3.9"/"php":\ "5.6"/g' \
        ${project_name}/composer.json
    $(cd ${project_name} \
        && eval ${composer} require doctrine/doctrine-migrations-bundle:^1.0 >/dev/null 2>&1)
    if [[ -d ${project_name}/vendor/doctrine/doctrine-migrations-bundle ]]; then
        prntOK
        ## patching configurations...
        prntWithSpaces "Configuring DoctrineMigrationsBundle..."
        ## patching AppKernel.php
        sed -i \
        's/DoctrineBundle(),/DoctrineBundle(),\n\t\tnew\ Doctrine\\Bundle\\MigrationsBundle\\DoctrineMigrationsBundle(),/g' \
        ${project_name}/app/AppKernel.php
        prntOK

        prntWithSpaces "Finalizing DoctrineMigrationsBundle(composer update)..."
        $(cd ${project_name} && eval ${composer} update >/dev/null 2>&1)
        prntOK
    else
        prntERR
        prntMessage "Sorry, can't install DoctrineMigrationsBundle." "err"
    fi
else
    prntCRIT "Sorry, can't install Symfony 2.8."
fi

