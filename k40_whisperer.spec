# -*- mode: python -*-

block_cipher = None

a = Analysis(['k40_whisperer.py'],
             pathex=['/Users/houser/Projects/K40_Whisperer'],
             binaries=[],
             datas=[('right.png', '.'),('left.png', '.'),('up.png', '.'),('down.png', '.'),('UL.png', '.'),
             ('UR.png', '.'),('LR.png', '.'),('LL.png', '.'),('CC.png', '.')],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)

pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          [],
          name='k40_whisperer',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          runtime_tmpdir=None,
          console=False
    )
app = BUNDLE(exe,
            name='K40 Whisperer.app',
            icon='emblem.icns',
            bundle_identifier='com.scorchworks.k40_whisperer',
      info_plist={
        'NSPrincipleClass': 'NSApplication',
        'NSAppleScriptEnabled': False,
        'NSHighResolutionCapable': True,
        'NSRequiresAquaSystemAppearance': 'Yes',
        'CFBundleGetInfoString': "Scorch Works",
        'CFBundleIdentifier': 'com.scorchworks.k40_whisperer',
        'CFBundleName': 'K40 Whisperer',
        'CFBundleDisplayName': 'K40 Whisperer',
        'NSHumanReadableCopyright': 'Copyright © 2017-2020, Scorch Works, GNU General Public License',
        'CFBundleVersion': '0.45',
        'CFBundleShortVersionString': '0.45'
        }
      )
