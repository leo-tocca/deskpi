#!/bin/bash
# Fit for Arch Linux/EndeavourOS
# Made by leo-tocca

deskPiDir=~

# Custom logging functions
log_action_msg() {
  echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_action_warning() {
  echo "[WARNING] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}


# initializing functions
if [ -e /lib/lsb/init-functions ]; then
  . /lib/lsb/init-functions
  log_action_msg "Initializing functions..."
fi

# Define systemd service names
fanDaemon="/etc/systemd/system/deskpi.service"
pwrCutOffDaemon="/etc/systemd/system/deskpi-cut-off-power.service"

# remove old daemon file
if [[ -f $fanDaemon ]]; then
  systemctl stop deskpi.service
  systemctl disable deskpi.service
  sudo rm -f $fanDaemon
fi

if [[ -f $pwrCutOffDaemon ]]; then
  systemctl disable deskpi-cut-off-power.service
  sudo rm -f $pwrCutOffDaemon
fi

# install git tool
pkgStatus=$(pacman -Q git 2>/dev/null)
if [ $? -ne 0 ]; then
  log_action_msg "Installing Git..."
  pacman -Sy --noconfirm git
else
  echo "git already installed!"
fi

# check if dwc2 dtoverlay has been enabled
checkResult=$(grep dwc2 /boot/config.txt)
if [ $? -ne 0 ]; then
  log_warning_msg "Adding dtoverlay=dwc2,dr_mode=host to /boot/config.txt file."
  sudo sed -i '/dtoverlay=dwc2*/d' /boot/firmware/config.txt
  sudo sed -i '$a\dtoverlay=dwc2,dr_mode=host' /boot/firmware/config.txt
  log_action_msg "check dwc2 overlay will be enabled after rebooting."
fi

echo "---------------------- DeskPi compiling ----------------------"

# Check if gcc is installed
if ! command -v gcc &> /dev/null; then
  echo "gcc not found. Installing gcc..."
  sudo pacman -Sy --noconfirm gcc
else
  echo "gcc is already installed."
fi

# Compile the source files
gcc $deskPiDir/deskpi/drivers/c/pwmFanControl.c -o $deskPiDir/deskpi/drivers/c/pwmFanControl64
gcc $deskPiDir/deskpi/drivers/c/safeCutOffPower.c -o $deskPiDir/deskpi/drivers/c/safeCutOffPower64

# Now that the binaries are compiled, we copy them to /usr/bin/ directory
# Define the directory where the compiled files are located
COMPILED_DIR="$deskPiDir/deskpi/drivers/c"

# Check if the directory exists and copy the compiled binaries to /usr/bin/
if [ -d "$COMPILED_DIR" ]; then
  # Copy the locally compiled binaries to /usr/bin/
  sudo cp -Rvf "$COMPILED_DIR/pwmFanControl64" /usr/bin/
  sudo cp -Rvf "$COMPILED_DIR/safeCutOffPower64" /usr/bin/
  sudo cp -Rvf "$deskPiDir/deskpi/installation/Endeavour/deskpi-config" /usr/bin/

  # Make sure they are executable
  sudo chmod +x /usr/bin/pwmFanControl64
  sudo chmod +x /usr/bin/safeCutOffPower64
  sudo chmod +x /usr/bin/deskpi-config

  echo "Locally compiled binaries copied to /usr/bin/"
else
  echo "Compiled directory does not exist: $COMPILED_DIR. Please ensure the files were compiled correctly."
fi


# Generate systemd service file for fan control
if [ ! -e $fanDaemon ]; then
 {
  echo "[Unit]" 
  echo "Description=DeskPi Fan Control Service" 
  echo "After=multi-user.target" 
  echo "[Service]" 
  echo "Type=simple" 
  echo "RemainAfterExit=true" 
  echo "ExecStart=/usr/bin/pwmFanControl64 &" 
  echo "[Install]" 
  echo "WantedBy=multi-user.target" 
 } | sudo tee $fanDaemon > /dev/null
fi

# Generate systemd service file for power cutoff
if [ ! -e $pwrCutOffDaemon ]; then
  {
    echo "[Unit]"
    echo "Description=DeskPi-cut-off-power service"
    echo "Conflicts=reboot.target"
    echo "Before=halt.target shutdown.target poweroff.target"
    echo "DefaultDependencies=no"
    echo "[Service]"
    echo "Type=oneshot"
    echo "ExecStart=/usr/bin/safeCutOffPower64 &"
    echo "RemainAfterExit=yes"
    echo "[Install]"
    echo "WantedBy=halt.target shutdown.target poweroff.target"
  } | sudo tee $pwrCutOffDaemon > /dev/null
fi

# grant privileges to root user
if [ -e $fanDaemon ]; then
  sudo chown root:root $fanDaemon
  sudo chmod 755 $fanDaemon
  log_action_msg "Load DeskPi service and load modules"
  systemctl daemon-reload
  systemctl enable deskpi.service
  systemctl start deskpi.service &
fi

if [ -e $pwrCutOffDaemon ]; then
  sudo chown root:root $pwrCutOffDaemon
  sudo chmod 755 $pwrCutOffDaemon
  systemctl enable deskpi-cut-off-power.service
fi

# Greetings
if [ $? -eq 0 ]; then
  log_action_msg "Congratulations! DeskPi Pro driver has been installed successfully, Have Fun!"
  log_action_msg "System will be rebooted in 10 seconds to take effect."
else
  log_action_warning "Could not download deskpi repository, please check the internet connection and try to execute it again."
  log_action_msg "Usage: sudo ./install-endeavouros-64bit.sh"
fi

sync && sleep 10 && reboot

