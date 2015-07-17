#! /bin/bash

#=========================================================================
# Copyright (C) VMware, Inc. 1986-2011.  All Rights Reserved.
# Copyright (c) 2013-2014 GemTalk Systems, LLC <dhenrich@gemtalksystems.com>.
#
# Name - installGemstone.sh <gemstone version (e.g., 3.1.0.1)>
#
# Purpose - Automatically download and install a Linux or Mac version of GemStone
#
# Description:
#    Does a basic install of GemStone for a developer on Mac or Linux
#    Setup for manual GemStone startup rather than automatic startup upon boot
#    Safe to run multiple times, as it will not overwrite existing data
#    Requires root access (using sudo) to change setings and create directories
#
# Actions:
#    Verify machine is capable of running GemStone 64-bit
#    Add shared memory setup to /etc/sysctl.conf
#    Add GemStone netldi service port to /etc/services
#    Create /opt/gemstone directory tree
#    Download the GemStone product zipfile
#    Uncompress the GemStone zipfile into /opt/gemstone/
#    Soft link the GemStone directory to /opt/gemstone/product
#    Copy the initial Seaside repository to data directory
#    Print build version information and available IPv4 addresses
#    Remind user to source defSeaside
#=========================================================================

set -e # exit on error
# Change these to change the specific version that will be installed
# and the download location on Amazon S3.
if [ "$1x" = "x" ] ; then
  echo "installGemstone.sh <gemstone version (e.g., 3.1.0.1)>"
  exit 1
fi 
vers="$1"
echo "Installing GemStone/S $vers"
bucket=$vers
# You shouldn't need to change anything else.

# Detect operating system
PLATFORM="`uname -sm | tr ' ' '-'`"
# Macs with Core i7 use the same software as older Macs
[ $PLATFORM = "Darwin-x86_64" ] && PLATFORM="Darwin-i386"

# Check we're on a suitable 64-bit machine and set gsvers
case "$PLATFORM" in
    Darwin-i386)
    OSVERSION="`sw_vers -productVersion`"
    MAJOR="`echo $OSVERSION | cut -f1 -d.`"
    MINOR="`echo $OSVERSION | cut -f2 -d.`"
    CPU_CAPABLE="`sysctl hw.cpu64bit_capable | cut -f2 -d' '`"
    #
    # Check the CPU and Mac OS X profile.
    if [[ $CPU_CAPABLE -ne 1 || $MAJOR -lt 10 || $MINOR -lt 5 ]] ; then
        echo "[Error] This script requires Mac OS X 10.5 or later on a 64-bit Intel CPU."
        exit 1
    fi
    gsvers="GemStone64Bit${vers}-i386.Darwin"
    ;;
    Linux-x86_64)
    # Linux looks OK
    gsvers="GemStone64Bit${vers}-x86_64.Linux"
    ;;
    *)
    echo "[Error] This script only works on a 64-bit Linux or Mac OS X machine"
    echo "The result from \"uname -sm\" is \"`uname -sm`\""
    exit 1
    ;;
esac

# set zipfile name from gsvers
gss_file=${gsvers}.zip

# set ftp_address
case "$vers" in
  2.4.4.2|2.4.4.3|2.4.4.4|2.4.4.5|2.4.4.6)
    ftp_address=ftp://ftp.gemstone.com
    ;;
  3.0.0)
    ftp_address=ftp://ftp.gemstone.com
    ;;
  3.1.0|3.1.0.1)
    ftp_address=ftp://ftp.gemstone.com
    ;;
  *)
    ftp_address=http://ftp.gemtalksystems.com:80
    ;;
esac

# We should run this as a normal user, not root.
if [ `id | cut -f2 -d= | cut -f1 -d\(` -eq 0 ]
    then
    echo "[Error] This script must be run as a normal user, not root."
    echo "However, some steps require root access using sudo."
    exit 1
fi

# Check that the current directory is writable
if [ ! -w "." ]
    then
    echo "[Error] This script requires write permission on your current directory."
    /bin/ls -ld "`pwd`"
    exit 1
fi

# We're good to go. Let user know.
machine_name="`uname -n`"
echo "[Info] Starting installation of $gsvers on $machine_name"

# Do a trivial sudo to test we can and get the password prompt out of the way
# sudo date

echo "[Info] Setting up shared memory"
# Ref: http://developer.postgresql.org/pgdocs/postgres/kernel-resources.html
# Ref: http://www.idevelopment.info/data/Oracle/DBA_tips/Linux/LINUX_8.shtml

case "$PLATFORM" in
    Linux-x86_64)
    # use TotalMem: kB because Ubuntu doesn't have Mem: in Bytes
    totalMemKB=`awk '/MemTotal:/{print($2);}' /proc/meminfo`
    totalMem=$(($totalMemKB * 1024))
    # Figure out the max shared memory segment size currently allowed
    shmmax=`cat /proc/sys/kernel/shmmax`
    # Figure out the max shared memory currently allowed
    shmall=`cat /proc/sys/kernel/shmall`
    ;;
    Darwin-i386)
    totalMem="`sysctl hw.memsize | cut -f2 -d' '`"
    # Figure out the max shared memory segment size currently allowed
    shmmax="`sysctl kern.sysv.shmmax | cut -f2 -d' '`"
    # Figure out the max shared memory currently allowed
    shmall="`sysctl kern.sysv.shmall | cut -f2 -d' '`"
    ;;
    *)
    echo "[Error] Can't determine operating system. Check script."
    exit 1
    ;;
esac
totalMemMB=$(($totalMem / 1048576))
shmmaxMB=$(($shmmax / 1048576))
shmallMB=$(($shmall / 256))

# Print current values
echo "  Total memory available is $totalMemMB MB"
echo "  Max shared memory segment size is $shmmaxMB MB"
echo "  Max shared memory allowed is $shmallMB MB"

# Figure out the max shared memory segment size (shmmax) we want
# Use 75% of available memory but not more than 2GB
shmmaxNew=$(($totalMem * 3/4))
[ $shmmaxNew -gt 2147483648 ] && shmmaxNew=2147483648
shmmaxNewMB=$(($shmmaxNew / 1048576))

# Figure out the max shared memory allowed (shmall) we want
# The MacOSX default is 4MB, way too small
# The Linux default is 2097152 or 8GB, so we should never need this
# but things will certainly break if it's been reset too small
# so ensure it's at least big enough to hold a fullsize shared memory segment
shmallNew=$(($shmmaxNew / 4096))
[ $shmallNew -lt $shmall ] && shmallNew=$shmall
shmallNewMB=$(($shmallNew / 256))

# Increase shmmax if appropriate
if [ $shmmaxNew -gt $shmmax ]; then
    echo "[Info] Increasing max shared memory segment size to $shmmaxNewMB MB"
    [ $PLATFORM = "Darwin-i386" ] && sysctl -w kern.sysv.shmmax=$shmmaxNew
    [ $PLATFORM = "Linux-x86_64" ] && bash -c "echo $shmmaxNew > /proc/sys/kernel/shmmax"
else
    echo "[Info] No need to increase max shared memory segment size"
fi

# Increase shmall if appropriate
if [ $shmallNew -gt $shmall ]; then
    echo "[Info] Increasing max shared memory allowed to $shmallNewMB MB"
    [ $PLATFORM = "Darwin-i386" ] && sysctl -w kern.sysv.shmall=$shmallNew
    [ $PLATFORM = "Linux-x86_64" ] && bash -c "echo $shmallNew > /proc/sys/kernel/shmall"
else
    echo "[Info] No need to increase max shared memory allowed"
fi

# At this point, shared memory settings contain the values we want, 
# put them in sysctl.conf so they are preserved.
if [[ ! -f /etc/sysctl.conf || `grep -sc "kern.*.shm" /etc/sysctl.conf` -eq 0 ]]; then
    case "$PLATFORM" in
        Linux-x86_64)
        echo "# kernel.shm* settings added by MagLev installation" > /tmp/sysctl.conf.$$
        echo "kernel.shmmax=`cat /proc/sys/kernel/shmmax`" >> /tmp/sysctl.conf.$$
        echo "kernel.shmall=`cat /proc/sys/kernel/shmall`" >> /tmp/sysctl.conf.$$
        ;;
        Darwin-i386)
        # On Mac OS X Leopard, you must have all five settings in sysctl.conf
        # before they will take effect.
        echo "# kern.sysv.shm* settings added by MagLev installation" > /tmp/sysctl.conf.$$
        sysctl kern.sysv.shmmax kern.sysv.shmall kern.sysv.shmmin kern.sysv.shmmni \
        kern.sysv.shmseg  | tr ":" "=" | tr -d " " >> /tmp/sysctl.conf.$$
        ;;
        *)
        echo "[Error] Can't determine operating system. Check script."
        exit 1
        ;;
    esac
    #
    echo "[Info] Adding the following section to /etc/sysctl.conf"
    cat /tmp/sysctl.conf.$$
    bash -c "cat /tmp/sysctl.conf.$$ >> /etc/sysctl.conf"
    /bin/rm -f /tmp/sysctl.conf.$$
else
    echo "[Info] The following shared memory settings already exist in /etc/sysctl.conf"
    echo "To change them, remove the following lines from /etc/sysctl.conf and rerun this script"
    grep "kern.*.shm" /etc/sysctl.conf
fi

# Now setup for NetLDI in case we ever need it.
echo "[Info] Setting up GemStone netldi service port"
if [ `grep -sc "^gs64ldi" /etc/services` -eq 0 ]; then
    echo '[Info] Adding "gs64ldi  50377/tcp" to /etc/services'
    bash -c 'echo "gs64ldi         50377/tcp        # Gemstone netldi"  >> /etc/services'
else
    echo "[Info] GemStone netldi service port is already set in /etc/services"
    echo "To change it, remove the following line from /etc/services and rerun this script"
    grep "^gs64ldi" /etc/services
fi

# Look for either wget to download GemStone
if [ -e "`which wget`" ]; then
    cmd="`which wget`"
else
    echo "[Error] wget is not available. Install wget and rerun this script."
    exit 1
fi

# Download GemStone
if [ ! -e $gss_file ]; then
    echo "[Info] Downloading $gss_file using ${cmd}"
    $cmd ${ftp_address}/pub/GemStone64/$bucket/$gss_file
else
    echo "[Info] $gss_file already exists"
    echo "to replace it, remove or rename it and rerun this script"
fi

# Create some directories that GemStone expects; make them writable
echo "[Info] Creating /opt/gemstone directory"
if [ ! -e /opt/gemstone ]
    then
    mkdir -p /opt/gemstone /opt/gemstone/log /opt/gemstone/locks
    chown $USER:${GROUPS[0]} /opt/gemstone /opt/gemstone/log /opt/gemstone/locks
    chmod 770 /opt/gemstone /opt/gemstone/log /opt/gemstone/locks
else
    echo "[Warning] /opt/gemstone directory already exists"
    echo "to replace it, remove or rename it and rerun this script"
fi

# Unzip the downloaded archive into /opt/gemstone/
echo "[Info] Uncompressing GemStone archive into /opt/gemstone/"
if [ ! -e /opt/gemstone/$gsvers ]
    then
    unzip -q -d /opt/gemstone $gss_file
else
    echo "[Warning] /opt/gemstone/$gsvers already exists"
    echo "to replace it, remove or rename it and rerun this script"
fi

# Soft link the new GemStone installation to /opt/gemstone/product
echo "[Info] Linking /opt/gemstone/$gsvers to /opt/gemstone/product" 
if [ ! -e /opt/gemstone/product ]
    then
    ln -sf /opt/gemstone/$gsvers /opt/gemstone/product
else
    if [ ! -h /opt/gemstone/product ]
        then
        # Stop now if /opt/gemstone/product isn't a symlink
        # it might be a prior installation, so exercise caution
        echo "[Error] /opt/gemstone/product already exists and is not a symbolic link"
        echo "remove or rename it and rerun this script"
        echo "WARNING - $gsvers installation not completed"
        exit 1
    fi
    echo "[Warning] symbolic link /opt/gemstone/product already exists"
    echo "to replace it, remove or rename it and rerun this script"
fi

# Copy initial system.conf into the Seaside data directory
echo "[Info] Copying initial system.conf to data directory"
if [ ! -e /opt/gemstone/product/seaside/data/system.conf ]
    then
    cp /opt/gemstone/product/seaside/system.conf \
        /opt/gemstone/product/seaside/data
    chmod 644 /opt/gemstone/product/seaside/data/system.conf
else
    echo "[Warning] /opt/gemstone/product/seaside/data/system.conf already exists"
    echo "to replace it, remove or rename it and rerun this script"
fi

# Copy an initial extent to the Seaside data directory
echo "[Info] Copying initial Seaside repository to data directory"
if [ ! -e /opt/gemstone/product/seaside/data/extent0.dbf ]
    then
    cp /opt/gemstone/product/bin/extent0.seaside.dbf \
        /opt/gemstone/product/seaside/data/extent0.dbf
    chmod 644 /opt/gemstone/product/seaside/data/extent0.dbf
else
    echo "[Warning] /opt/gemstone/product/seaside/data/extent0.dbf already exists"
    echo "to replace it, remove or rename it and rerun this script"
fi

echo "[Info] Finished $gsvers installation on $machine_name"
echo ""
echo "[Info] GemStone version information:"
cat /opt/gemstone/product/version.txt

# If we can determine any IPv4 addresses, print them out. Otherwise be silent.
if [[ -x /sbin/ifconfig && `/sbin/ifconfig -a | grep -sc " inet addr:.*Bcast"` -gt 0 ]]
    then
    echo ""
    echo "[Info] $machine_name has the following IPv4 addresses:"
    /sbin/ifconfig -a | grep ' inet addr:.*Bcast' | cut -f2 -d: | cut -f1 -d' '
fi

# Reminder to setup environment variables
echo ""
echo "[Info] Remember to set GEMSTONE environment variables by running:"
echo "source /opt/gemstone/product/seaside/defSeaside"

# End of script
exit 0
