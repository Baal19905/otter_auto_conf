#!/bin/bash


if [ $# -ne 1 ];
then
    echo "usage: $0 <src_id>"
    exit 1
fi

src_id=$1
echo "connecting mysql ..."
read -p "usr:" mysql_usr
stty -echo
read -p "password:" mysql_pwd
stty echo
echo

sql="delete from DATA_MEDIA where data_media_source_id=${src_id}"

mysql -u${mysql_usr} -p${mysql_pwd} otter -e"${sql}"