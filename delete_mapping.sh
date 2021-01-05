#!/bin/bash


if [ $# -ne 2 ];
then
    echo "usage: $0 <config_file> <pipeline_id>"
    exit 1
fi

config_file=$1
pipeline_id=$2

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

rm delete_mapping.sql -f
for item in `cat ${config_file} | grep -Ev "^$|[#;]"`
do
    db="${item%.*}"
    tab="${item#*.}"
    if [ "$tab" == "*" ];
    then
        tab=".*"
    fi
    sql="DELETE t1 FROM DATA_MEDIA_PAIR t1 INNER JOIN DATA_MEDIA t2 ON t1.SOURCE_DATA_MEDIA_ID=t2.id AND t2.NAMESPACE='${db}' AND t2.NAME='${tab}' AND t1.pipeline_id=${pipeline_id};"
    echo "${sql}" >> delete_mapping.sql
    echo "delete mapping[${db}.${tab}]"
done

mysql -u${mysql_usr} -p${mysql_pwd} otter < delete_mapping.sql