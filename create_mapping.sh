#!/bin/bash


if [ $# -ne 4 ];
then
    echo "usage: $0 <config_file> <src_id> <des_id> <pipeline_id>"
    exit 1
fi

config_file=$1
src_id=$2
des_id=$3
pipeline_id=$4

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

data_media_pair_temp='{"blank":true,"clazzPath":"","extensionDataType":"CLAZZ","notBlank":false,"timestamp":#create}'


function modify_data_media_pair()
{
    pair=${data_media_pair_temp}
    timestamp=`date +%s`
    timestamp=`expr $timestamp \* 1000`
    pair=${pair/\#create/${timestamp}}
}

function gen_data_media_paire_sql()
{
    db=$1
    if [ "$2" == "*" ];
    then
        table=".*"
    else
        table=$2
    fi
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT id FROM DATA_MEDIA WHERE PROPERTIES->>'$.source.id' = ${src_id} AND NAMESPACE='${db}' AND NAME = '${table}';" 2>/dev/null > temp
    result=(`cat temp`)
    src_data_id=${result[1]}
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT id FROM DATA_MEDIA WHERE PROPERTIES->>'$.source.id' = ${des_id} AND NAMESPACE='${db}' AND NAME = '${table}';" 2>/dev/null > temp
    result=(`cat temp`)
    des_data_id=${result[1]}
    modify_data_media_pair
    sql="insert into DATA_MEDIA_PAIR (PUSHWEIGHT,RESOLVER,FILTER,SOURCE_DATA_MEDIA_ID,TARGET_DATA_MEDIA_ID,PIPELINE_ID,COLUMN_PAIR_MODE,GMT_CREATE,GMT_MODIFIED) values (5,'${pair}','${pair}','${src_data_id}','${des_data_id}','${pipeline_id}','INCLUDE',now(),now());"
    echo $sql >> mapping.sql
}

rm mapping.sql temp -f
for item in `cat ${config_file} | grep -Ev "^$|[#;]"`
do
    db="${item%.*}"
    tab="${item#*.}"
    gen_data_media_paire_sql "${db}" "${tab}"
    echo "mapping[${db}.${tab}]"
done
mysql -u${mysql_usr} -p${mysql_pwd} otter < mapping.sql