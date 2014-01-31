#!/bin/sh

if ! id | grep -q root; then
        echo "must be run as root"
        exit
fi

echo "Reseting root password to [root]..."

#it was blanked out via:
#root_password=$(cat /etc/shadow | grep root | awk -F ':' '{print $2}')
#sed -i -e 's:'$root_password'::g' /etc/shadow

passwd <<-_EOF_
root
root
_EOF_

echo "ssh: resecuring, password now required..."

#it was opened up via:
#sed -i -e 's:PermitEmptyPasswords no:PermitEmptyPasswords yes:g' /etc/ssh/sshd_config
#sed -i -e 's:UsePAM yes:UsePAM no:g' /etc/ssh/sshd_config

sed -i -e 's:PermitEmptyPasswords yes:PermitEmptyPasswords no:g' /etc/ssh/sshd_config
sed -i -e 's:UsePAM no:UsePAM yes:g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

echo "Complete..."

