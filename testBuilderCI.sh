#!/bin/bash -x
#
# Test driver script for builderCI itself
#
# Copyright (c) 2012 VMware, Inc. All Rights Reserved <dhenrich@vmware.com>.
#

#run tests
./testTravisCI.sh
if [[ $? != 0 ]] ; then exit 1; fi

# make sure that system runs okay when you skip the metacello bootstrap step
cd $BUILDER_CI_HOME
./build.sh -i $ST -X -f "$BUILDER_CI_HOME/tests/skipMetacelloBootstrap.st" -o travisCI
if [[ $? != 0 ]] ; then exit 1; fi
cd "${BUILD_PATH}/travisCI/"
$BUILDER_CI_HOME/buildImageErrorCheck.sh
if [[ $? != 0 ]] ; then exit 1; fi
$BUILDER_CI_HOME/buildTravisStatusCheck.sh 
if [[ $? != 0 ]] ; then exit 1; fi
cat TravisTranscript.txt
