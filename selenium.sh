sudo -E su

apt-get install -y xinit x11-xserver-utils unzip
add-apt-repository ppa:mozillateam/firefox-stable
apt-get update
apt-get upgrade -y

if [ ! -e /usr/lib/firefox-addons/extensions/firebug@software.joehewitt.com/license.txt ];then
  cd /tmp
  wget https://addons.mozilla.org/en-US/firefox/downloads/latest/1843/addon-1843-latest.xpi -O firebug.xpi
  mkdir -p /usr/lib/firefox-addons/extensions/firebug@software.joehewitt.com
  unzip -o firebug.xpi -d /usr/lib/firefox-addons/extensions/firebug@software.joehewitt.com
fi

grep '99.9.9' /usr/lib/firefox-addons/extensions/firebug@software.joehewitt.com/defaults/preferences/firebug.js ||
  echo 'pref("extensions.firebug.currentVersion", "99.9.9");' >> /usr/lib/firefox-addons/extensions/firebug@software.joehewitt.com/defaults/preferences/firebug.js

echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
chmod 0600 /etc/X11/Xwrapper.config

echo "export DISPLAY=:0.0" > /etc/profile.d/x.sh

cat <<EOS > /etc/X11/xorg.conf
Section "Device"
  Identifier "VESA Framebuffer"
  Driver "vesa"
EndSection
Section "Monitor"
  Identifier "My Monitor"
  HorizSync 31.5 - 150.0
  VertRefresh 75-85
EndSection
Section "Screen"
  Identifier "Screen 1"
  Device "VESA Framebuffer"
  Monitor "My Monitor"
  DefaultDepth 24
  Subsection "Display"
    Depth 24
    Modes "1024x768" "800x600" "640x480"
  EndSubsection
EndSection
Section "ServerLayout"
  Identifier "Simple Layout"
  Screen "Screen 1"
EndSection
EOS
chmod 0644 /etc/X11/xorg.conf
