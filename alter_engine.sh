#!/bin/bash

MYSQL=/usr/bin/mysql
PT=/usr/bin/pt-online-schema-change
CONVERT=/usr/bin/mysql_convert_table_format

usage(){
        echo "Description:"
        echo "这个脚本主要是用来一次修改mysql数据库的单个库所有表引擎，一共有三种方式："
        echo "1、pt-online-schema-change：可以实现在线修改表引起。"
        echo "2、mysql_convert_table_format：批量修改表引擎 "
        echo "3、使用mysql默认的修改方式"
        echo "Options:"
        echo "  -h|--help"
        echo "   Print help info."
        echo "  --sock|-S)"
        echo "   Sets mysql connect socket"
        echo "  --mode|-M)"
        echo "   Sets alter table methods：pt | convert | default"
        echo "  --database|-D)"
        echo "   Sets alter database."
        echo "  --nowl|-N)"
        echo "   Sets current engine"
        echo "  --future|-F)"
        echo "   Sets future engine"
        echo ""
        echo "Example:"
        echo "  ./alter_engine.sh -S /data/mysql_3306/mysql.sock -D gx_sucai -M pt -N innodb -F myisam"
        exit 0
}

if [ $# -lt 1 ];then
	usage	
	exit
fi

while test -n "$1"; do
        case "$1" in
                --help|-h)
                        usage
                        ;;
                --sock|-S)
                        sock=$2
                        shift
                        ;;
                --mode|-M)
                        mode=$2
                        shift
                        ;;
                --database|-D)
                        db=$2
                        shift
                        ;;
                --nowl|-N)
                        n_engine=$2
                        shift
                        ;;
                --future|-F)
                        f_engine=$2
                        shift
                        ;;
                *)
                        echo "Unknown argument: $1"
                        usage
                        ;;
        esac
        shift
done

if [ $mode = pt ]; then
	$MYSQL -uroot -S $sock $db -e "select TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='"$db"' and ENGINE='"$n_engine"';" | grep -v "TABLE_NAME" > /tmp/tables.txt
        for t_name in $(cat /tmp/tables.txt);do
                echo "Starting convert table $t_name......"
                sleep 1
                $PT -uroot --alter "engine='$f_engine';" D=$db,t=$t_name,S=$sock --execute
                if [ $? -eq 0 ];then
                        echo "Convert table $t_name to $f_engine success." >> /tmp/con_table.log
                        sleep 1
                else
                        echo "Convert table $t_name to $f_engine failed!" >> /tmp/con_table.log
                fi
        done
elif [ $mode = default ]; then
	$MYSQL -uroot -S $sock $db -e "select TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='"$db"' and ENGINE='"$n_engine"';" | grep -v "TABLE_NAME" > /tmp/tables.txt
        for t_name in $(cat /tmp/tables.txt);do
                echo "Starting convert table $t_name......"
                sleep 1
                $MYSQL -uroot -S $sock $db -e "alter table $t_name engine='$f_engine';"
                if [ $? -eq 0 ];then
                        echo "Convert table $t_name to $f_engine success." >> /tmp/con_table.log
                        sleep 1
                else
                        echo "Convert table $t_name to $f_engine failed!" >> /tmp/con_table.log
                fi
        done
elif [ $mode = convert ]; then
        $CONVERT --user=root --sock=$sock --engine=$f_engine $db
fi
