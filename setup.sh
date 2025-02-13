#!/bin/bash

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
sudo cp /home/pi/pisight/rpi-uvc-gadget.sh /usr/local/bin/rpi-uvc-gadget.sh
sudo cp /home/pi/pisight/uvc-gadget.service /etc/systemd/system/uvc-gadget.service
sudo systemctl daemon-reload
sudo systemctl enable uvc-gadget.service
sudo systemctl start uvc-gadget.service
