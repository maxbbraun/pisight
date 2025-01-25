#!/bin/bash

# 1. Enable camera and serial interfaces: sudo raspi-config
# 2. Run this script: sudo ./setup.sh

set -e

echo "dtoverlay=dwc2,dr_mode=otg" | tee -a /boot/firmware/config.txt

cd /home/pi
sudo apt install -y git meson libcamera-dev libjpeg-dev
git clone https://gitlab.freedesktop.org/camera/uvc-gadget.git

cd /home/pi/uvc-gadget

make uvc-gadget
cd build
meson install
ldconfig

chmod +x /home/pi/pisight/rpi-uvc-gadget.sh
cp /home/pi/pisight/rpi-uvc-gadget.sh /usr/local/bin/rpi-uvc-gadget.sh
cp /home/pi/pisight/uvc-gadget.service /etc/systemd/system/uvc-gadget.service
