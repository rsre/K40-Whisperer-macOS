# K40 Whisperer for macOS

In this repo you can find the necessary files to build K40 Whisperer v0.27 for macOS. The files regarding Linux and Windows systems have been removed.

## Build instructions
```bash
pip install -r requirements.txt
sh build_app.sh
```

## Installation
You'll need to install the [USB drivers](https://github.com/adrianmihalko/ch340g-ch34g-ch34x-mac-os-x-driver) to be able to control the machine.

You'll also need libusb and inkscape. You can install them from homebrew.

```bash
brew install libusb
brew install inkscape
```

## Known problems
There's a some weird behavour in macOS Mojave that makes Tkinter buttons not show for an app built with py2app. **To make the buttons show just resize the window.**

Tested working in macOS 10.14.1 and macOS 10.10.5.


Original K40 Whisperer by [Scorch Works](http://www.scorchworks.com/K40whisperer/k40whisperer.html)