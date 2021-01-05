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

data_media_properties='{"mode": "SINGLE","name": "#table","namespace": "#db","source": {"driver": "#driver","encode": "#encode","gmtCreate": #create,"gmtModified": #modify,"id": #id,"name": "#name","password": "#pwd","type": "#type","url": "#url","username": "#usr"}}'


function modify_data_media_properties()
{
    timestamp=`date +%s`
    timestamp=`expr $timestamp \* 1000`
    properties=${data_media_properties}
    properties=${properties/\#table/${table}}
    properties=${properties/\#db/${db}}
    properties=${properties/\#driver/${driver}}
    properties=${properties/\#encode/${encode}}
    properties=${properties/\#create/${timestamp}}
    properties=${properties/\#modify/${timestamp}}
    properties=${properties/\#id/${id}}
    properties=${properties/\#name/${name}}
    properties=${properties/\#pwd/${pwd}}
    properties=${properties/\#type/${type}}
    properties=${properties/\#url/${url}}
    properties=${properties/\#usr/${usr}}
}

function gen_data_media_sql()
{
    db=$1
    if [ "$2" == "*" ];
    then
        table=".*"
    else
        table=$2
    fi
    id=$3
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT PROPERTIES->>'$.driver' FROM DATA_MEDIA_SOURCE WHERE id = ${id};" 2>/dev/null > temp
    result=(`cat temp`)
    driver=${result[1]}
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT PROPERTIES->>'$.encode' FROM DATA_MEDIA_SOURCE WHERE id = ${id};" 2>/dev/null > temp
    result=(`cat temp`)
    encode=${result[1]}
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT PROPERTIES->>'$.name' FROM DATA_MEDIA_SOURCE WHERE id = ${id};" 2>/dev/null > temp
    result=(`cat temp`)
    name=${result[1]}
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT PROPERTIES->>'$.password' FROM DATA_MEDIA_SOURCE WHERE id = ${id};" 2>/dev/null > temp
    result=(`cat temp`)
    pwd=${result[1]}
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT PROPERTIES->>'$.type' FROM DATA_MEDIA_SOURCE WHERE id = ${id};" 2>/dev/null > temp
    result=(`cat temp`)
    type=${result[1]}
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT PROPERTIES->>'$.url' FROM DATA_MEDIA_SOURCE WHERE id = ${id};" 2>/dev/null > temp
    result=(`cat temp`)
    url=${result[1]}
    mysql -u${mysql_usr} -p${mysql_pwd} otter -e "SELECT PROPERTIES->>'$.username' FROM DATA_MEDIA_SOURCE WHERE id = ${id};" 2>/dev/null > temp
    result=(`cat temp`)
    usr=${result[1]}
    modify_data_media_properties
    sql="insert into DATA_MEDIA (NAME,NAMESPACE,PROPERTIES,DATA_MEDIA_SOURCE_ID,GMT_CREATE,GMT_MODIFIED) values ('${table}','${db}','${properties}',${id},now(), now());"
    echo $sql >> tables.sql
}


rm tables.sql temp -f
for item in `cat ${config_file} | grep -Ev "^$|[#;]"`
do
    db="${item%.*}"
    tab="${item#*.}"
    gen_data_media_sql "${db}" "${tab}" ${src_id}
    echo "gen table[${db}.${tab}]"
done

mysql -u${mysql_usr} -p${mysql_pwd} otter < tables.sql