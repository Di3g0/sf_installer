# sf_installer
Installs the Symfony framework (2.8) as a desired "project" to the current
working directory(cwd), which includes some mandatory bundles (see mod_bundle)
and configurations. To get the 'clean' Symfony installation working, adjust the
database settings in "project"/app/config/parameters.yml.

####Installation (as root):
```sh
    cd /opt && git clone https://github.com/aspann/sf_installer
    ln -sf /opt/sf_installer/install_sf.sh /usr/local/bin/install_sf-2.8
    ln -sf /usr/local/bin/install_sf-2.8 /usr/local/bin/install_sf
```

####Usage:
```
    install_sf[.sh] <project_name> [<options>]
        options:
         -f force overwrite
         -h help
         -y Yes to all questions
```
