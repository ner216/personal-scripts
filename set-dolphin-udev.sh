#!/bin/bash

sudo tee /etc/udev/rules.d/51-wiimote.rules > /dev/null << 'EOF'
# Wii Remote / DolphinBar hidraw access
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0306", MODE="0666", GROUP="plugdev"

# Wii Remote / DolphinBar raw USB access (for Bluetooth Passthrough)
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0306", MODE="0666", GROUP="plugdev"
EOF

sudo udevadm control --reload-rules && sudo udevadm trigger


