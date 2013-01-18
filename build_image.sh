#!/bin/bash -x
#
# build_image.sh -- Downloads and installs the desired Smalltalk
#   installation: PharoCore-1-3, Pharo-1.4, Squeak-4.3, Squeak-4.4
#
# Copyright (c) 2012 VMware, Inc. All Rights Reserved <dhenrich@vmware.com>.
#

# Environment variables defined in .travis.yml
#
# Copyright (c) 2012 VMware, Inc. All Rights Reserved <dhenrich@vmware.com>.
#

#install 32 bit libs if necessary
case "$(uname -m)" in
        "x86_64")
                echo "64bit os"
                sudo apt-get -qq install libc6:i386
                ;;
        *)
                echo "32 vit os"
                ;;
esac

IMAGE_BASE_NAME=$ST
IMAGE_TARGET_NAME=$ST

case "$ST" in

  # PharoCore-1.0
  PharoCore-1.0)
    cd $IMAGES_PATH
    wget -q https://gforge.inria.fr/frs/download.php/26832/PharoCore-1.0.zip
    unzip PharoCore-1.0.zip
    cd PharoCore-1.0
  ;;
  # PharoCore-1.1
  PharoCore-1.1)
    cd $IMAGES_PATH
    wget -q https://gforge.inria.fr/frs/download.php/28341/PharoCore-1.1.2.zip
    unzip PharoCore-1.1.2.zip
    cd PharoCore-1.1.2
    IMAGE_BASE_NAME=PharoCore-1.1.2-11422
  ;;
  # PharoCore-1.2
  PharoCore-1.2)
    cd $IMAGES_PATH
    wget -q https://gforge.inria.fr/frs/download.php/28553/PharoCore-1.2.2-12353.zip
    unzip PharoCore-1.2.2-12353
    cd PharoCore-1.2.2-12353
    IMAGE_BASE_NAME=PharoCore-1.2.2-12353
  ;;
  # PharoCore-1.3
  PharoCore-1.3)
    cd $IMAGES_PATH
    wget -q https://gforge.inria.fr/frs/download.php/30567/PharoCore-1.3-13328.zip
    unzip PharoCore-1.3-13328.zip
    cd PharoCore-1.3
  ;;
  # Pharo-1.4
  Pharo-1.4)
    cd $IMAGES_PATH
    wget -q https://gforge.inria.fr/frs/download.php/31259/Pharo-1.4-14557.zip
    unzip Pharo-1.4-14557
    cd Pharo-1.4
  ;;
  # Pharo-2.0
  Pharo-2.0)
    cd $IMAGES_PATH
    wget -q https://ci.lille.inria.fr/pharo/view/Pharo%202.0/job/Pharo-2.0/lastSuccessfulBuild/artifact/Pharo-2.0.zip
    unzip Pharo-2.0.zip
    cd Pharo-2.0
  ;;
  # Squeak-4.3 ... allow Squeak4.3 for backwards compatibility
  Squeak-4.3|Squeak4.3)
    cd $IMAGES_PATH
    wget -q http://ftp.squeak.org/4.3/Squeak4.3.zip
    unzip Squeak4.3.zip
    cd Squeak4.3
    wget -q http://ftp.squeak.org/4.1/SqueakV41.sources.gz
    gunzip SqueakV41.sources.gz
    IMAGE_BASE_NAME=Squeak4.3
    ;;
  # Squeak-4.4
  Squeak-4.4)
    cd $IMAGES_PATH
    wget -q http://www.squeakci.org/job/SqueakTrunk/lastSuccessfulBuild/artifact/target/*zip*/target.zip
    unzip target.zip
    cd target
    wget -q http://ftp.squeak.org/4.1/SqueakV41.sources.gz
    gunzip SqueakV41.sources.gz
    IMAGE_BASE_NAME=TrunkImage
    ;;

  # unknown
  \?) echo "Unknown Smalltalk version ${ST}"
    exit 1
  ;;
  esac

# move the image components into the correct location
mv *.sources $SOURCES_PATH
mv ${IMAGE_BASE_NAME}.changes ../${IMAGE_TARGET_NAME}.changes
mv ${IMAGE_BASE_NAME}.image ../${IMAGE_TARGET_NAME}.image

# success
exit 0
