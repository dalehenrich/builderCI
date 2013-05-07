#!/bin/bash
#
# build_client.sh -- Builds Pharo images using a series of Smalltalk
#   scripts. Best to be used together with Jenkins.
#
# Copyright (c) 2010 Yanni Chiu <yanni@rogers.com>
# Copyright (c) 2010-2011 Lukas Renggli <renggli@gmail.com>
# Copyright (c) 2012 VMware, Inc. All Rights Reserved <dhenrich@vmware.com>.
#

# Environment variables now defined in .travis.yml

# vm configuration
case "$(uname -s)" in
	"Linux")
		PHARO_VM="$VM_PATH/Linux/squeak"
		PHARO_PARAM="-nodisplay \
      -nosound \
      -plugins "$VM_PATH/Linux" \
	    -encoding latin1"
		;;
	"Darwin")
		PHARO_VM="$VM_PATH/MacOS/Squeak VM Opt"
		PHARO_PARAM="-headless"
		;;
	"Cygwin")
		PHARO_VM="$VM_PATH/Windows/Squeak.exe"
		PHARO_PARAM="-headless"
		;;
	*)
		echo "$(basename $0): unknown platform $(uname -s)"
		exit 1
		;;
esac
if [ -f "$IMAGES_PATH/pharo" ] ; then
	# Use Pharo generic script to run the VM (since Pharo2)
    PHARO_VM="$IMAGES_PATH/pharo"
    PHARO_PARAM=
fi

# build configuration
BEFORE_SCRIPTS=("$SCRIPTS_PATH/before.st")

# help function
function display_help() {
	echo "$(basename $0) -i input -o output {-m} {-s script} {-d} {-f full-path-to-script} {-X}"
  echo " -d skip delete of OUTPUT_PATH"
  echo " -f one or more scripts (full path) to build the image, can be intermixed with -m and -s options"
	echo " -i input product name, image from images-directory, or successful jenkins build"
	echo " -m use Metacello test harness: FileTree, Metacello, travisCIHarness.st, can be intermixed with -f and -s options"
	echo " -o output product name"
	echo " -s one or more scripts from the scripts-directory to build the image, can be intermixed with -m and -f options"
  echo " -X do not bootstrap metacello into the image"
}

echo "PROCESSING OPTIONS"

# parse options
BOOTSTRAP_METACELLO=include
DELETE_OUTPUT_PATH=true
while getopts ":i:mXdo:f:s:?" OPT ; do
	case "$OPT" in

    # skip delete of OUTPUT_PATH
    d) DELETE_OUTPUT_PATH=false
    ;;
		# full path to script
	  f)	if [ -f "$OPTARG" ] ; then
                SCRIPTS=("${SCRIPTS[@]}" "$OPTARG")
			else
				echo "$(basename $0): invalid script ($OPTARG)"
				exit 1
			fi
		;;

		# input
		i)	if [ -f "$BUILD_PATH/$OPTARG/$OPTARG.image" ] ; then
				INPUT_IMAGE="$BUILD_PATH/$OPTARG/$OPTARG.image"
			elif [ -f "$BUILD_PATH/$OPTARG.image" ] ; then
				INPUT_IMAGE="$BUILD_PATH/$OPTARG.image"
			elif [ -f "$IMAGES_PATH/$OPTARG/$OPTARG.image" ] ; then
				INPUT_IMAGE="$IMAGES_PATH/$OPTARG/$OPTARG.image"
			elif [ -f "$IMAGES_PATH/$OPTARG.image" ] ; then
				INPUT_IMAGE="$IMAGES_PATH/$OPTARG.image"
			elif [ -n "$WORKSPACE" ] ; then
				INPUT_IMAGE=`find -L "$WORKSPACE/../.." -name "$OPTARG.image" | grep "/lastSuccessful/" | head -n 1`
			fi

			if [ ! -f "$INPUT_IMAGE" ] ; then
				echo "$(basename $0): input image not found ($OPTARG)"
				exit 1
			fi

			INPUT_CHANGES="${INPUT_IMAGE%.*}.changes"
			if [ ! -f "$INPUT_CHANGES" ] ; then
				echo "$(basename $0): input changes not found ($INPUT_CHANGES)"
				exit 1
			fi
		;;

    # include standard Metacello test harness
    m) SCRIPTS=("${SCRIPTS[@]}" "$SCRIPTS_PATH/travisCIHarness.st" )
    ;; 

		# output
		o)	OUTPUT_NAME="$OPTARG"
			OUTPUT_PATH="$BUILD_PATH/$OUTPUT_NAME"
			OUTPUT_ZIP="$BUILD_PATH/$OUTPUT_NAME.zip"
			OUTPUT_SCRIPT="$OUTPUT_PATH/$OUTPUT_NAME.st"
			OUTPUT_IMAGE="$OUTPUT_PATH/$OUTPUT_NAME.image"
			OUTPUT_CHANGES="$OUTPUT_PATH/$OUTPUT_NAME.changes"
			OUTPUT_CACHE="$OUTPUT_PATH/package-cache"
      case "$ST" in
        Squeak*) 
          OUTPUT_DEBUG="$OUTPUT_PATH/SqueakDebug.log"
          ;; 
        Pharo*) 
          OUTPUT_DEBUG="$OUTPUT_PATH/PharoDebug.log" 
          ;;
      esac
			OUTPUT_DUMP="$OUTPUT_PATH/crash.dmp"
		;;

		# script
		s)	if [ -f "$SCRIPTS_PATH/$OPTARG" ] ; then
                SCRIPTS=("${SCRIPTS[@]}" "$SCRIPTS_PATH/$OPTARG")
			else
				echo "$(basename $0): invalid script ($OPTARG)"
				exit 1
			fi
		;;

    X) BOOTSTRAP_METACELLO=exclude
    ;;

		# show help
		\?)	display_help
			exit 1
		;;

	esac
done

# check required parameters
if [ -z "$INPUT_IMAGE" ] ; then
	echo "$(basename $0): no input product name given"
	exit 1
fi

if [ -z "$OUTPUT_IMAGE" ] ; then
	echo "$(basename $0): no output product name given"
	exit 1
fi

echo "BUILDING IMAGE FILE"

#prepare output path
if [ "$DELETE_OUTPUT_PATH" == true ] ; then
  if [ -d "$OUTPUT_PATH" ] ; then
	  rm -rf "$OUTPUT_PATH"
  fi
fi

mkdir -p "$OUTPUT_PATH"
mkdir -p "$BUILD_CACHE/${JOB_NAME:=$OUTPUT_NAME}"
ln -sf "$BUILD_CACHE/${JOB_NAME:=$OUTPUT_NAME}" "$OUTPUT_CACHE"

# prepare image file and sources
cp "$INPUT_IMAGE" "$OUTPUT_IMAGE"
cp "$INPUT_CHANGES" "$OUTPUT_CHANGES"
find "$SOURCES_PATH" -name "*.sources" -exec ln -f "{}" "$OUTPUT_PATH/" \;

# hook up the git_cache, Metacello bootstrap and mcz repo

ln -sf "$GIT_PATH" "$OUTPUT_PATH/"
ln -sf "$BUILDER_CI_HOME/mcz" "$OUTPUT_PATH/"
ln -sf "$BUILDER_CI_HOME/scripts/Metacello-Base.st" "$OUTPUT_PATH/"
ln -sf "$BUILDER_CI_HOME/scripts/FileStream-show.st" "$OUTPUT_PATH/"
ln -sf "$BUILDER_CI_HOME/scripts/MetacelloBuilderTravisCI.st" "$OUTPUT_PATH/"

# prepare script file
if [ "$BOOTSTRAP_METACELLO" == include ] ; then
  BEFORE_SCRIPTS=("${BEFORE_SCRIPTS[@]}" "$SCRIPTS_PATH/bootstrapMetacello.st")
else
  BEFORE_SCRIPTS=("${BEFORE_SCRIPTS[@]}" "$SCRIPTS_PATH/bootstrapGofer.st")
fi
SCRIPTS=("${BEFORE_SCRIPTS[@]}" "${SCRIPTS[@]}" "$SCRIPTS_PATH/after.st")

for FILE in "${SCRIPTS[@]}" ; do
	cat "$FILE" >> "$OUTPUT_SCRIPT"
	echo "!" >> "$OUTPUT_SCRIPT"
done

#feedback about system being used ... 64 bit  vms created headaches
uname -a

echo "RUNNING TESTS..."

# build image in the background
exec "$PHARO_VM" $PHARO_PARAM "$OUTPUT_IMAGE" "$OUTPUT_SCRIPT" &
pid="$!"

# wait for the process to terminate, or a debug log
if [ $pid ] ; then
	COUNTER=1
	while kill -0 $pid 2> /dev/null ; do
		if [ -f "$OUTPUT_DUMP" ] || [ -f "$OUTPUT_DEBUG" ] ; then
			sleep 5
			kill -s SIGKILL $pid 2> /dev/null
			if [ -f "$OUTPUT_DUMP" ] ; then
				echo "$(basename $0): VM aborted ($PHARO_VM)"
				cat "$OUTPUT_DUMP" | tr '\r' '\n' | sed 's/^/  /'
				exit 1
			elif [ -f "$OUTPUT_DEBUG" ] ; then
				echo "$(basename $0): Execution aborted ($PHARO_VM)"
			#	cat "$OUTPUT_DEBUG" | tr '\r' '\n' | sed 's/^/  /'
				exit 0
			fi
		fi
		sleep 1
		COUNTER=$[$COUNTER +1]
		if (( "$COUNTER" > 1800)); then
                  	echo "$(basename $0): has take over 30 minutes before finishing ... terminating job"
			exit 1
		fi
		let "tictoc = $COUNTER % 60"
		if [ "$tictoc" -eq 0 ] ; then
               		echo "travis ... be patient PLEASE: https://github.com/dalehenrich/builderCI/issues/38"
                fi 
	done
        wait $pid
        exitStatus=$?
        echo "VM exit status: $exitStatus " 
        if [[ "$exitStatus" != "0" ]] ; then
          echo "$(basename $0): error during VM execution ($PHARO_VM) "
          exit $exitStatus
        fi
else
	echo "$(basename $0): unable to start VM ($PHARO_VM)"
	exit 1
fi
# remove cache link
rm -rf "$OUTPUT_CACHE" "$OUTPUT_ZIP"
(
	cd "$OUTPUT_PATH"
	rm -f *.sources
)

# success
exit 0
