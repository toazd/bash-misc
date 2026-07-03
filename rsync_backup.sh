#!/bin/sh

sudo rsync -aHAXSr --exclude "/proc/" --exclude "/sys/" --exclude "/dev/" --exclude "/run/" --exclude "/run/udev" --progress / "/run/media/wmcdannell/BACKUP/Rsync/"
