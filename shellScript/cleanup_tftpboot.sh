#!/bin/sh
find /tftpboot/RELEASE/trunk -mtime +30 -exec rm -f {} \;

find /tftpboot -maxdepth 1 -type f -size +1 -exec mv {} /tftpboot/tmp \;
find /tftpboot/tmp -mtime +30 -exec rm -f {} \;
