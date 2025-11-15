#!/usr/bin/env bash

echo "Rescanning SCSI/ATA Drives ..."

for host in /sys/class/scsi_host/*; do echo "- - -" | sudo tee $host/scan; ls /dev/sd* ; done

exit 0