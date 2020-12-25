# K40 Whisperer for macOS

Packaging of Scorchworks K40 Whisperer as an OSX Application. In this repo you can find the necessary files to build K40 Whisperer v0.42 for macOS. The files regarding Linux and Windows systems have been removed.

> K40 Whisperer is an alternative to the the Laser Draw (LaserDRW) program that comes with the cheap Chinese laser cutters available on E-Bay and Amazon. K40 Whisperer reads SVG and DXF files,interprets the data and sends commands to the K40 controller to move the laser head and control the laser accordingly. K40 Whisperer does not require a USB key (dongle) to function.

![K40 Whisperer running on macOS](https://github.com/rsre/K40-Whisperer-macOS/blob/master/K40-Whisperer-running-on-macOS.png "K40 Whisperer")

The official K40 Whisperer and instructions are at Scorchworks:

> http://www.scorchworks.com/K40whisperer/k40whisperer.html

This fork is to add packaging and minor fixes to work on macOS systems, creating a clickable application that can be installed on any macOS system. This eliminates having to run K40 Whisperer from a Terminal prompt.

## Running The Packaged Application

K40 Whisperer requires a few dependencies that are not installed as part of the application bundle. You will need to install these yourself to have a functioning application.

* [Homebrew](https://brew.sh/) Not required but **strongly recomended**
* [libusb](https://libusb.info) for access to the USB port(s)
* [inkscape](https://inkscape.org) for drawing and rasterization

These dependencies are best installed with [Homebrew](https://brew.sh/) in a `Terminal` window as follows. This only needs to be done once on your system.

```
# Install HomeBrew (only if you don't have it)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Install Dependencies
brew install libusb
brew cask install inkscape
```

You need not read any further in this document. You should be able to run K40 Whisperer.

## Rebuilding from Source (macOS)

In the main directory run `build_macOS.sh`. This will create a clickable macOS Application in the `./dist` directory named `K40 Whisperer.app` that can then be distributed or moved to your Applications folder. See the following sections for details based on your chosen Python version.

If you are using one of the most excellent [Homebrew](https://brew.sh/) versions of Python, you are not only a wonderful person, but life will be easy for you. This build process has been tested *mostly* on Python 3.8.6 using [pyenv](https://github.com/pyenv/pyenv).

NOTE: When installing Python with `pyenv`, you should use the `--enable-framework` flag so that Python can get properly bundled with the application.

### Python 3.8.6 (preferred method)

Set up Python 3.8.6 with HomeBrew and pyenv. Something like the following should work

```
# Install HomeBrew (only if you don't have it)
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install Dependencies (only if you haven't done this already)
brew install libusb
brew cask install inkscape
brew install pyenv

# Install Python 3.8.6 with pyenv and set it as the default Python
```

1. Install tcl-tk with Homebrew.
```brew install tcl-tk```

2. Add tcl-tk to your $PATH.
```
echo 'export PATH="/usr/local/opt/tcl-tk/bin:$PATH"' >> ~/.zshrc
```
3. Reload shell by quitting Terminal app or using the source command.
```
source ~/.zshrc
```
4. Check that tcl-tk is in $PATH.
```
echo $PATH | grep --color=auto tcl-tk
```
You should see your $PATH contents with tcl-tk highlighted.

5. Now run the commands shown in Homebrew's output from step 1.
```
export LDFLAGS="-L/usr/local/opt/tcl-tk/lib"
export CPPFLAGS="-I/usr/local/opt/tcl-tk/include"
export PKG_CONFIG_PATH="/usr/local/opt/tcl-tk/lib/pkgconfig"
```
6. If you have Python version 3.8.6 already installed with pyenv then uninstall it.
```
pyenv uninstall 3.8.6
```
7. Set the environment variables that will be used by python-build.
```
PYTHON_CONFIGURE_OPTS="--with-tcltk-includes='-I/usr/local/opt/tcl-tk/include' --with-tcltk-libs='-L/usr/local/opt/tcl-tk/lib -ltcl8.6 -ltk8.6' --enable-framework" 
```
Note: use tcl-tk version that was installed by Homebrew. At the moment of posting it was 8.6.
8. Install Python.
```
pyenv install 3.8.6
```
9. Set your desired Python version.
```
pyenv global 3.8.6
```
10. Then running the build should work. If not, well, there should be a lot of error messages to help you track things down.
```
./build_macOS.sh
```


## macOS Build Notes

This fork adds the following files to Scorch's work

* `build_macOS.sh` -- bash build script to build and create application bundle.
* `update_macOS.sh` -- bash script to patch a new version of K40 Whisperer and bundle it.
* `emblem.icns` -- Icons for macOS application bundle (made with `sips`)
* `macOS.patch` -- tweaks to Scorch's source for macOS

When a new source package is released by Scorch, the general update process is.

1. Download and extract the new source code
2. Check this repository out into a working directory
3. Run `update_macOS.sh` with the address of the latest source archive
4. *poof* out comes a disk image (`.dmg` file) with the new bundled version.
5. Don't forget to test it!

Here's my typing... and my likely future copy and paste.

```
# Get this repository
git clone https://github.com/stephenhouser/k40_whisperer.git
cd k40_whisperer

# Download, apply patches, build the application
./update_macOS.sh https://www.scorchworks.com/K40whisperer/K40_Whisperer-0.49_src.zip

# Test/Fix/Test...(needs some work)
...
open ./dist/K40\ Whisperer.app
...

# Move newly generated patch file into place
mv macOS-0.49.patch macOS.patch

# Commit and push back to GitHub
git commit -a -m"Update to v0.49"
git tag v0.49
git push --follow-tags
```
