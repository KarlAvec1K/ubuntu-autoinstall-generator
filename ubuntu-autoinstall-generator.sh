#!/bin/bash

# Variables
ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/focal/daily-live/current/focal-live-server-amd64.iso"
ISO_NAME="focal-live-server-amd64.iso"
WORK_DIR="ubuntu-autoinstall-work"
MODIFIED_ISO="ubuntu-20.04-autoinstall.iso"

# Function to check if required utilities are installed
check_utilities() {
  for cmd in curl mkisofs sed; do
    if ! command -v $cmd &> /dev/null; then
      echo "[❌] Error: $cmd is not installed."
      exit 1
    fi
  done
}

# Check for required utilities
echo "[👶] Starting up..."
check_utilities

# Download the ISO
echo "[📥] Downloading ISO from $ISO_URL..."
curl -L -o "$ISO_NAME" "$ISO_URL"

# Check if the ISO was downloaded
if [ ! -f "$ISO_NAME" ]; then
  echo "[❌] Error: ISO file $ISO_NAME not found."
  exit 1
fi

# Create working directory
mkdir -p "$WORK_DIR"

# Extract the ISO
echo "[🔧] Extracting ISO..."
sudo mount -o loop "$ISO_NAME" /mnt
sudo rsync -a /mnt/ "$WORK_DIR/"
sudo umount /mnt

# Modify the ISO
echo "[🛠️] Modifying ISO..."
# Example modification: adding autoinstall parameters
sed -i '/append/ s/$/ autoinstall ds=nocloud-net;s=/user-data=/mnt/user-data/;s=/meta-data=/mnt/meta-data/' "$WORK_DIR/isolinux/txt.cfg"

# Create the modified ISO
echo "[💾] Creating modified ISO..."
mkisofs -r -V "Custom Ubuntu Install" -cache-inodes -J -l -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat -o "$MODIFIED_ISO" "$WORK_DIR"

# Ask if user wants to delete the working directory
read -p "[❓] Do you want to delete the working directory '$WORK_DIR'? [y/n]: " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
  echo "[🗑️] Deleting working directory..."
  rm -rf "$WORK_DIR"
else
  echo "[ℹ️] Working directory '$WORK_DIR' was not deleted."
fi

echo "[✔️] Done. Modified ISO created as '$MODIFIED_ISO'."
