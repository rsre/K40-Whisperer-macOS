# -*- coding: utf-8 -*-
from setuptools import setup

APP = ['k40_whisperer.py']
APP_NAME = 'K40 Whisperer'
DATA_FILES = ['right.png','left.png','up.png','down.png','UL.png','UR.png','LR.png','LL.png','CC.png']
OPTIONS = {
	'iconfile': 'scorchworks.icns',
	'includes': ['lxml.etree', 'lxml._elementpath', 'gzip'],
    'plist': {
        'CFBundleName': APP_NAME,
        'CFBundleDisplayName': APP_NAME,
        'CFBundleGetInfoString': "Scorch Works",
        'CFBundleIdentifier': "com.scorchworks.osx.k40-whisperer",
        'CFBundleVersion': "0.27",
        'CFBundleShortVersionString': "0.27",
        'NSHumanReadableCopyright': u"Copyright © 2017, Scorch Works, GNU General Public License",
        'NSHighResolutionCapable': True
    }
}
setup(
    name=APP_NAME,
    app=APP,
    data_files=DATA_FILES,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
