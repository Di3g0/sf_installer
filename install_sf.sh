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
prntMessage "=== Symfony Framework installer (2.8) ===\n"

function help {
    prntMessage "usage: $0 <project_name> [<options>]\n\
        options:\n\
         -f\tforce overwrite\n\
         -h\thelp$1\n\
         -u\tupdates install_sf (if available)\n\
         -y\tYes to all questions"
}

## checking if $1 (project_name) is set
if [[ -z $1 ]]; then
    help " (this message)"
    exit 0;
else
    parms="$@"
    ## parsing options..
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|-au|--update)
                prntMessage "Try to Update myself..."
                real_app=$(readlink -eq `whereis install_sf | cut -d ' ' -f2`)
                real_app_dir=$(dirname ${real_app})
                if [[ -d ${real_app_dir} ]]; then
                    echo -n "root-"
                    $(su -c "cd ${real_app_dir} && git pull >/dev/null 2>&1")
                    prntMessage "Updated succeeded, please rerun." "ok"
                else
                    prntMessage "Update failed." "err"
                fi
                exit 0; ;;
            -h|--h|--help)
                help " (this message)"; exit 0; ;;
            -f)
                opt_force=true; ;;
            -y)
                opt_y2all=true; ;;
            -fy|-yf)
                opt_force=true
                opt_y2all=true
                ;;
            *)
                if [[ ! ${project_name} ]] && [[ ! $1 == -* ]]; then
                    project_name=$1
                else
                    prntMessage ">>> Invalid option: $1" "err"; echo
                    help; exit 0
                fi
        esac
        shift
    done

    ## checking paths... (existence)
    if [[ -d ${project_name} ]] && [[ ${opt_force} ]]; then
        prntWithSpaces "Deleting existing project '${project_name}' due -f option..."
        rm -rf ${project_name}
        if [[ -d ${project_name} ]]; then
            prntERR; exit 1;
        fi
        prntOK
    elif [[ -d ${project_name} ]]; then
        prntCRIT "Sorry, project '${project_name}' exists already."
    fi

    if [[ ${opt_y2all} ]]; then
        prntWithSpaces "Enabeling 'yes to all' due -y option..."
        prntOK
    fi; echo
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
fi; echo

## preparing symfony base-installation...
prntWithSpaces "Installing Symfony 2.8..."
symfony new ${project_name} 2.8 >/dev/null 2>&1
if [[ -d ${project_name} ]]; then
    prntOK

    ## installing bundle files
    for bundle in ${installer_path}/mod_bundle/*.bundle; do
        if [[ ! ${opt_y2all} ]]; then
            read -p "Install $(basename $bundle | \
             sed -s 's/.bundle//g')? (y/n): " -n 1 -r
            echo
        else
            REPLY="y"
        fi

        if [[ $REPLY =~ ^[YyJj]$ ]]; then
            source ${bundle};
        fi
    done

    ## finalizing install (comperser update)
    prntWithSpaces "Finalizing Symfony 2.8 (composer update)..."
    $(cd ${project_name} && eval ${composer} update >/dev/null 2>&1)
    prntOK; echo
    ## patching config_test.yml
    prntWithSpaces "Fixing test-environment..."
    echo $CONFTST_YML_B64 | base64 -d >> ${project_name}/app/config/config_test.yml
    prntOK
else
    prntCRIT "Sorry, can't install Symfony 2.8."
fi
echo

prntMessage "Symfony 2.8 setup complete."

exit 0
