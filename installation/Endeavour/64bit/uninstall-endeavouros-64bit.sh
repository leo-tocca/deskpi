#!/bin/bash
# Uninstall Fit for Arch Linux/EndeavourOS
# made by leo-tocca

# Define systemd service names
fanDaemon="/etc/systemd/system/deskpi.service"
pwrCutOffDaemon="/etc/systemd/system/deskpi-cut-off-power.service"

# initializing functions
if [ -e /lib/lsb/init-functions ]; then
  . /lib/lsb/init-functions
  log_action_msg "Initializing functions..."
fi


# Stop and remove systemd services
if [ -f $fanDaemon ]; then
  systemctl stop deskpi.service
  systemctl disable deskpi.service
  sudo rm -f $fanDaemon
fi

if [ -f $pwrCutOffDaemon ]; then
  systemctl disable deskpi-cut-off-power.service
  sudo rm -f $pwrCutOffDaemon
fi

# Delete pwmFanControl64 and safeCutOffPower64 executable binary files
if [ -e /usr/bin/pwmFanControl64 ]; then
  sudo rm -f /usr/bin/pwmFanControl64
  sudo rm -f /usr/bin/safeCutOffPower64
fi

# Greetings
if [ $? -eq 0 ]; then
  log_action_msg "DeskPi Pro driver has been uninstalled successfully!"
  log_action_msg "System will be rebooted in 5 seconds to take effect."
fi

sync && sleep 5 && reboot

