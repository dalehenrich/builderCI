#!/bin/bash -x
#
# GemStone GCI Test driver script for builderCI. Use with templates gci_travis.yml
#
#      -verbose flag causes unconditional transcript display
#
# Copyright (c) 2013 VMware, Inc. All Rights Reserved <dhenrich@vmware.com>.
# Copyright (C) 2014 GemTalk Systems LLC <dale.henrichs@gemtalksystems.com>
#

if [ -z "$TRAVIS_CONTAINER" ]; then
  #install 32 bit libs if necessary
  case "$(uname -m)" in
    "x86_64")
      echo "64bit os"
      # 32-bit gci libs
      sudo apt-get -qq update
      sudo apt-get install ia32-libs
     ;;
    *)
      echo "32bit os"
      ;;
  esac
fi

echo "====STARTING SERVER: $GemStone"
ST="$GemStone"
./build.sh -i $ST -m -n -f "$PROJECT_HOME/tests/gemstoneGCI.st" -o serverGCI
if [[ $? != 0 ]] ; then 
  echo "ERROR: $(basename $0)"
  cd "${BUILD_PATH}/serverGCI/"
  $BUILDER_CI_HOME/buildImageErrorCheck.sh # dump Transcript on error and exit
  if [[ $? != 0 ]] ; then exit 1; fi
  $BUILDER_CI_HOME/dumpTranscript.sh
  exit 1
fi
cd "${BUILD_PATH}/serverGCI/"
$BUILDER_CI_HOME/buildImageErrorCheck.sh # dump Transcript on error and exit
if [[ $? != 0 ]] ; then exit 1; fi
$BUILDER_CI_HOME/buildTravisStatusCheck.sh "$@" # dump Transcript on failed tests and exit
if [[ $? != 0 ]] ; then exit 1; fi
echo "====STARTING CLIENT: $CLIENT"
cd $BUILDER_CI_HOME
ST="$CLIENT"
# copy the gci libraries to the OUTPUT_PATH directory
mkdir -p $BUILD_PATH/clientGCI
cp /opt/gemstone/product/lib32/*.so $BUILD_PATH/clientGCI
ls /opt/gemstone/log
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
./build.sh -i $ST -d -m -f "$PROJECT_HOME/tests/clientGCI.st" -o clientGCI
if [[ $? != 0 ]] ; then 
  echo "ERROR: $(basename $0)"
  ls -altr $BUILD_PATH/clientGCI
  ls -altr /opt/gemstone/log
  cd "${BUILD_PATH}/clientGCI/"
  $BUILDER_CI_HOME/buildImageErrorCheck.sh # dump Transcript on error and exit
  if [[ $? != 0 ]] ; then exit 1; fi
  $BUILDER_CI_HOME/dumpTranscript.sh
  exit 1
fi
ls -altr $BUILD_PATH/clientGCI
ls -altr /opt/gemstone/log
cd "${BUILD_PATH}/clientGCI/"
$BUILDER_CI_HOME/buildImageErrorCheck.sh # dump Transcript on error and exit
if [[ $? != 0 ]] ; then exit 1; fi
$BUILDER_CI_HOME/buildTravisStatusCheck.sh "$@" # dump Transcript on failed tests and exit
if [[ $? != 0 ]] ; then exit 1; fi
