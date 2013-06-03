#!/bin/bash
# ########################################################################
# This program is check table structure and online alter table for pt.
# Version: 1.0 (2013-05-22)
# Authors: zhanghe@gexing.com
# History:
# ########################################################################

MYSQL=/usr/bin/mysql
PT=/usr/bin/pt-online-schema-change
CAT=/bin/cat
GREP=/bin/grep
ECHO=/bin/echo
TABLE_STRUCTURE=/tmp/table_structure.sql

usage(){
cat << EOF

Usage:
This program is check table structure and online alter table for pt.
Options:
  --help|-h)
    Print help info.
  --sock|-S)
    Sets mysql connect socket.
  --table|-t)
    Sets mysql connect table.
  --database|-d)
    Sets mysql connect database.
  --test|-t)
    Test table structure.
  --alter|-a)
    Sets alter table model.
  --content|-c)
    Sets alter table contents.
  --model|-m)
    Sets alter table model : dry-run | execute.(default dry-run)
Example:
check table structure：
  ./online_schema_change.sh -S /data/mysql_3306/mysql_3306.sock -D gx_test -t asdf --test
online alter table for pt：
1)dry-run model：
  ./online_schema_change.sh -S /data/mysql_3306/mysql_3306.sock -D gx_test -t asdf --alter -c "ADD INDEX pid( \`pid\` )" -m dry-run
2)execute model：
  ./online_schema_change.sh -S /data/mysql_3306/mysql_3306.sock -D gx_test -t asdf --alter -c "ADD INDEX pid( \`pid\` )" -m execute

EOF
}

check_table(){
	#$ECHO TABLE_STRUCTURE=$($MYSQL -S $sock -e "show create table $database.$table") 
	TABLE_STRUCTURE=$($MYSQL -S $sock -e "show create table $database.$table") 
	$ECHO $TABLE_STRUCTURE | $GREP PRIMARY &> /dev/null
	if [ $? -eq 0 ];then
		echo "OK:PRIMARY KEY is OK."
	else
		echo "ERROR:NO PRIMARY!!!"
		exit 1
	fi
	$ECHO $TABLE_STRUCTURE | grep -e '^[a-zA-Z[:digit:][:punct:][:space:]]*$' &> /dev/null
	if [ $? -eq 0 ];then
		echo "OK:There is no chinese."
	else
		echo "ERROR:have chinese!!!"
		exit 1
	fi
}

alter_table(){
	echo $PT --alter "$content" D=$database,t=$table,S=$sock --"$model"
	$PT --alter "$content" D=$database,t=$table,S=$sock --"$model"
}

if [ $# -lt 1 ];then
	usage	
	exit
fi

while test -n "$1"; do
    case "$1" in
	--test)
	    check_table=Y
	    shift
	    ;;
	-a|--alter)
	    ALTER=Y
	    shift
	    ;;
	-P|--port)
	    port=$2
	    shift 2
	    ;;
	-D|--database)
	    database=$2
	    shift 2
	    ;;
	-t|--table)
	    table=$2
	    shift 2
	    ;;
	-S|--sock)
            sock=$2
	    shift 2
	    ;;
	-c|--content)
	    content=$2
	    shift 2
	    ;;
	-m|--model)
	    model=$2
	    shift 2
	    ;;
        -u|--user)
	    user=$2
	    shift 2
	    ;;
	-p|--passwd)
	    passwd=$2
	    shift 2
	    ;;
	-H|--host)
	    host=$2
	    shift 2
	    ;;
	-h|--help)
	    usage
	    exit
	    ;;
	*)
	    echo "Unknown argument: $1"
	    usage
	    echo 
	    exit
	    ;;
    esac
    #shift	
done

if [ "$check_table" == 'Y' ];then
	check_table
fi

if [ "$ALTER" == 'Y' ];then
	check_table
	echo "check table structure is ok."
	read -p "Do you want to alter table[yes/no]?" answer
	case $answer in
		Y|y|yes)
			echo "fine ,continue"
			alter_table;;
		N|n|no)
			echo "ok,good bye";;
		*)
			echo "error choice";;
		esac
	exit 0
fi
