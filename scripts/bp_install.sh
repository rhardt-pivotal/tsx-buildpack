#!/bin/bash
# TimeShiftX
# Copyright (C) 2013-2020 Vornex Inc.
# This is the installation script for tsx for Linux
# run it as root then reboot the system

# set -e
set -x



checkSysVersion() {
	# OSsubName: RedHat, SUSE, System_z, Debian, Ubuntu
	
	OSname=`uname`
	
	if [ -f /etc/redhat-release ] ; then
		REV=`cat /etc/redhat-release | sed s/.*release\ // | cut -d. -f1`
		OSsubName=-RedHat${REV}
	elif [ -f /etc/SuSE-release ] ; then
		REV=`cat /etc/SuSE-release | grep VERSION | sed s/.*=\ //`
		OSsubName=-SUSE${REV}
	elif [ `uname -i` = "s390x" ];then
		OSsubName=-System_z
	elif [ -f /etc/lsb-release ] ; then
		REV=`cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -d= -f2 | cut -d. -f1`
		OSsubName=-Ubuntu${REV}
		OStype=Debian
	elif [ -f /etc/debian_version ] ; then
		REV=`cat /etc/debian_version | cut -d. -f 1`
		OSsubName=-Debian${REV}
		OStype=Debian
	else
		OSsubName=-Unknown
	fi

	OSversion=
	
	OSarch=
	
	SysVersion=${OSname}${OSsubName}${OSversion}${OSarch}
	if [ "$SysVersion" != "Linux-Ubuntu18" ];then
		echo " Error: This program can only be installed on Linux-Ubuntu18"
		echo "        The current system is $SysVersion"
		retval=1
	else
		retval=0
	fi
}

checkSysVersion
if [ "$retval" != 0 ];then
	if [ "$1" != "force" ];then
		echo " Installation cancelled."
		exit 3
	fi
fi

notfound=""
function checkDependenses() {
	la=$1
	ldlib=""
	if [ `uname -i` = "s390x" ];then
		ldlib=/lib${la}/ld${la}*.so.1
	else
		ldlib=/lib${la}/ld-linux*.so.2
	fi
	dependlibs="/lib${la}/libpthread*.so.0 /lib${la}/libdl*.so.2 /lib${la}/libc*.so.6 ${ldlib}"

	if [ "$1" = "64" ];then
		rlbit=64
	else
		rlbit=32
	fi

	if [ "${OStype}" = "Debian" ]; then
		if [ "$1" = "64" ];then
			dependlibs="/lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libdl.so.2"
		else
			dependlibs="/lib32/libpthread.so.0 /lib32/libdl.so.2"
		fi
	fi

	for lb in $dependlibs
	do 
		if [ ! -e $lb ]; then
			EXT="${lb##*\*}"
			FILE=$(basename "$lb" *$EXT)" ($rlbit bit)"
			notfound=$notfound$FILE"\n"
		fi
	done
}

ARCH=`getconf LONG_BIT`

function checkRequiredLibs() {
	checkDependenses
	if [ ${ARCH} = 64 ];then
		checkDependenses 64

		echo $notfound | grep -q "(64 bit)" > /dev/null
		if [ "$?" != "0" ];then
			if [ "$notfound" != "" ];then
				echo -e " WARNING: The following lib(s) are missing and required to time travel 32bit apps:\n$notfound"
				echo -e " If you only need to time travel 64bit apps then you can ignore this warning."
				retval=0
				return
			fi
		fi
	fi


	check=lib
	if [ "${notfound/$check}" != "$notfound" ]; then
		echo -e " The following lib(s) are required:\n$notfound"
		retval=1
	else
		retval=0
	fi
}

checkRequiredLibs
if [ "$retval" != 0 ];then
	if [ "$1" != "force" ];then
		echo -e " Installation cancelled."
		exit 2
	fi
fi

INSTALLED=installed
# check if already installed
tsx version 2>/dev/null  1>/dev/null
if [ $? = 0 ];then
	echo -e " Info: TimeShiftX is already installed. Please uninstall it first."
	echo -e " Installation cancelled."
	exit 2
fi



BPRootDir="$( cd "$(dirname "$0")" ; pwd -P )/.."

mkdir $BPRootDir/tsx


echo "*** running modified installer.  Installer dir: $1"

echo "Starting from $(pwd)"
ls -al


BaseDir=$BPRootDir/tsx
BinDir=$BaseDir/bin
LicenseDir=$BaseDir/license
LibDir=$BaseDir/lib
DataDir=$BaseDir/data
BackupDir=$BinDir/backup



InstallerDir=$1   # "$( cd "$(dirname "$0")" ; pwd -P )/"



rm -rf $BinDir $LibDir

mkdir -p $BinDir
mkdir -p $LicenseDir
mkdir -p $LibDir
mkdir -p $DataDir
mkdir -p $BackupDir

cp -f ${InstallerDir}/Readme.txt /home/vcap/tsx

if [ $? != 0 ];then
	echo " Installation cancelled."
	exit 2
fi

cp -f ${InstallerDir}tsxcpu.sh ${InstallerDir}tsxactivate.sh ${InstallerDir}tsxrehost.sh ${InstallerDir}tsxuninstall.sh ${InstallerDir}tsxsupport.sh $BinDir

if [ ${ARCH} = 64 ]
then
	cp -f ${InstallerDir}tsx32.so ${InstallerDir}tsx64.so $LibDir
	cp -f ${InstallerDir}tsx32 ${InstallerDir}tsx64 ${InstallerDir}testconsole32 ${InstallerDir}testconsole64 $BinDir
	cp -f ${InstallerDir}activate32 ${InstallerDir}activate64 $LicenseDir
	cp -f ${InstallerDir}_vnx_* $LicenseDir

	cp -f ${InstallerDir}tsx32 ${InstallerDir}tsx64 $BackupDir


	ln -fs $BinDir/testconsole64 $BinDir/testconsole
	ln -fs $BinDir/tsx64 $BinDir/tsx
	ln -fs $LicenseDir/activate64 $LicenseDir/activate
	ln -fs $LicenseDir/_vnx_rehost64 $LicenseDir/_vnx_rehost
else
	cp -f ${InstallerDir}tsx32.so $LibDir/tsx.so
	cp -f ${InstallerDir}tsx32 $BinDir/tsx
	cp -f ${InstallerDir}testconsole32 $BinDir/testconsole
	cp -f ${InstallerDir}activate32 $LicenseDir/activate
	cp -f ${InstallerDir}_vnx_rehost32 $LicenseDir/_vnx_rehost

	cp -f ${InstallerDir}tsx32 $BackupDir

fi

# create simlinks to binaries

OldMask=`umask`
umask 0
chmod a=rx $BaseDir/tsx
chmod a=r $BaseDir/tsx/*.txt
chmod -R a=rx $BinDir $LibDir $LicenseDir
chmod a=rwx $DataDir $LicenseDir
umask $OldMask

# suid progs for debian oses need to have s(g)uid bit
if [ "${OStype}" = "Debian" ]; then
	chmod +s $LibDir/tsx32.so
	chmod +s $LibDir/tsx64.so
fi



echo " Current running apps must be restarted one time to initially load TimeShiftX."

echo " Success: TimeShiftX is ${INSTALLED}."
