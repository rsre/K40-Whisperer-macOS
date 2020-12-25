#!/bin/bash
# ---------------------------------------------------------------------
# This file executes the build command for the OS X Application bundle.
# It is here because I am lazy
# ---------------------------------------------------------------------

# Call getopt to validate the provided input. 
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

if [ "$SETUP_ENVIRONMENT" = true ]
then
	# Install HomeBrew (only if you don't have it)
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# Install Dependencies
	brew install inkscape
	brew install libusb

	# Install python environments...
	brew install pyenv
	eval "$(pyenv init -)"

	# Install Python 3.9.0 with pyenv and set it as the default Python
	PYTHON_CONFIGURE_OPTS="--enable-framework" pyenv install 3.8.6
	pyenv global 3.8.6
	pyenv rehash
fi

echo "Validate environment..."

# Get version from main source file.
VERSION=$(grep "^version " k40_whisperer.py | grep -Eo "[\.0-9]+")

# Determine Python to use... prefer Python3
PYTHON=$(command -v python3)
if [ -z "${PYTHON}" ]
then
	PYTHON=$(command -v python)
fi

PIP=$(command -v pip3)
if [ -z "${PIP}" ]
then
	PIP=$(command -v pip)
fi

# Clean up any previous build work
echo "Remove old builds..."
rm -rf ./build ./dist *.pyc ./__pycache__

# Set up and activate virtual environment for dependencies
echo "Setup Python Virtual Environment..."
PY_VER=$(${PYTHON} --version 2>&1)
if [[ $PY_VER == *"2.7"* ]]
then
	${PIP} install virtualenv py2app==0.16
	virtualenv python_venv
else
	${PYTHON} -m venv python_venv
fi

source ./python_venv/bin/activate

# Install requirements
echo "Install Dependencies..."
${PIP} install -r requirements.txt

echo "Build macOS Application Bundle..."

FILE=k40_whisperer.spec
if [ -f "$FILE" ]; then
	${PYTHON} -O -m PyInstaller -y --clean k40_whisperer.spec
else 
    echo "$FILE does not exist. Creating a basic one..."

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
					k40_whisperer.py
	mv K40\ Whisperer.spec k40_whisperer.spec
    ${PYTHON} -O -m PyInstaller -y --clean k40_whisperer.spec
fi

rm -rf dist/k40_whisperer

echo "Copy support files to dist..."
cp k40_whisperer_test.svg Change_Log.txt gpl-3.0.txt dist

# Clean up the build directory when we are done.
echo "Clean up build artifacts..."
rm -rf build

# Remove virtual environment
if [ "$KEEP_VENV" = false ]
then
	echo "Remove Python virtual environment..."
	deactivate
	rm -rf python_venv
fi

# Buid a new disk image
if [ "$MAKE_DISK" = true ]
then
	echo "Build macOS Disk Image..."

	VOLNAME=K40-Whisperer-${VERSION}
	hdiutil create -fs HFS+ -volname ${VOLNAME} -srcfolder ./dist ./${VOLNAME}.dmg
	mv ${VOLNAME}.dmg ./dist
fi

echo "Done."