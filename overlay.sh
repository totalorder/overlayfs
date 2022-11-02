# Local filesystem mounting			-*- shell-script -*-

#
# This script overrides local_mount_root() in /usr/share/initramfs-tools/scripts/local
# and mounts root as a read-only filesystem with a temporary (rw)
# overlay filesystem.
#

. /scripts/local

local_mount_root()
{
	local_top
	if [ -z "${ROOT}" ]; then
		panic "No root device specified. Boot arguments must include a root= parameter."
	fi

	local_device_setup "${ROOT}" "root file system"
	ROOT="${DEV}"

	# Get the root filesystem type if not set
	if [ -z "${ROOTFSTYPE}" ] || [ "${ROOTFSTYPE}" = auto ]; then
		FSTYPE=$(get_fstype "${ROOT}")
	else
		FSTYPE=${ROOTFSTYPE}
	fi

	local_premount

	# CHANGES TO THE ORIGINAL FUNCTION BEGIN HERE
	# N.B. this code still lacks error checking

  # TODO: If the /etc/fstab change is commented out in overlayfs.sh, then /boot/firmware will still be R/W (may be a good thing)

	modprobe ${FSTYPE}
	checkfs "${ROOT}" root "${FSTYPE}"

	# Create directories for root and the overlay
	mkdir /lower /upper

	# Create a folder for persistent data. It will be mounted as R/W
	mkdir -p ${rootmnt}/persistent

	# Mount read-only root to /lower
	if [ "${FSTYPE}" != "unknown" ]; then
		mount ${FSTYPE:+-t "${FSTYPE}"} ${ROOTFLAGS} "${ROOT}" /lower
		mkdir -p /lower/persistent

		# Remount with read only (-r). For some reason mount -o remount,r returned "Invalid argument"
		umount /lower
		mount -r ${FSTYPE:+-t "${FSTYPE}"} ${ROOTFLAGS} "${ROOT}" /lower
	else
		mount ${ROOTFLAGS} ${ROOT} /lower
		mkdir -p /lower/persistent

    # Remount with read only (-r). For some reason mount -o remount,r returned "Invalid argument"
		umount /lower
		mount -r ${ROOTFLAGS} ${ROOT} /lower
	fi

	modprobe overlay

	# Mount a tmpfs for the overlay in /upper
	mount -t tmpfs tmpfs /upper
	mkdir /upper/data /upper/work

	# Mount the final overlay-root in $rootmnt
	mount -t overlay \
	    -olowerdir=/lower,upperdir=/upper/data,workdir=/upper/work \
	    overlay ${rootmnt}

	# Make /persistent R/W
	mount -o bind /lower/persistent ${rootmnt}/persistent
	mount -o remount,rw ${rootmnt}/persistent

	# Make /etc/netplan R/W
	mount -o bind /lower/etc/netplan ${rootmnt}/etc/netplan
	mount -o remount,rw ${rootmnt}/etc/netplan
}
