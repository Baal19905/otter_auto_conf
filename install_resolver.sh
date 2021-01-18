#!/bin/bash

if [ $# -ne 2 ];
then
    echo "usage $0 <config_file> <code_file>"
    exit 1
fi

config_file=$1
code_file=$2


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

str=`cat ${code_file}`
source_text=""
resolver='{"blank": false,"extensionDataType": "SOURCE","notBlank": true,"sourceText": "###","timestamp": '"`date +%s`}"

function str_to_array()
{
    for index in `seq 0 $((${#str}-1))`
    do
        array[$index]=${str:$index:1}
    done
}

function str_to_source_text()
{
    for ((i=0;i<${#array[@]};i++))
    do
        n=`printf %d "'${array[i]}"`
        if [ ${n} -eq 10 ]; # /n
        then
            source_text=${source_text}"\\\\n"
        elif [ ${n} -eq 13 ]; # /r
        then
            source_text=${source_text}"\\\\r"
        elif [ ${n} -eq 9 ]; # /t
        then
            source_text=${source_text}"\\\\t"
        elif [ ${n} -eq 34 ]; # "
        then
            source_text=${source_text}"\\\\\""
        elif [ ${n} -eq 92 ]; # \"
        then
            source_text=${source_text}"\\\\\\\\"
        else
            source_text=${source_text}${array[i]}
        fi
    done
}

function gen_update_sql()
{
    resolver=${resolver/\#\#\#/${source_text}}
    for item in `cat ${config_file} | grep -Ev "^$|[#;]"`
    do
        db="${item%.*}"
        tab="${item#*.}"
        sql="UPDATE DATA_MEDIA_PAIR t1 INNER JOIN DATA_MEDIA t2 ON t1.SOURCE_DATA_MEDIA_ID=t2.id AND t2.NAME='${tab}' AND t2.NAMESPACE='${db}' SET resolver='${resolver}';"
        echo "${sql}" >> resolver.sql
    done
}

rm -f resolver.sql

set -e
str_to_array
str_to_source_text
gen_update_sql

mysql -u${mysql_usr} -p${mysql_pwd} otter < resolver.sql
