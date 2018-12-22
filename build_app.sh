#!/usr/bin/bash
rm *.pyc
rm -rf build dist
python2 py2app_setup.py py2app --packages=PIL