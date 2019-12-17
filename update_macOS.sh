#!/bin/bash
#
# Script to copy changed files from Scorch's updated K40 Whisperer
# to staging directory for creating macOS package.
#
# 1. Copy over new files from directory specified on command line
# 2. Apply macOS patches from `macOS.patch` and update version numbers
# 3. Run the build script
# 4. Create a disk image (.dmg) for release
#
MD5="md5 -q"
files="gpl-3.0.txt Change_Log.txt README_Linux.txt README_MacOS.md \
		CC.png LL.png LR.png UL.png UR.png up.png down.png left.png right.png \
		bezmisc.py cspsubdiv.py cubicsuperpath.py dxf.py ecoords.py egv.py \
		ffgeom.py g_code_library.py inkex.py interpolate.py nano_library.py \
		py2exe_setup.py requirements.txt  simplepath.py \
		simplestyle.py simpletransform.py svg_reader.py windowsinhibitor.py"

CLEAN_SOURCE=false
while getopts "hvf:u:d:" OPTION; do
	case "$OPTION" in
		h)  echo "Update K40 Whisperer and build macOS Application"
			echo "update_macOS.sh [-hv]  [-d <dir>] | [-f <zipfile>] | [-u <url>] | [<url>]"
			echo "	-h Print help (this)"
			echo "	-v Verbose output"
			echo "  -c Clean up (delete) new sources (ON when downloading from URL)"
			echo "	-d <dir> Use existing source directory"
			echo "	-f <file> Use existing .zip file"
			echo "	-u <url> Download archive from URL"
			exit 1
			;;
		v) 	VERBOSE=true
			;;
		c)  CLEAN_SOURCE=true
			;;
		d) 	UPDATE_DIR=${OPTARG}
			unset SOURCE_ZIP
			unset URL
			;;
		f) 	SOURCE_ZIP=${OPTARG}
			unset UPDATE_DIR
			unset URL
			;;
		u) 	URL=${OPTARG}
			unset SOURCE_ZIP
			unset UPDATE_DIR
			;;
		*)  echo "Incorrect option provided $1"
			exit 1
			;;
    esac
done

if [ -z ${URL+x} ] && [ -z ${SOURCE_ZIP+x} ] && [ -z ${UPDATE_DIR+x} ]
then
	URL=$1
fi

# http://www.scorchworks.com/K40whisperer/K40_Whisperer-0.29_src.zip
if [ ! -z ${URL+x} ]
then
	echo "Download K40 Whisperer source archive..."
	CLEAN_SOURCE=true
	SOURCE_ZIP=$(echo $URL | rev | cut -f1 -d/ | rev)
	curl -o $SOURCE_ZIP $URL
	if [ ! -f $SOURCE_ZIP ]
	then
		echo "Download failed."
		exit 1
	fi
fi

if [ -f "$SOURCE_ZIP" ]
then
	echo "Extract K40 Whisperer source files..."
	unzip -oq $SOURCE_ZIP
	UPDATE_DIR=$(basename $SOURCE_ZIP .zip)
	if [ ! -d $UPDATE_DIR ]
	then
		echo "Extraction failed."
		exit 1
	fi
fi

# Check that the update directory has K40 in it.
if [ ! -f ${UPDATE_DIR}/k40_whisperer.py ] ; then
	echo "K40 Whisperer does not exist at \$1 = ${UPDATE_DIR}!"
	exit
fi

NEW_APP=$(ls -1 ${UPDATE_DIR}/k40_whisperer.py)
VERSION=$(grep "^version " ${UPDATE_DIR}/k40_whisperer.py | grep -Eo "[\.0-9]+")
#VERSION=$(echo ${FILE_VERSION}|cut -c1).$(echo ${FILE_VERSION}|cut -c2-)

echo "Updating to version $VERSION"

# Copy over changed supporting files
echo "Copy updated files from ${UPDATE_DIR}..."
for i in ${UPDATE_DIR}/*
do
	fn=`basename ${i}`
	if [ -f "$fn" ]
	then
		curd5=`${MD5} "${fn}"`
		newd5=`${MD5} "${UPDATE_DIR}/${fn}"`
		if [ "$curd5" != "$newd5" ]; then
			echo "*   $fn"
			cp "${UPDATE_DIR}/${fn}" "$fn"
		fi
	else
		echo "+   $fn"
		cp "${UPDATE_DIR}/${fn}" "$fn"
	fi
done


# Apply macOS patches to f-engrave.py
echo "Patch k40_whisperer.py for macOS..."
patch -p0 -i macOS.patch

# Update version in setup script
echo "Update version number in setup script..."
sed -i.orig "s/app_version = .*/app_version = \"${VERSION}\"/" py2app_setup.py

# Build macOS application
echo "Build macOS Application..."
./build_macOS.sh -d || exit

# Make new patch file
echo "Update macOS.patch file..."
rm macOS-${VERSION}.patch
for i in $(grep +++ macOS.patch | cut  -f1|cut -d\  -f2)
do
    diff -Naur $UPDATE_DIR/$i $i >> macOS-${VERSION}.patch
done

if [ ! -z ${CLEAN_SOURCE+x} ]
then
	echo "🧹 Cleaning up downloaded source files..."
	rm -rf $SOURCE_ZIP $UPDATE_DIR
fi
