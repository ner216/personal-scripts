#!/bin/bash

sudo tee /etc/udev/rules.d/51-wiimote.rules > /dev/null << 'EOF'
# DolphinBar / Wii Remote hidraw access
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0306", MODE="0666", TAG+="uaccess"

# DolphinBar / Wii Remote raw USB access
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0306", MODE="0666", TAG+="uaccess"
EOF

sudo udevadm control --reload-rules && sudo udevadm trigger


