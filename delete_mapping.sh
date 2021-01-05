#!/bin/bash


if [ $# -ne 1 ];
then
    echo "usage: $0 <pipeline_id>"
    exit 1
fi

pipeline_id=$1
echo "connecting mysql ..."
read -p "usr:" mysql_usr
stty -echo
read -p "password:" mysql_pwd
stty echo
echo

sql="delete from DATA_MEDIA_PAIR where pipeline_id=${pipeline_id}"

mysql -u${mysql_usr} -p${mysql_pwd} otter -e"${sql}"