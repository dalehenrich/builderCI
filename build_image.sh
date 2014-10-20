#!/bin/bash
#
# build_image.sh -- Downloads and installs the desired Smalltalk
#
# Copyright (c) 2012,2013 VMware, Inc. All Rights Reserved <dhenrich@vmware.com>.
# Copyright (c) 2013-2014 GemTalk Systems, LLC <dhenrich@gemtalksystems.com>.
#

# Environment variables defined in .travis.yml
#
# Copyright (c) 2012,2013 VMware, Inc. All Rights Reserved <dhenrich@vmware.com>.
#

case "$ST" in

  PharoCore-1.0|PharoCore-1.1|PharoCore-1.2|PharoCore-1.3|Pharo-1.4|Pharo-2.0|Pharo-3.0|Pharo-4.0|Squeak-4.3|Squeak4.3|Squeak-4.4|Squeak-4.5|Squeak-Trunk)
	./build_client_image.sh
	if [[ $? != 0 ]] ; then exit 1; fi
        exit 0
  ;;
  GemStone-2.4.*)
        GEMSTONE_VERSION_NAME="${ST:9}"
        KEY_PATH="./gemstone/GemStone64Bit2.4.0-x86_64.Linux.key"
 ;;
  GemStone-3.0.1)
        GEMSTONE_VERSION_NAME="3.0.1"
        KEY_PATH="./gemstone/GemStone64Bit3.0.0-x86_64.Linux.key"
 ;;
  GemStone-3.1.0.*)
        GEMSTONE_VERSION_NAME="${ST:9}"
        KEY_PATH="./gemstone/GemStone64Bit3.1.0-x86_64.Linux.key"
 ;;
  GemStone-3.2.*)
        GEMSTONE_VERSION_NAME="${ST:9}"
        KEY_PATH="./gemstone/GemStone64Bit3.2.0-x86_64.Linux.key"
 ;;


  # unknown
  *) echo "Unknown Smalltalk version ${ST}"
    exit 1
  ;;
esac

# only GemStone gets here
# uname -a 
./installGemstone.sh $GEMSTONE_VERSION_NAME
if [[ $? != 0 ]] ; then exit 1; fi
source /opt/gemstone/product/seaside/defSeaside #set GemStone environment variables
chmod +w  /opt/gemstone/product/seaside/etc/gemstone.key
cp $KEY_PATH /opt/gemstone/product/seaside/etc/gemstone.key
cat - >> /opt/gemstone/product/seaside/data/system.conf << EOF
# not needed for 3.1.x not debugging and ignored by 2.4.x
GEM_NATIVE_CODE_ENABLED = TRUE;
EOF


startGemstone
# gslist -lc
# cat /opt/gemstone/log/seaside.log


