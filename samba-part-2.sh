#! /bin/bash

sudo echo "Getting schema..."
sudo wget https://raw.githubusercontent.com/sudo-project/sudo/main/docs/schema.ActiveDirectory
sudo echo "unixing schema..."
sudo dos2unix schema.ActiveDirectory
sudo echo "adding dc..."
sudo sed -i 's/DC=X/DC=au-team,DC=irpo/g' schema.ActiveDirectory
sudo echo "separating schema..."
sudo head -$(grep -B1 -n '^dn:$' schema.ActiveDirectory | head -1 | grep -oP '\d+') schema.ActiveDirectory > first.ldif
sudo tail +$(grep -B1 -n '^dn:$' schema.ActiveDirectory | head -1 | grep -oP '\d+') schema.ActiveDirectory | sed '/^-/d' > second.ldif
sudo echo "adding schema..."
sudo ldbadd -H /var/lib/samba/private/sam.ldb first.ldif --option="dsdb:schema update allowed"=true
sudo ldbmodify -v -H /var/lib/samba/private/sam.ldb second.ldif --option="dsdb:schema update allowed"=true
sudo echo "adding sudoers.."
sudo samba-tool ou add 'ou=sudoers'
sudo echo "implementing rule and adding it"
sudo cat << EOF > sudoRole-object.ldif
dn: CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo
changetype: add
objectClass: top
objectClass: sudoRole
cn: prava_hq
name: prava_hq
sudoUser: %hq
sudoHost: ALL
sudoCommand: /bin/grep
sudoCommand: /bin/cat
sudoCommand: /usr/bin/id
sudoOption: !authenticate
EOF
sudo ldbadd -H /var/lib/samba/private/sam.ldb sudoRole-object.ldif
sudo echo "Modifiyng attributes (because they don't work properly, insert sob emoji.)"
sudo echo -e "dn: CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo\nchangetype: modify\nreplace: nTSecurityDescriptor" > ntGen.ldif
sudo ldbsearch  -H /var/lib/samba/private/sam.ldb -s base -b 'CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo' 'nTSecurityDescriptor' | sed -n '/^#/d;s/O:DAG:DAD:AI/O:DAG:DAD:AI\(A\;\;RPLCRC\;\;\;AU\)\(A\;\;RPWPCRCCDCLCLORCWOWDSDDTSW\;\;\;SY\)/;3,$p' | sed ':a;N;$!ba;s/\n\s//g' | sed -e 's/.\{78\}/&\n /g' >> ntGen.ldif
sudo ldbmodify -v -H /var/lib/samba/private/sam.ldb ntGen.ldif
