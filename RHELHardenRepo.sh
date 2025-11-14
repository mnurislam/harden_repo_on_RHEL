#!/bin/bash
# Filename: RHELHardenRepo.sh
# Description: Setting up Veeam hardened repo for RHEL
# Author: Muhammad Nur Islam
# Email: islam.shuhaili@outlook.com
# Organization:

set -euo pipefail

read -p "Enter veeam admin username: " userName
read -p "Enter veeam admin group: " userGroup
read -p "Enter harden repo directory: " repoDir

# Check if user exist
getent passwd "$userName" >/dev/null || {
  echo "User not found: $userName"
  exit 1
}

# Check if group exist
getent group "$userGroup" >/dev/null || {
  echo "Group not found: $userGroup"
  read -rp "Do you want to create a group $userGroup: (y/n) " RESPONSE

  case $RESPONSE in
  [yY] | [yY][eE][sS])
    printf "Creating %s group....\n" "$userGroup"

    groupadd "$userGroup"

    printf "Verifying group creation...\n"
    getent group "$userGroup" | awk -F : '{ print $1 " group created" }'

    printf "Adding %s into %s....\n" "$userName" "$userGroup"
    usermod -aG "$userGroup" "userName"

    printf "Verifying user membership for %s...\n" "$username"
    id -nG "$userName" | grep -q "$userGroup"
    ;;
  *)
    printf "Operation cancelled. Exiting setup.\n"
    exit 1
    ;;
  esac

}

# Modify directory ownership and permission
printf "\n### Directory Ownership and Permission ###\n"
printf "Current state of $repoDir ...\n"
stat -c $'\nDirectory: %n\nPermission: %a\nOwner: %U\nGroup: %G\n' "$repoDir"
echo

printf "Changing ownership of $repoDir to \nUser: $userName \nGroup: $userGroup \n"
echo
chown -v "$userName":"$userGroup" "$repoDir"
printf "$repodir Ownereship and Permission has been changed .... \n"
stat -c $'\nDirectory: %n\nPermission: %a\nOwner: %U\nGroup: %G\n' "$repoDir"
echo

printf "Changing permission for directory $repoDir \n"
chmod 700 "$repoDir"
printf "$repoDir permission has been changed\n"

# Installing packages
printf "\n### Installing dnf-automatic ###\n"
printf "\n Installing dnf-automatic packages...\n "
if dnf install -y dnf-automatic; then
  printf "Installation complete! \nEditing /etc/dnf/automatic.conf file\n"

  # Check file, create backup and modify if exists
  dnfConf='/etc/dnf/automatic.conf'
  if [ ! -e $dnfConf ]; then
    printf "File does not exist!\n"
  else
    printf "\nCreating backup of $dnfConf config file ...\n"
    cp -v $dnfConf $dnfConf.bak | while read line; do
      printf "$line\n"
    done
    printf "\nChanging upgrade_type to security and applying updates\n"

    # Check if the line exist first before modify
    grep -Eq '^[[:space:]]*upgrade_type[[:space:]]*=' $dnfConf ||
      echo 'upgrade_type = default' >>$dnfConf
    grep -Eq '^[[:space:]]*apply_updates[[:space:]]*=' $dnfConf ||
      echo 'apply_updates = no' >>$dnfConf

    # Apply change if the files already exists
    sed -i -e 's/^upgrade_type *= * *default/upgrade_type = security/' \
      -e 's/^apply_updates *= * *no/apply_updates = yes/' $dnfConf
    printf "\nFile /etc/dnf/automatic.conf has been updated\n"
    grep -En 'upgrade_type|apply_updates' $dnfConf | awk '{print "Line Number: " $1 " " $2 " " $3}'
  fi
else
  echo "Installation fail"
  exit 1
fi

# Enable and start services
printf "\n### Enable and Start services ###\n"
printf "\n Enable and start download timer and automatic install services \n"
for service in dnf-automatic-download.timer dnf-automatic-install.timer; do
  systemctl enable --now "$service"
done

# Modify chronyd config file"
printf "\n### Modifying chronyd config file ###\n"
printf "Modify chronyd config file...\n"
chronydConf='/etc/sysconfig/chronyd'
printf "Changing configuration of $chronydConf \n"
if [ ! -e $chronydConf ]; then
  echo "File does not exist!"
  exit 1
else

  # Create backup and modify config file
  printf "\n### Creating backup of $chronydConf config file ... #####\n"
  cp -v $chronydConf $chronydConf.bak | while read line; do
    printf "$line\n"
  done
  sed -i -e 's/OPTIONS=-"F/OPTIONS="-R -F/' $chronydConf
  printf "$chronydConf has been altered\n"
  printf "File name: $chronydConf \n"
  # grep -En $chronydConf | awk '{print "Line number: " $1 " " $2 " " $3}'
  cat $chronydConf
fi

# Restart chronyd conf
printf "\n### Restarting Chronyd ###\n"
printf "Restarting chronyd service...\n"

systemctl restart chronyd

echo "All process have completed successfully"
read -rp "Press Enter to exit.... "
