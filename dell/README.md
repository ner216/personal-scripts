# Script tools created for Dell systems

### power-mode

This script was created for Ubuntu to switch Dell BIOS thermal modes without affecting the operating system power profile. This is necessary because laptops such as the Dell Pro 14 PC14250 do not expose these modes in the BIOS, but it does expose them to the operating system. 

When switching modes with this script, ensure that power-profiles-deamon is not installed as the thermal mode switch will trigger the power-profiles-daemon to switch power modes as well.
