cask 'k40-whisperer' do
  version '0.49.A'
  sha256 '342cadfc883a63495858fa6d36a4f4372c05b35b9de66a6eab019f8aa98acc18'

  url "https://github.com/rsre/K40-Whisperer-macOS/releases/download/v#{version}/K40-Whisperer-#{version}.dmg"
  appcast 'https://github.com/rsre/K40-Whisperer-macOS/releases.atom'
  name 'K40 Whisperer'
  homepage 'https://github.com/rsre/k40-whisperer-macOS'

  depends_on formula: 'libusb'
  depends_on cask: 'inkscape'

  app 'K40 Whisperer.app'
end
