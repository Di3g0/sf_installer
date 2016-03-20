# sf_installer

####Installation (as root):
```sh
    cd /opt && git clone https://github.com/aspann/sf_installer
    ln -sf /opt/sf_installer/install_sf.sh /usr/local/bin/install_sf-2.8
    ln -sf /usr/local/bin/install_sf-2.8 /usr/local/bin/install_sf
```

####Usage:
```
    install_sf[.sh] <project_name> <options>
        options:
         -f force overwrite
         -h help
         -y Yes to all questions
```
