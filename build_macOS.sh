#!/bin/bash
# ---------------------------------------------------------------------
# This file executes the build command for the OS X Application bundle.
# It is here because I am lazy
# ---------------------------------------------------------------------
PYTHON_VERSION=3.10.3

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

# *** Not Tested! ***
if [ "$SETUP_ENVIRONMENT" = true ]; then
	# Install HomeBrew (only if you don't have it)
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	check_failure "Failed to install homebrew"

	# Install Dependencies
	brew install --cask inkscape
	brew install --build-from-source libusb
	check_failure "Failed to install libusb"

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
	PATH="/usr/local/opt/tcl-tk/bin:$PATH" \
		LDFLAGS="-L/usr/local/opt/tcl-tk/lib" \
		CPPFLAGS="-I/usr/local/opt/tcl-tk/include" \
		PKG_CONFIG_PATH="/usr/local/opt/tcl-tk/lib/pkgconfig" \
		PYTHON_CONFIGURE_OPTS="--enable-framework --with-tcltk-includes='-I$(brew --prefix tcl-tk)/include' --with-tcltk-libs='-L$(brew --prefix tcl-tk)/lib -ltcl8.6 -ltk8.6'" \
		pyenv install ${PYTHON_VERSION}
	check_failure "Failed to install Python ${PYTHON_VERSION}"

	# Select Python to use
	pyenv local ${PYTHON_VERSION} && pyenv rehash
	check_failure "Failed to setup Python ${PYTHON_VERSION}"
fi

echo "Validate environment..."
OS=$(uname)
if [ "${OS}" != "Darwin" ]; then
	fail "Um... this build script is for OSX/macOS."
fi

# Use the specific python version from pyenv so we don't get hung up on the
# system python or a user's own custom environment.
PYTHON=$(command -v python3)
PY_VER=$($PYTHON --version 2>&1 | awk '{ print $2 }')
[[ ${PY_VER} == "${PYTHON_VERSION}" ]] || fail 1 "Packaging REQUIRES Python ${PYTHON_VERSION}. Please rerun with -s to setup build environment"

# Clean up any previous build work
echo "Remove old builds..."
rm -rf ./build ./dist *.pyc ./__pycache__

# Set up and activate virtual environment for dependencies
echo "Setup Python Virtual Environment..."
python3 -m venv "${VENV_DIR}"
check_failure "Failed to initialize python venv"

source "./${VENV_DIR}/bin/activate"
check_failure "Failed to activate python venv"

# Unset our python variable now that we are running inside of the virtualenv
# and can just use `python` directly
PYTHON=

# Install requirements
echo "Install Dependencies..."
python3 -m pip install --upgrade pip
pip3 install -r requirements.txt
check_failure "Failed to install python requirements"

echo "Build macOS Application Bundle..."

# Get version from main source file.
VERSION=$(grep "^version " k40_whisperer.py | grep -Eo "[\.0-9]+")

# No need to add --enable-plugin=tk-inter 
python3 -OO -m nuitka --standalone --macos-create-app-bundle --follow-imports --static-libpython=no k40_whisperer.py
check_failure "Failed to package k40_whisperer bundle"

echo "Copy files to dist..."
mkdir dist
cp k40_whisperer_test.svg Change_Log.txt gpl-3.0.txt README.md dist
mv k40_whisperer.app dist
sed -e "s/VERSION/${VERSION}/g" Info.plist > dist/k40_whisperer.app/Contents/Info.plist
mkdir dist/k40_whisperer.app/Contents/Resources/
cp emblem.icns dist/k40_whisperer.app/Contents/Resources/
mv dist/k40_whisperer.app dist/K40\ Whisperer.app

# Clean up the build directory when we are done.
echo "Clean up build artifacts..."
rm k40_whisperer.bin
rm -rf k40_whisperer.build
rm -rf build_env.*

# Remove virtual environment
if [ "$KEEP_VENV" = false ]; then
	echo "Remove Python virtual environment..."
	deactivate
	rm -rf "${VENV_DIR}"
fi

# Buid a new disk image
if [ "$MAKE_DISK" = true ]; then
	echo "Build macOS Disk Image..."
	VOLNAME=K40-Whisperer-${VERSION}
	rm ${VOLNAME}.dmg
	hdiutil create -fs HFS+ -volname ${VOLNAME} -srcfolder ./dist ./${VOLNAME}.dmg
	check_failure "Failed to build k40_whisperer dmg"
	mv ${VOLNAME}.dmg ./dist
fi

echo "Done."