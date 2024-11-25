#!/bin/bash
# ---------------------------------------------------------------------
# This file executes the build command for the macOS Application bundle
# ---------------------------------------------------------------------
PYTHON_VERSION=3.11.4
SRC_DIR=src

# Call getopt to validate the provided input. 
VENV_DIR=build_env.$$
VERBOSE=false
MAKE_DISK=false
KEEP_VENV=false
SETUP_ENVIRONMENT=false
while getopts "hvdesp" OPTION; do
	case "$OPTION" in
		h)  echo "Options:"
			echo "\t-h Print help (this)"
			echo "\t-v Verbose output"
			echo "\t-e Keep Python virtual environment (don't delete)"
			echo "\t-s Setup dev environment"
			echo "\t-d Make disk image (.dmg)"
			exit 0
			;;
		v) 	VERBOSE=true
			;;
		d) 	MAKE_DISK=true
			;;
		e)  KEEP_VENV=true
			;;
		s)  SETUP_ENVIRONMENT=true
			;;
		*)  echo "Incorrect option provided"
			exit 1
			;;
    esac
done

# Prints the provided error message and then exits with an error code
function fail {
    CODE="${1:-1}"
    MESSAGE="${2:-Unknown error}"
    echo ""
    echo -e "\033[31;1;4m*** ERROR: $MESSAGE ***\033[0m"
    echo ""
    exit $CODE
}


# Exits with error code/message if the previous command failed
function check_failure {
    CODE="$?"
    MESSAGE="$1"
    [[ $CODE == 0 ]] || fail "$CODE" "$MESSAGE" 
}

if [ "$SETUP_ENVIRONMENT" = true ]; then
	# Install HomeBrew (only if you don't have it)
	which -s brew
	if [[ $? != 0 ]] ; then
		# Install Homebrew
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
		check_failure "Failed to install homebrew"
	fi

	# Install Dependencies
	brew install inkscape
	brew install --build-from-source libusb
	check_failure "Failed to install libusb"

	# Link Homebrew lib so pyusb can find libusb
	ln -s /opt/homebrew/lib ~/lib

	# Tcl/Tk
	brew install --build-from-source tcl-tk
	check_failure "Failed to install tcl-tk"

	# Install python environments...
	brew install --build-from-source pyenv
	check_failure "Failed to install pyenv"
	eval "$(pyenv init -)"

	# Install Python with pyenv and set it as the default Python
	pyenv uninstall -f ${PYTHON_VERSION}
	# https://github.com/pyenv/pyenv/issues/94
	# Not needed anymore with python 3.11.4
	# env PATH="$(brew --prefix tcl-tk)/bin:$PATH" \
	# 	LDFLAGS="-L$(brew --prefix tcl-tk)/lib" \
	# 	CPPFLAGS="-I$(brew --prefix tcl-tk)/include" \
	# 	PKG_CONFIG_PATH="$(brew --prefix tcl-tk)/lib/pkgconfig" \
	# 	PYTHON_CONFIGURE_OPTS="--enable-framework --with-tcltk-includes='-I$(brew --prefix tcl-tk)/include' --with-tcltk-libs='-L$(brew --prefix tcl-tk)/lib -ltcl8.6 -ltk8.6'"
	pyenv install ${PYTHON_VERSION}
	check_failure "Failed to install Python ${PYTHON_VERSION}"

	# Select Python to use
	pyenv local ${PYTHON_VERSION} && pyenv rehash
	check_failure "Failed to setup Python ${PYTHON_VERSION}"
fi

echo "Validate environment..."
OS=$(uname)
if [ "${OS}" != "Darwin" ]; then
	fail "Um... this build script is for macOS."
fi

# Use the specific python version from pyenv so we don't get hung up on the
# system python or a user's own custom environment.
PYTHON=$(command -v python)
PY_VER=$($PYTHON --version 2>&1 | awk '{ print $2 }')
[[ ${PY_VER} == "${PYTHON_VERSION}" ]] || fail 1 "Packaging REQUIRES Python ${PYTHON_VERSION}. Please rerun with -s to setup build environment"

# Clean up any previous build work
echo "Remove old builds..."
rm -rf ./build ./dist *.pyc ./__pycache__

# Set up and activate virtual environment for dependencies
echo "Setup Python Virtual Environment..."
$PYTHON -m venv "${VENV_DIR}"
check_failure "Failed to initialize python venv"

source "./${VENV_DIR}/bin/activate"
check_failure "Failed to activate python venv"

# Unset our python variable now that we are running inside of the virtualenv
# and can just use `python` directly
PYTHON=

# Install requirements
echo "Install Dependencies..."
python -m pip install --upgrade pip
python -m pip install -r ${SRC_DIR}/requirements.txt
check_failure "Failed to install python requirements"

echo "Build macOS Application Bundle..."

# Create .spec file if it doesn't exist
SPEC_NAME=k40_whisperer.spec
SPEC_FILE=${SRC_DIR}/${SPEC_NAME}
if [ ! -f "$SPEC_FILE" ]; then
    echo "$SPEC_FILE does not exist. Creating a basic one..."

	pyi-makespec	--onefile -w \
					--add-data right.png:. \
					--add-data left.png:. \
					--add-data up.png:. \
					--add-data down.png:. \
					--add-data UL.png:. \
					--add-data UR.png:. \
					--add-data LR.png:. \
					--add-data LL.png:. \
					--add-data CC.png:. \
					-n 'K40 Whisperer' \
					-i emblem.icns \
					--osx-bundle-identifier com.scorchworks.k40_whisperer \
					--specpath ${SRC_DIR} \
					--name ${SPEC_NAME}
					k40_whisperer.py
fi

# Get version from main source file.
VERSION=$(grep "^version " ${SRC_DIR}/k40_whisperer.py | grep -Eo "[\.0-9]+")

python -OO -m PyInstaller -y --clean ${SPEC_FILE}
check_failure "Failed to package k40_whisperer bundle"

# Remove temporary binary
rm -rf dist/k40_whisperer

echo "Copy support files to dist..."
cp ${SRC_DIR}/{k40_whisperer_test.svg,Change_Log.txt,gpl-3.0.txt,README.md} dist

# Clean up the build directory when we are done.
echo "Clean up build artifacts..."
rm -rf build

# Remove virtual environment
if [ "$KEEP_VENV" = false ]; then
	echo "Remove Python virtual environment..."
	deactivate
	rm -rf "${VENV_DIR}"
fi

# Buid a new disk image
if [ "$MAKE_DISK" = true ]; then
	echo "Build macOS Disk Image..."
	VOLNAME="K40 Whisperer ${VERSION}"
	VOLFILE="K40-Whisperer-${VERSION}.dmg"
	# Remove the old disk image if it exists
	[ ! -e ${VOLFILE} ] || rm ${VOLFILE}
	hdiutil create -fs 'Case-sensitive APFS' -volname "${VOLNAME}" -srcfolder ./dist ./dist/${VOLFILE}
	check_failure "Failed to build k40_whisperer dmg"
fi

echo "Done."