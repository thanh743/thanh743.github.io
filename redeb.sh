#!/bin/bash
#title           :redeb.sh
#description     :This script attempts to backup your tweaks, packages,....,everything what has a debian structure and what is not offered by cydia.
#                :You can save the current versions of your packages without any major hassle and without the fear that you will update a tweak and will not
#                :be able to "downgrade" to a lower and compatible version.
#author          :T.Herak
#date            :20150709
#version         :0.8
#depends         :dpkg, gawk, sed, bash, coreutils, coreutils-bin
#usage           :./redeb.sh <tweak bundle id>
#notes           :Use at your own risk.
#updates         :v. 0.5 : first version which was put to github
#                :v. 0.6 : added some cleansing after the packages are redebed, changed the structure of log files and deb files to Documents/Redeb
#                :v. 0.7 : possibility to list packade bundle IDs, if those are unknown for the user
#                :v. 0.8 : minor code corrections, mainly related to the output and command prompts during the script runtime
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
# Functions
function usage()
{
      echo -e  "You didn't insert any package ID,do you want me to list all your available packages (y/n)? : \c"
      read listPackages
        case "$listPackages" in
          y|Y)
              dpkg --get-selections | awk '{print $1}' | sort -n

              echo -e "Please select the Package BundleID from the list and paste it here followed by Return key : \c"
              read packageID
              BUNDLEID="$packageID"
              #echo "$packageID" //just for testings purposes
              ;;
           *) echo "Please rerun the script with ./redeb.sh <package bundle id> or you might list the bundle IDs with starting this script again"
              exit 1
              ;;
        esac
}

#Let's see if the Redeb folder exists in /var/mobile/Documents and it will be created when needed
if [ -d /var/jb/var/mobile/Documents/Redeb ];
  then
    echo "/var/jb/var/mobile/Documents/Redeb exists, continuing ..."
else
  mkdir -p /var/jb/var/mobile/Documents/Redeb
fi

#logging
exec > >(tee /var/jb/var/mobile/Documents/Redeb/redeb.log)
exec 2>/var/jb/var/mobile/Documents/Redeb/redeb.err

#check syntax and possibly list bundle IDs if requested
if [ "$1" = "" ]; then
  usage
else
  BUNDLEID="$1"
fi

#define some variables
VERSION=`dpkg-query -s "$BUNDLEID" | grep Version | awk '{print $2}'`
DEB="$BUNDLEID"_"$VERSION".deb
export ROOTDIR="/var/jb/var/mobile/Documents/Redeb/packages/$BUNDLEID"
export DebsFolder="/var/jb/var/mobile/Documents/Redeb/debs"

#check for the debs dir, where the deb file will be moved after it is created
if [ -d "$DebsFolder" ]; then
        echo "Debs Folder detected..."
    else
        mkdir -pv $DebsFolder
        echo "Debs Folder created ..."
fi
sleep 1


#check if the root directory for repackaging already exists
if [ -d "$ROOTDIR" ]; then
        echo "Root directory for repackaging already exists, moving to next step..."
   else
        mkdir -pv $ROOTDIR
        echo "Creating directory for repackaging..."
fi
sleep 1

#check debian folder in root directory
if [ -d "$ROOTDIR"/DEBIAN/ ]; then
  echo "DEBIAN directory for controlfile detected, moving ..."
else
  mkdir $ROOTDIR/DEBIAN/
        echo "DEBIAN folder created"
fi
sleep 1

#create control file for repackaging
#/usr/bin/dpkg-query -s "$BUNDLEID" | grep -v Status>>"$ROOTDIR"/DEBIAN/control

if [ -f "$ROOTDIR"/DEBIAN/control ]; then
     echo "Control File detected, moving.."
else
     echo "Control File is being created..."
     /usr/bin/dpkg-query -s "$BUNDLEID" | grep -v Status>>"$ROOTDIR"/DEBIAN/control
     sleep 1
        if [ -f "$ROOTDIR"/DEBIAN/control ]; then
          echo "Control file created successfully"
        fi
fi

#list files related to bundle id into a variable which will be ran in a loop to determine the folder structure and its files which
#are mandatory for recreating of the DEB package

for i in $(/usr/bin/dpkg-query -L "$BUNDLEID"|sed "1 d")
do
  if [ -d "$i" ]
  then
    newdirpath=`echo "$ROOTDIR$i"`
    mkdir $newdirpath
  elif [ -f "$i" ]
  then
    newfilepath=`echo "$ROOTDIR$i"`
    cp -p $i $newfilepath
   fi
done

#Finaly build some fucking deb file
echo "Making some last checks if there is everything prepared for the \"redeb\""
sleep 1

if [[ -d "$ROOTDIR"/DEBIAN && -f "$ROOTDIR"/DEBIAN/control ]]; then
echo  "$ROOTDIR/DEBIAN detected..."
sleep 1
echo " Control file detected..."
echo -n \.
fi
sleep 2

echo "Building the package into $DEB"
dpkg-deb -b $ROOTDIR $DEB

echo "Cleaning temp files used for packaging"
if [[ -f "$DEB" && -d "$ROOTDIR" ]];then
  echo "$DEB is created, now cleaning the temp files..."
  mv $DEB $DebsFolder/$DEB
  rm -r $ROOTDIR
fi
echo "Done!"
echo "Your new repackaged DEB file is located at $DebsFolder/$DEB"
#######!! TODO !! As the last step, there is a comparision between the "redebed" package and the contents of the actually installed one