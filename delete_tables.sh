#!/bin/bash


if [ $# -ne 2 ];
then
    echo "usage: $0 <config_file> <src_id>"
    exit 1
fi

config_file=$1
src_id=$2

if [ ! -f ${config_file} ];
then
    echo "Invalid config file[${config_file}]!!!"
    exit 1
fi

echo "connecting mysql ..."
read -p "usr:" mysql_usr
stty -echo
read -p "password:" mysql_pwd
stty echo
echo

rm delete_tables.sql -f
for item in `cat ${config_file} | grep -Ev "^$|[#;]"`
do
    db="${item%.*}"
    tab="${item#*.}"
    if [ "$tab" == "*" ];
    then
        tab=".*"
    fi
    sql="DELETE FROM DATA_MEDIA WHERE DATA_MEDIA_SOURCE_ID=${src_id} AND NAMESPACE='${db}' AND NAME='${tab}';"
    echo ${sql} >> delete_tables.sql
    echo "delete table[${db}.${tab}]"
done

mysql -u${mysql_usr} -p${mysql_pwd} otter < delete_tables.sql