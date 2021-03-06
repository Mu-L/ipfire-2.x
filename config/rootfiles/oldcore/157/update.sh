#!/bin/bash
############################################################################
#                                                                          #
# This file is part of the IPFire Firewall.                                #
#                                                                          #
# IPFire is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation; either version 3 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# IPFire is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with IPFire; if not, write to the Free Software                    #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA #
#                                                                          #
# Copyright (C) 2020 IPFire-Team <info@ipfire.org>.                        #
#                                                                          #
############################################################################
#
. /opt/pakfire/lib/functions.sh
/usr/local/bin/backupctrl exclude >/dev/null 2>&1

core=157

exit_with_error() {
	# Set last succesfull installed core.
	echo $(($core-1)) > /opt/pakfire/db/core/mine
	# force fsck at next boot, this may fix free space on xfs
	touch /forcefsck
	# don't start pakfire again at error
	killall -KILL pak_update
	/usr/bin/logger -p syslog.emerg -t ipfire \
		"core-update-${core}: $1"
	exit $2
}

# Remove old core updates from pakfire cache to save space...
for (( i=1; i<=$core; i++ )); do
	rm -f /var/cache/pakfire/core-upgrade-*-$i.ipfire
done

KVER="xxxKVERxxx"

# Backup uEnv.txt if exist
if [ -e /boot/uEnv.txt ]; then
	cp -vf /boot/uEnv.txt /boot/uEnv.txt.org
fi

# Do some sanity checks.
case $(uname -r) in
	*-ipfire-kirkwood)
		exit_with_error "ERROR cannot update. kirkwood kernel was not supported." 1
		;;
	*-ipfire*)
		# Ok.
		;;
	*)
		exit_with_error "ERROR cannot update. No IPFire Kernel." 1
		;;
esac
if [ -e /boot/grub/grub.conf ]; then
	exit_with_error "ERROR unsupported GRUB1/pygrub found!" 1
fi

# Check diskspace on root
ROOTSPACE=`df / -Pk | sed "s| * | |g" | cut -d" " -f4 | tail -n 1`

if [ $ROOTSPACE -lt 100000 ]; then
	exit_with_error "ERROR cannot update because not enough free space on root." 2
	exit 2
fi

# Remove the old kernel
rm -rf /boot/System.map-*
rm -rf /boot/config-*
rm -rf /boot/ipfirerd-*
rm -rf /boot/initramfs-*
rm -rf /boot/vmlinuz-*
rm -rf /boot/uImage-*-ipfire-*
rm -rf /boot/zImage-*-ipfire-*
rm -rf /boot/uInit-*-ipfire-*
rm -rf /boot/dtb-*-ipfire-*
rm -rf /lib/modules

# Remove files
rm -rf /usr/lib/libboost*.so.1.71.0

# Stop services

# Extract files
extract_files

# update linker config
ldconfig

# Apply local configuration to sshd_config
/usr/local/bin/sshctrl

# Update Language cache
/usr/local/bin/update-lang-cache

# Filesytem cleanup
/usr/local/bin/filesystem-cleanup

# Fix file permissions changed
chmod -s /usr/bin/gpg
chmod -x \
	/var/ipfire/fwhosts/icmp-types \
	/var/ipfire/ovpn/ovpn-leases.db

chown -R root:root \
	/var/ipfire/updatexlrator/bin \
	/var/ipfire/urlfilter/bin

chown root:root \
	/srv/web/ipfire/cgi-bin/cachemgr.cgi

# Delete scrubbed files
rm -f \
	/usr/lib/dma-mbox-create \
	/usr/lib/openssh/ssh-keysign

# Delete orphaned pppd 2.4.8 shared object files
rm -rf \
	/usr/lib/pppd/2.4.8/

# Start services
/etc/init.d/sshd restart
/etc/init.d/apache restart
/etc/init.d/collectd restart
/etc/init.d/squid restart

# remove lm_sensor config after collectd was started
# to reserch sensors at next boot with updated kernel
rm -f  /etc/sysconfig/lm_sensors

# Upadate Kernel version uEnv.txt
if [ -e /boot/uEnv.txt ]; then
	sed -i -e "s/KVER=.*/KVER=${KVER}/g" /boot/uEnv.txt
fi

# call user update script (needed for some arm boards)
if [ -e /boot/pakfire-kernel-update ]; then
	/boot/pakfire-kernel-update ${KVER}
fi

# This update needs a reboot...
touch /var/run/need_reboot

# Finish
/etc/init.d/fireinfo start
sendprofile

# Update grub config to display new core version
if [ -e /boot/grub/grub.cfg ]; then
	grub-mkconfig -o /boot/grub/grub.cfg
fi

sync

# Don't report the exitcode last command
exit 0
