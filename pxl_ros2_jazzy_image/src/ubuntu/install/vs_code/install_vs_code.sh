#!/usr/bin/env bash
set -ex

# Install vsCode
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/x64/g')
wget -q https://update.code.visualstudio.com/latest/linux-deb-${ARCH}/stable -O vs_code.deb
apt-get update
apt-get install -y ./vs_code.deb

# Desktop icon
mkdir -p /usr/share/icons/hicolor/apps
wget -O /usr/share/icons/hicolor/apps/vscode.svg https://kasm-static-content.s3.amazonaws.com/icons/vscode.svg
desktop_file=/usr/share/applications/code.desktop
if [ ! -f "$desktop_file" ]; then
  cat > "$desktop_file" <<'DESKTOP'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=/usr/share/code/code --no-sandbox %F
Icon=/usr/share/icons/hicolor/apps/vscode.svg
Type=Application
Terminal=false
Categories=Development;IDE;
DESKTOP
else
  sed -i '/Icon=/c\Icon=/usr/share/icons/hicolor/apps/vscode.svg' "$desktop_file"
  sed -i 's#/usr/share/code/code#/usr/share/code/code --no-sandbox##' "$desktop_file"
fi
cp "$desktop_file" "$HOME/Desktop"
chmod +x $HOME/Desktop/code.desktop
chown 1000:1000 $HOME/Desktop/code.desktop
rm vs_code.deb

# Conveniences for python development
apt-get update
apt-get install -y python3-setuptools \
                   python3-venv \
                   python3-virtualenv

# Cleanup for app layer
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi
