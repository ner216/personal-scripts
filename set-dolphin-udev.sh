#!/bin/bash

sudo echo "SUBSYSTEM=="hidraw", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0306", MODE="0666", GROUP="plugdev"" > /etc/udev/rules.d/51-wiimote.rules

sudo udevadm control --reload-rules && sudo udevadm trigger


