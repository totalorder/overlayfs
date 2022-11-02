#!/bin/bash
set -e
set -o pipefail

# Please upgrade the kernel before continuing:
# apt update && apt upgrade && reboot now
apt install initramfs-tools

# Configure update-initramfs to include the overlay module
if ! grep overlay /etc/initramfs-tools/modules > /dev/null; then
  echo overlay >> /etc/initramfs-tools/modules
fi

# Install the overlay script which configures mounts on boot
# Note: Every time this file is changed the initrd image needs to be recreated with update-initramfs
cp overlay.sh /etc/initramfs-tools/scripts/overlay

# Backup current image
cp "/boot/initrd.img-$(uname -r)" "/boot/initrd.img-$(uname -r).bak"

# Create a new image with the overlay module included
update-initramfs -c -k "$(uname -r)"

# TODO: Useful commands for debugging
# sudo update-initramfs -c -k "$(uname -r)" && sudo reboot now
# sudo less /etc/initramfs-tools/scripts/overlay
# echo " debug" | sudo tee /boot/firmware/cmdline.txt
# sudo less /run/initramfs/initramfs.debug

# Backup current cmdline.txt
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.bak

# Make a copy of cmdline.txt without boot=overlay, add boot=overlay to the copy, and replace cmdline.txt with the copy
sed -e 's/.*/ & /;:1;s/ boot=overlay / /g;t1;s/ \+/ /g;s/^ //;s/ $//' "/boot/firmware/cmdline.txt" > "/boot/firmware/cmdline.txt.orig" &&
sed -e "s/.*/boot=overlay &/" "/boot/firmware/cmdline.txt.orig" > "/boot/firmware/cmdline.txt.overlay" &&
cp "/boot/firmware/cmdline.txt.overlay" "/boot/firmware/cmdline.txt"

# Install utility script
cp overctl /usr/local/sbin

# TODO: Do I actually need this? Probably not
# Backup current fstab
#cp /etc/fstab /etc/fstab.bak
# Make /boot/firmware readonly
#sed -e "s/\(.*\/boot.*\)defaults\(.*\)/\1defaults,ro\2/" -i /etc/fstab
