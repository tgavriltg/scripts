#!/bin/bash

#This is a ShellScript For mysql All DB Backup and Bin-log.
#version v1
#2013-04-12

#此脚本为一周一个全库备份，每天一个增量备份。每周一为全库备份，其他为增量备份。

# Defaults setting
port=3306
weekly=1

recovery_single_table(){
cat << EOF
导入或导出单张表:
  默认情况下，InnoDB表不能通过直接复制表文件的方式在mysql服务器之间进行移植，即便使用了innodb_file_per_table选项。而使用Xtrabackup工具可以实现此种功能，
不过，此时需要“导出”表的mysql服务器启用了innodb_file_per_table选项（严格来说，是要“导出”的表在其创建之前，mysql服务器就启用了innodb_file_per_table选项），
并且“导入”表的服务器同时启用了innodb_file_per_table和innodb_expand_import(innodb_import_table_from_xtrabackup=1)选项。

(1)“导出”表
  导出表是在备份的prepare阶段进行的，因此，一旦完全备份完成，就可以在prepare过程中通过--export选项将某表导出了：
  /usr/bin/innobackupex --defaults-file=/data/mysql_3312/mysql_3312.cnf --apply-log --use-memory=4G --export /data/backup/db_backup/mysql_3312/3312_2013-04-15_full
  /usr/bin/innobackupex --defaults-file=/data/mysql_3312/mysql_3312.cnf --apply-log --use-memory=4G --export --incremental --incremental-dir=/data/backup/db_backup/mysql_3312/3312_2013-04-16 /data/backup/db_backup/mysql_3312/3312_2013-04-15_full
  上面是基于增量备份的，所以--export两次。多次类似。
(2)“导入”表
  要在mysql服务器上导入来自于其它服务器的某innodb表，需要先在当前服务器上创建一个跟原表表结构一致的表，而后才能实现将表导入：
  mysql> CREATE TABLE mytable (...)  ENGINE=InnoDB;或者如果表结构没有问题的话，可以mysql> truncate table mytable；
  然后将此表的表空间删除：
  mysql> ALTER TABLE mydatabase.mytable DISCARD TABLESPACE;
  接下来，将来自于“导出”表的服务器的mytable表的mytable.ibd和mytable.exp文件复制到当前服务器的数据目录，更改为mysql.mysql的权限，然后使用如下命令将其“导入”：
  mysql> ALTER TABLE mydatabase.mytable IMPORT TABLESPACE;
EOF
}

recovery_all_data(){
cat << EOF
全库恢复：
1.解压包。
2./usr/bin/innobackupex --defaults-file=/data/mysql_3312/mysql_3312.cnf --apply-log /data/backup/db_backup/mysql_3312/3312_2013-04-15_full
  这里的--apply-log指明是将日志应用到数据文件上，完成之后将备份文件中的数据恢复到数据库中.
3./etc/init.d/mysql_3312 stop;cd /data/mysql_3312/;mv data data-bak;mkdir data;chown mysql.root data;
  要恢复需要停掉mysql，然后把数据文件删掉，为了保险把data文件夹改名，新建data文件夹。
4./usr/bin/innobackupex --defaults-file=/data/mysql_3312/mysql_3312.cnf --copy-back /data/backup/db_backup/mysql_3312/3312_2013-04-15_full
  这里的--copy-back指明是进行数据恢复。数据恢复完成之后，需要修改相关文件的权限mysql数据库才能正常启动。
5.chown -R mysql.root /data/mysql_3312/data/;/etc/init.d/mysql_3312 start
  恢复完之后，需要更改数据文件为mysql的使用用户，然后启动mysql。
6.从库的话，需要查看xtrabackup_slave_info信息，看同步的MASTER_LOG_FILE和MASTER_LOG_POS。
  mysql> change master to master_host='172.16.2.25',master_port=3312,master_user='repl',master_password='xxx',master_log_file='mysql-bin.000902',master_log_pos=143068038;
EOF
}

recovery_incremental_data(){
cat << EOF
增量恢复
1.解压包。
2./usr/bin/innobackupex --defaults-file=/data/mysql_3312/mysql_3312.cnf --apply-log /data/backup/db_backup/mysql_3312/3312_2013-04-15_full
  这里的--apply-log指明是将日志应用到数据文件上，完成之后将备份文件中的数据恢复到数据库中.
3./usr/bin/innobackupex --defaults-file=/data/mysql_3309/mysql_3309.cnf --apply-log --use-memory=4G --incremental --incremental-dir=/data/backup/db_backup/mysql_3312/3312_2013-04-16 /data/backup/db_backup/mysql_3312/3312_2013-04-15_full
  这里的--incremental-dir为全库备份的（或者上一次备份的）
4./etc/init.d/mysql_3312 stop;cd /data/mysql_3312/;mv data data-bak;mkdir data;chown mysql.root data;
  要恢复需要停掉mysql，然后把数据文件删掉，为了保险把data文件夹改名，新建data文件夹。
5./usr/bin/innobackupex --defaults-file=/data/mysql_3312/mysql_3312.cnf --copy-back --use-memory=4G /data/backup/db_backup/mysql_3312/3312_2013-04-15_full
  这里的--copy-back指明是进行数据恢复。数据恢复完成之后，需要修改相关文件的权限mysql数据库才能正常启动。
6.chown -R mysql.root /data/mysql_3312/data/;/etc/init.d/mysql_3312 start
  恢复完之后，需要更改数据文件为mysql的使用用户，然后启动mysql。
7.从库的话，需要查看xtrabackup_slave_info信息，看同步的MASTER_LOG_FILE和MASTER_LOG_POS。
  mysql> change master to master_host='172.16.2.25',master_port=3312,master_user='repl',master_password='xxx',master_log_file='mysql-bin.000902',master_log_pos=143068038;
EOF
}

usage(){
cat << EOF
Usage:
  这是一个用来备份mysql的shell脚本，主要是用innobackupex来备份数据，用mysqldump来备份表结构，bin-log是每天备份前一天的。
  备份策略是每周一个全库备份，其他天是增量备份。
Options:
  -h|--help
    显示帮助信息。
  -p|--port
    设置mysql端口，默认3306.
  -w|weekly
    设置一周内哪一天进行全库备份。默认周一.
  --recovery_single_table
    显示恢复单张表方法.
  --recovery_all_data
    显示全备份恢复方法.
  --recovery_incremental_data
    显示增量备份恢复方法.
	  	
Example:
  $0 -p 3307 -w 1
EOF
}

while test -n "$1"; do
    case "$1" in
	-p|--port)
	    port=$2
	    shift
	    ;;
	-h|--help)
	    echo
	    usage
	    echo
	    exit
	    ;;
	-w|weekly)
	    weekly=$2
	    shift
	    ;;
	--recovery_single_table)
	    echo
	    recovery_single_table
	    echo
	    exit
	    ;;
	--recovery_all_data)
	    echo
	    recovery_all_data
	    echo
	    exit
	    ;;
	--recovery_incremental_data)
	    echo
	    recovery_incremental_data
	    echo
	    exit
	    ;;
	*)
	    echo "Unknown argument: $1"
	    usage
	    echo 
	    exit
	    ;;
    esac
    shift
done

#setting
#设置数据库名，数据库登录,备份路径，日志路径，数据文件位置，以及备份方式
#默认情况下，用sock登录mysql数据库，备份至/data/backup/db_backup/
BackupPath=/data/backup/db_backup/mysql_$port/
LogFile=/var/log/innobackupex_mysql_$port.log
DBdataPath=/data/mysql_$port/data/
innobackupex=/usr/bin/innobackupex
allbackup="$BackupPath""$port"_$(date +%Y-%m-%d)_full
frmbackup="$BackupPath"frm
next=$(expr $weekly + 1)
#Setting End

echo "---------------------------------------------------------------------" >> $LogFile
echo " $(date +"%y-%m-%d %H:%M:%S") Start " >> $LogFile
echo "---------------------------------------------------------------------" >> $LogFile

#check folder 
if ! [ -d $BackupPath ];then
	/bin/mkdir -p $BackupPath
fi

if ! [ -d $frmbackup ];then
	/bin/mkdir -p $frmbackup
fi

if ! [ -d $BackupPath/mysql-bin ];then
	/bin/mkdir -p $BackupPath/mysql-bin
fi

#Backup $port All Database
if [ -f "$BackupPath""$port"_$(date +%Y-%m-%d).tar.gz ] || [ -f "$BackupPath""$port"_$(date +%Y-%m-%d)_full.tar.gz ];then
	echo "["$BackupPath""$port"_$(date +%Y-%m-%d).tar.gz] || ["$BackupPath""$port"_$(date +%Y-%m-%d)_full.tar.gz]The Backup File is exists,Can't Backup!" >> $LogFile
else
	#full backup
	if [ $(date +%u) == $weekly ];then
    		$innobackupex --defaults-file=/data/mysql_$port/mysql_$port.cnf --sock=/data/mysql_$port/mysql.sock --slave-info --no-timestamp $allbackup  >> /dev/null 2>&1
    		cd $BackupPath;tar zcf "$port"_$(date +%Y-%m-%d)_full.tar.gz "$port"_$(date +%Y-%m-%d)_full >> /dev/null 2>&1
        	echo "["$BackupPath""$port"_$(date +%Y-%m-%d)_full.tar.gz]Backup Success!" >> $LogFile
		if [ -d "$port"_$(date +%Y-%m-%d --date='1 days ago') ];then
			rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')
			echo "[/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')_full]Delete Success!" >> $LogFile
		else 
			echo "[/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')_full] is not exist" >> $LogFile
		fi
	#incremental backup
	elif [ $(date +%u) == $next ];then
		$innobackupex --defaults-file=/data/mysql_$port/mysql_$port.cnf --sock=/data/mysql_$port/mysql.sock --slave-info --no-timestamp --incremental --incremental-basedir="$BackupPath""$port"_$(date +%Y-%m-%d --date='1 days ago')_full "$BackupPath""$port"_$(date +%Y-%m-%d) >> /dev/null 2>&1
		cd $BackupPath;tar zcf "$port"_$(date +%Y-%m-%d).tar.gz "$port"_$(date +%Y-%m-%d) >> /dev/null 2>&1
		echo "["$BackupPath""$port"_$(date +%Y-%m-%d).tar.gz]Backup Success!" >> $LogFile
		if [ -d "$port"_$(date +%Y-%m-%d --date='1 days ago')_full ];then
			/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')_full
			echo "[/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')_full]Delete Success!" >> $LogFile
		else
			echo "[/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')_full] is not exist" >> $LogFile
		fi
	else
		$innobackupex --defaults-file=/data/mysql_$port/mysql_$port.cnf --sock=/data/mysql_$port/mysql.sock --slave-info --no-timestamp --incremental --incremental-basedir="$BackupPath""$port"_$(date +%Y-%m-%d --date='1 days ago') "$BackupPath""$port"_$(date +%Y-%m-%d) >> /dev/null 2>&1
		cd $BackupPath;tar zcf "$port"_$(date +%Y-%m-%d).tar.gz "$port"_$(date +%Y-%m-%d) >> /dev/null 2>&1
		echo "["$BackupPath""$port"_$(date +%Y-%m-%d).tar.gz]Backup Success!" >> $LogFile
		if [ -d "$port"_$(date +%Y-%m-%d --date='1 days ago') ];then
			/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')
			echo "[/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')]Delete Success!" >> $LogFile
		else
			echo "[/bin/rm -rf "$port"_$(date +%Y-%m-%d --date='1 days ago')] is not exist" >> $LogFile
		fi
	fi
fi
## backup database mysql ##########
#if [ -f "$BackupPath"mysql_$(date +%Y-%m-%d).tar.gz ];then
#  	echo "["$BackupPath"mysql_$(date +%Y-%m-%d).tar.gz]The Backup File is exists,Can't Backup!" >> $LogFile
#else
#    /usr/bin/mysqlhotcopy --sock=/data/mysql_$port/mysql.sock mysql $mysqlbackup >> /dev/null 2>&1
#    tar -czf $mysqlbackup.tar.gz $mysqlbackup >> /dev/null 2>&1
#    /bin/rm -rf $mysqlbackup
#    echo "["$BackupPath"mysql_$(date +%Y-%m-%d).tar.gz]Backup Success!" >> $LogFile
#fi

## backup database .frm ##########
if [ -f "$frmbackup"/"$port"_$(date +%Y-%m-%d).sql ];then
    echo "["$frmbackup"/"$port"_$(date +%Y-%m-%d).sql]The Backup File is exists,Can't Backup!" >> $LogFile
else
    mysqldump --opt -d -A -S /data/mysql_$port/mysql.sock > "$frmbackup"/"$port"_$(date +%Y-%m-%d).sql
    echo "["$frmbackup"/"$port"_$(date +%Y-%m-%d).sql]Backup Success!" >> $LogFile
fi

## backup mysql-bin ##############
for binlog in $(find /data/mysql_$port/data/ -name "mysql-bin*"  -mtime 1);do
	/bin/cp $binlog "$BackupPath"mysql-bin/
	echo "[$binlog]Backup Success! " >> $LogFile
done
/usr/bin/mysql -S /data/mysql_$port/mysql.sock -e 'flush logs;'

echo "-----------------------------------------------------------------------" >> $LogFile
echo " $(date +"%y-%m-%d %H:%M:%S") Finish " >> $LogFile
echo "-----------------------------------------------------------------------" >> $LogFile
