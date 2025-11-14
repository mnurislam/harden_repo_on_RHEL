# Veeam Hardened Repository Setup Script (RHEL/Centos/Rocky)

## Description

Bash script to automate configuration necessary steps to secure a Linux server (RHEL-based) for Veeam hardened repo usage.

## Project Goal
- **Operating System** : RHEL 8/9, CentOS stream 8/9, or Rocky Linux 8/9.
- **Privilleges** : must run with ```sudo``` command, or root user (if created ) 
- ***Veeam Account*** :
  - Pre-created, non-root **Veeam Admin User** (e.g., ```veeamadm``` ).
  - A dedicated **Veeam Admin Group** (e.g., ```veeamadm``` ).
- ***Repository Path*** : The target directory must be exists (e.g.,```/mnt/repo```  ).

## Features

- ***User/Group Management*** : Check if the Veeam admin user exists and offers to create and offers the specified Veeam admin group if missing, then adds the users to the group.
- **Directory Hardening** :
  - Sets ownership to repository directory ( ```$repoDir``` ) to the scpecified Veeam user and group.
  - Sets strict permission to **700** on ```$repoDir``` (Owner Read/Write/Execute, Group/Others No Access).
- **Automatic Updates** :
  - Install the ```dnf-automatic``` package.
  - Configure ```/etc/dnf/automatic``` to set ```upgrade_type = security``` and ```apply_updates = yes ```
- **Time Sync Hardening (Chronyd):** : Modifies ```/etc/sysconfig/chronyd``` to enforce required security options (e.g., setting ```OPTIONS="-R -F"``` )

## Usage

``` bash
chmod +x RHELHardenRepo.sh

# Run the script with sudo command 
sudo ./RHELHardenRepo.sh

# The script will prompt you for:
# - Veeam Admin Username
# - Veeam Admin Group Name
# - Repository Directory Path
```


## Post-Run Steps

- **Veeam Console** : Adding server to Veeam Backup & Replication console, selecting the "Single-use credentials for this server" option.

## Contributing License 

- **License** : MIT License
- **Contributing** : 
