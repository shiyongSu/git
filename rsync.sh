#!/bin/bash
#rsync pxeinstall
#

sdec="/var/www/html/autoinstall"
#ddec="/var/www/html/pxebak/tftpboot_dir"

function _rsync(){
     for ip in $(cat rsync.txt)
do
         echo $ip
#         ssh -n $ip "sudo mv $sdec/scripts/pxeinstall $sdec/scripts/pxeinstall.$(date +%Y%m%d%H%M);\
#                     sudo mv $sdec/tftpboot/bzImage $sdec/tftpboot/bzImage.$(date +%Y%m%d%H%M);\
#                     sudo mv $sdec/tftpboot/image.cpio.gz $sdec/tftpboot/image.cpio.gz.$(date +%Y%m%d%H%M)" 
#         if [ $? == 0 ];then
#             echo $ip "bakup file seccess ..."
#         else
#             echo $ip "Err ,Please check"
#         fi
      rsync  -av --bwlimit=10000 $sdec/scripts/pxeinstall  root@$ip::pxe
      rsync  -av --bwlimit=10000 $sdec/tftpboot/bzImage  root@$ip::tftp
      rsync  -av --bwlimit=10000 $sdec/tftpboot/image.cpio.gz  root@$ip::tftp
done
}

function pxeinstall(){
	for ip in $(cat rsync.txt)
do
	    echo $ip
  	    rsync  -av --bwlimit=10000 $sdec/scripts/pxeinstall  root@$ip::pxe
done	
}

function bzimage(){
        for ip in $(cat rsync.txt)
do
            echo $ip
	    rsync  -av --bwlimit=10000 $sdec/tftpboot/bzImage  root@$ip::tftp
done
}

function image(){
        for ip in $(cat rsync.txt)
do   
            echo $ip
	    rsync  -av --bwlimit=10000 $sdec/tftpboot/image.cpio.gz  root@$ip::tftp
done
}

function tarball(){
        for ip in $(cat rsync.txt)
do
            echo $ip
            rsync  -av --bwlimit=10000 $sdec/tarball/  root@$ip::tarball
done
}

function md5(){
     for ip in $(cat rsync.txt)
do
     ssh -n $ip "sudo /bin/bash -c 'md5sum $sdec/scripts/pxeinstall >$sdec/scripts/pxeinstall.md5';\
                 sudo sed -i 's/\/var\/www\/html\/autoinstall\/scripts\///g' /var/www/html/autoinstall/scripts/pxeinstall.md5 "
     if [ $? == 0 ];then
          echo $ip "MD5 change seccess ..."
     else
          echo $ip "Err ,Please check"
     fi
done
}

/usr/bin/inotifywait -mrq --format  '%Xe %w%f' -e modify,create,delete,attrib,close_write,move /var/www/html/autoinstall/ | while read file
do
    INO_EVENT=$(echo $file | awk '{print $1}')
    INO_FILE=$(echo $file | awk -F '/' '{print $NF}')
    INO_DIR=$(echo $file | awk -F '/' '{print $(NF-1)}')
    echo "-------------------------------$(date)------------------------------------"
    echo $file
#增加、修改、写入完成、移动进事件
    if [[ $INO_EVENT == 'CREATE' ]] || [[ $INO_EVENT == 'MODIFY' ]] || [[ $INO_EVENT == 'CLOSE_WRITE' ]] || [[ $INO_EVENT == 'MOVED_TO' ]]; then
       if [[ $INO_FILE == 'pxeinstall' ]]; then
          echo 'CREATE or MODIFY or CLOSE_WRITE or MOVED_TO or ATTRIB'
          sleep 60
          pxeinstall 
          md5
       elif [[ $INO_FILE == 'bzImage' ]]; then
          sleep 60
          bzimage
       elif [[ $INO_FILE == 'image.cpio.gz' ]]; then
          sleep 60
          image
       elif [[ $INO_DIR == 'tarball' ]]; then
          sleep 60
          tarball
       fi
    fi
done
